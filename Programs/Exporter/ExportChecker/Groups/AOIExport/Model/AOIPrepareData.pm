
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnIsGroupAllowed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::AOIExport::Model::AOIPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::AOIExport::Model::AOIGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::CAMJob::Stackup::StackupCode';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

# This method decide, if group will be "active" or "passive"
# If active, decide if group will be switched ON/OFF
# Return enum: Enums->GroupState_xxx
sub OnGetGroupState {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData   = AOIGroupData->new();
	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	return Enums->GroupState_ACTIVEON;

}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my $groupData = AOIGroupData->new();

	my $inCAM      = $dataMngr->{"inCAM"};
	my $jobId      = $dataMngr->{"jobId"};
	my $stepToTest = "panel";

	my @layers = CamJob->GetSignalLayerNames( $inCAM, $jobId );

	# 1) Set step to test
	$groupData->SetStepToTest($stepToTest);

	# 2) Set test layers
	my $stackupCode = StackupCode->new( $inCAM, $jobId, $stepToTest );
	for ( my $i = scalar(@layers) - 1 ; $i >= 0 ; $i-- ) {

		if ( $stackupCode->GetIsLayerEmpty( $layers[$i] ) ) {
			splice @layers, $i, 1;
		}
	}

	$groupData->SetLayers( \@layers );

	# 3) Set send to server
	my @orders = HegMethods->GetPcbOrderNumbers($jobId);
	if ( scalar(@orders) > 1 ) {

		@orders = grep { $_->{"stav"} == 4 } @orders;    #Ve vırobì (4)

		for ( my $i = scalar(@orders) - 1 ; $i > 0 ; $i-- ) {
			if ( HegMethods->GetInfMasterSlave( $orders[$i]->{"reference_subjektu"} ) eq "S" ) {
				splice @orders, $i, 1;
			}
		}
	}

	$groupData->SetSendToServer(1) if ( scalar(@orders) );

	# 4) Set test panel frame
	my $testFrame = 0;
	if (
		 CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $stepToTest )
		 && ( $stepToTest eq "mpanel"
			  || grep { $_->{"stepName"} =~ /^mpanel\d*/ } CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $stepToTest ) )
		 && !$defaultInfo->GetIsFlex()
	  )
	{
		$testFrame = 1;
	}

	$groupData->SetIncldMpanelFrm($testFrame);

	return $groupData;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

