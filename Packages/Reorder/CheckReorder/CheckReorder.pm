#-------------------------------------------------------------------------------------------#
# Description: Do check of reorder job. Recognize changes, which has to be done manually by tpv
# before pcb goes to production
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::CheckReorder;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Reorder::CheckReorder::CheckInfo';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;    # Job id without order id
	$self->{"orderId"}     = shift;    # Complete order id (X000000-00)
	                                   # ReorderType_POOL
	                                   # ReorderType_POOLFORMERSTD
	                                   # ReorderType_POOLFORMERMOTHER
	                                   # ReorderType_STD
	                                   # ReorderType_STDFORMERPOOL
	$self->{"reorderType"} = shift;

	$self->{"isPool"} = HegMethods->GetPcbIsPool( $self->{"jobId"} );

	# All controls
	#my @controls = ();
	#$self->{"controls"} = \@controls;

	my @chList = ();
	$self->{"checks"} = \@chList;

	# 1) Load  checklist and check classes
	$self->__LoadChecks();

	## Load all check class
	#3$self->__LoadCheckClasses();

	return $self;
}

# Do all checks and return check which fail
sub RunChecks {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @manCh = ();

	my $isPool = HegMethods->GetPcbIsPool($jobId);
	my $pnlExist = CamHelper->StepExists( $inCAM, $jobId, "panel" );

	foreach my $check ( @{ $self->{"checks"} } ) {

		$check->Run();
		my @changes = $check->GetChanges();

		if ( scalar(@changes) ) {
			push( @manCh, @changes );
		}

		my $resultItem = $self->_GetNewItem( $check->GetCheckKey() );
		$resultItem->SetData( \@changes );
		$self->_OnItemResult($resultItem);
	}

	return @manCh;
}

# Return total number of checked aitems
sub GetItemCnt {
	my $self = shift;

	return scalar( @{ $self->{"checks"} } );
}

sub __LoadChecks {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $orderId     = $self->{"orderId"};
	my $isPool      = $self->{"isPool"};
	my $reorderType = $self->{"reorderType"};

	my $path  = GeneralHelper->Root() . "\\Packages\\Reorder\\CheckReorder\\CheckList";
	my @lines = @{ FileHelper->ReadAsLines($path) };

	unless ( -e $path ) {
		die "Unable to process reorder $jobId, because \"CheckList\" file doesnt exist.\n";
	}

	my @checks = ();

	@lines = grep { $_ !~ /#/ } @lines;

	foreach my $l (@lines) {

		$l =~ s/\s//g;

		if ( $l ne "" ) {

			my $key = uc($l);

			my $module = 'Packages::Reorder::CheckReorder::Checks::' . $key;
			eval("use  $module;");

			push( @checks, $module->new( $key, $inCAM, $jobId, $orderId, $reorderType ) );
		}
	}

	unless ( scalar(@checks) ) {
		die "Unable to process reorder $jobId, because there are no automatic changes.\n";

	}

	$self->{"checks"} = \@checks;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::CheckReorder';

	use aliased 'Packages::InCAM::InCAM';
		use aliased 'Packages::Reorder::Enums';

	use Data::Dump qw(dump);

	my $inCAM   = InCAM->new();
	my $jobId   = "d215629";
	my $orderId = "d215629-01";
 

	my $ch = CheckReorder->new( $inCAM, $jobId, $orderId, Enums->ReorderType_POOL );
	my @arr = $ch->RunChecks();

	dump(@arr)

}

1;

