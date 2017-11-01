
#-------------------------------------------------------------------------------------------#
# Description: Check controls
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::CheckGroup::Helper::MasterJobHelper;

#3th party library
use utf8;
use strict;
use warnings;
use DateTime;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamNetlist';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"poolInfo"} = shift;

	return $self;
}

# Return order able to be MASTER
sub GetMasterJob {
	my $self        = shift;
	my $masterOrder = shift;
	my $masterJob   = shift;
	my $mess        = shift;

	my @orders = $self->{"poolInfo"}->GetOrdersInfo();

	my $result = 1;

	# 1) load term of orders

	my @orderDeliver = ();
	foreach my $order (@orders) {

		my %inf = ( "order" => $order );

		my $deliver = HegMethods->GetTermOfOrder( $order->{"orderId"} );
		my $dt      = undef;
		if ( $deliver =~ m/^(\d{4})-(\d{2})-(\d{2})/ ) {
			$dt = DateTime->new(
								 "year"  => $1,
								 "month" => $2,
								 "day"   => $3
			);
		}
		else {
			die "Bed format of deliver date ($deliver) at " . $order->{"orderId"};
		}

		$inf{"date"} = $dt;

		push( @orderDeliver, \%inf );
	}

	# 2) sort terms asc

	@orderDeliver = sort { DateTime->compare( $a->{"date"}, $b->{"date"} ) } @orderDeliver;

	# 3) consider only orders with the most early date

	my $smallerDate    = $orderDeliver[0]->{"date"};
	my @candidateOrder = grep { DateTime->compare( $_->{"date"}, $smallerDate ) == 0 } @orderDeliver;
	my $candidatesStr  = join( ";", map { $_->{"order"}->{"jobName"} } @candidateOrder );

	# 4) check if orders is not in production as mmother

	@candidateOrder = grep { $self->__MasterCandidate( $_->{"order"}->{"orderId"}, $_->{"order"}->{"jobName"} ) } @candidateOrder;

	# if more candidates, take by newer pcb id
	# (newer pcb has bigger chance, material is filled properly in IS. IS400 vs FR4)
	@candidateOrder = sort { $b cmp $a } @candidateOrder;
	if ( scalar(@candidateOrder) ) {

		$$masterOrder = $candidateOrder[0]->{"order"}->{"orderId"};
		$$masterJob   = $candidateOrder[0]->{"order"}->{"jobName"};

	}
	else {

		$$mess .= "Not found a suitable \"master job\" for this pool panel.\n";
		$$mess .=
		  "The job (" . $candidatesStr . ") with earliest \"deliver date\" (" . $smallerDate->dmy() . ") is already in produce like \"master job\"";
		$result = 0;
	}

	return $result;

}

sub CheckMasterJob {
	my $self      = shift;
	my $masterjob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	# 1) check if master job contains only two steps: o+1 and iput step

	my @steps = CamStep->GetAllStepNames( $inCAM, $masterjob );
	my $strAll = join( "; ", @steps );

	# Remove o+1_single step if exist, only 2 steps should left

	# all alowed master steps
	my @allowed =
	  ( CamStep->GetReferenceStep( $inCAM, $masterjob, "o+1" ), 
	  "o+1", 
	  "o+1_single", 
	  "o+1_panel", 
	  CamNetlist->GetNetlistSteps( $inCAM, $masterjob ) );
	  
	my %tmp;
	@tmp{@allowed} = ();
	@steps = grep { !exists $tmp{$_} } @steps;

	if ( scalar(@steps) > 0 ) {
		my $str   = join( "; ", @steps );
		 
		
		$$mess .= "Master job \"$masterjob\" can't contain steps: $str.\n";
		$$mess .= "Current master job steps: $strAll.\n";

		$result = 0;
	}

	# 2) check if exist some child jobs
	my @orderNames = $self->{"poolInfo"}->GetOrderNames();
	my @childOrders = grep { $_ !~ /^$masterjob/i } @orderNames;

	unless ( scalar(@childOrders) ) {
		$$mess .= "Pool soubor obsahuje pouze jednu objednávku. Pusť desku do výroby samostatně.\n";

		$result = 0;
	}

	return $result;
}

# Check if pcb is not in produce as master
sub __MasterCandidate {
	my $self      = shift;
	my $orderId   = shift;
	my $orderName = shift;

	my $res = 1;

	my $lastOrderNum = HegMethods->GetNumberOrder($orderName);

	my ($sufixNum) = $lastOrderNum =~ /-(\d+)/;

	for ( my $i = 1 ; $i <= int($sufixNum) ; $i++ ) {

		my $orderNameTmp = $orderName . '-' . sprintf( "%02d", $i );

		if ( HegMethods->GetStatusOfOrder($orderNameTmp) eq 'Ve vyrobe' ) {
			if ( HegMethods->GetInfMasterSlave($orderNameTmp) eq 'M' ) {
				$res = 0;
				last;
			}
		}
	}

	return $res;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::PoolMerge::CheckGroup::Helper::MasterJobHelper';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobName   = "f52457";
	my $stepName  = "panel";
 

	my $mess = "";

	my $mngr = MasterJobHelper->new($inCAM);
	$mngr->CheckMasterJob( $jobName, \$mess );

	print $mess;

}

1;

