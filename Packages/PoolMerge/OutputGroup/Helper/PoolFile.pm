
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for pool file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::OutputGroup::Helper::PoolFile;

#3th party library
use utf8;
use strict;
use warnings;
use DateTime;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAMJob::Stackup::StackupDefault';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::NifFile::NifFile';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"poolInfo"} = shift;

	return $self;
}

# Set info about solder mask and silk screnn, based on layers
sub CreatePoolFile {
	my $self        = shift;
	my $masterJob   = shift;
	my $masterOrder = shift;
	my $mess        = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my $path = JobHelper->GetJobArchive($masterJob) . "\\$masterJob.pool";

	if ( -e $path ) {
		unlink($path);
	}

	# 1) prepare count of each child order in panel

	my @repeats = CamStepRepeat->GetRepeatStep( $inCAM, $masterJob, "panel" );
	my @orders = $self->{"poolInfo"}->GetOrdersInfo();

	# hash, key order id, value number of pieces on panel from optimizator
	my %orderCnt = ();
	foreach my $order (@orders) {

		$orderCnt{ $order->{"orderId"} } = scalar( @{ $order->{"pos"} } );
	}

	# check if there are some extra steps on panel, and correct order counts

	foreach my $order (@orders) {

		# real count
		my $cntReal = undef;
		if ( $order->{"jobName"} eq $masterJob ) {
			$cntReal = grep { $_->{"stepName"} eq "o+1" } @repeats;
		}
		else {
			$cntReal = grep { $_->{"stepName"} eq $order->{"jobName"} } @repeats;
		}

		# actual count from pool file
		my $cntFile = 0;
		foreach my $orderId ( keys %orderCnt ) {
			my $job= $order->{"jobName"};
			if ( $orderId =~ /^$job-/i ) { 
				$cntFile += $orderCnt{$orderId} ;
			}
		}

		# if count doesnt equal, add difference
		if ( $cntReal > $cntFile ) {

			$orderCnt{ $order->{"orderId"} } = $cntReal;
		}
		
		# consider, if pool has defined customer panel
		my $nif = NifFile->new( $order->{"jobName"} );
		my $custPnl = $nif->GetValue("nasobnost_panelu");
		
		if(defined $custPnl && $custPnl ne "" && $custPnl > 0){
			$orderCnt{ $order->{"orderId"} } *= $custPnl;
		}
	}



	# 2) build file
	my @lines = ();

	push( @lines, "[POOL]" );
	push( @lines, "master = $masterOrder" );

	my @orderNames = $self->{"poolInfo"}->GetOrderNames();
	@orderNames = grep { $_ !~ /^$masterOrder/i } @orderNames;

	push( @lines, "slaves = " . join( ",", @orderNames ) );
	push( @lines, "" );

	foreach my $orderId ( keys %orderCnt ) {

		push( @lines, "[".$orderId."]" );
		push( @lines, "nasobnost = " . $orderCnt{$orderId} );
		push( @lines, "" );
	}

	# frite to file
	if ( open( my $f, ">", $path ) ) {

		foreach my $l (@lines) {
			print $f $l."\n";
		}

		close($f);
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::AOIExport::AOIMngr';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobName   = "f13610";
	#	my $stepName  = "panel";
	#	my $layerName = "c";
	#
	#	my $mngr = AOIMngr->new( $inCAM, $jobName, $stepName, $layerName );
	#	$mngr->Run();
}

1;

