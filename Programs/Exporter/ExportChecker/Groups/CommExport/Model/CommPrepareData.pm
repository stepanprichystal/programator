
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnIsGroupAllowed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::CommExport::Model::CommPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::Model::CommGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Commesting::BasicHelper::Helper' => 'CommHelper';
use aliased 'CamHelpers::CamAttributes';

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

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $state = Enums->GroupState_DISABLE;

 
	if ( HegMethods->GetElTest($jobId) ) {

		$state = Enums->GroupState_ACTIVEON;

	}
	else {

		if ( $defaultInfo->GetPcbClass() <= 3 && $defaultInfo->GetLayerCnt() == 1 ) {

			$state = Enums->GroupState_DISABLE;

		}
		else {

			$state = Enums->GroupState_ACTIVEON;
		}
	}

	#we want nif group allow always, so return ACTIVE ON
	return $state;
}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = CommGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	$groupData->SetStepToTest("panel");

	$groupData->SetCreateEtStep(1);

	# 5) if customer panel, do not check panel
	my $custPnl = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_panel" );
	my $custSet = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_set" );
	
	my $keepProfiles = CommHelper->KeepProfilesAllowed( $inCAM, $jobId, "panel" );

	if ( $keepProfiles 
		&& ( !defined $custPnl || ( defined $custPnl && $custPnl eq "no" ) ) 
		&& ( !defined $custSet || ( defined $custSet && $custSet eq "no" ) ) ) {
		$groupData->SetKeepProfiles(1);
	}
	else {

		$groupData->SetKeepProfiles(0);

	}
 

	# Set server and local copy of IPC
	if ($groupData->GetKeepProfiles()) {

		$groupData->SetLocalCopy(0); # Set local copy IPC (only if keep profiles is set)
	
	}else{
		
		$groupData->SetLocalCopy(1);
	}
 
 	# Set server copy always (in order TPV office is closed and production need ipc)
 	$groupData->SetServerCopy(1);
 	
 
 
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

