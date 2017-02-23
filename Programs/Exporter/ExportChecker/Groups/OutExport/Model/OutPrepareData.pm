
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnIsGroupAllowed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::OutExport::Model::OutPrepareData;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::OutExport::Model::OutGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Other::CustomerNote';

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

	my $defaultInfo  = $dataMngr->GetDefaultInfo();
	my $customerNote = $defaultInfo->GetCustomerNote();

	# if customer request control data, group is ON
	if ( defined $customerNote->ExportDataControl() && $customerNote->ExportDataControl() == 1 ) {
			
			return Enums->GroupState_ACTIVEON;
	}else{
			return Enums->GroupState_ACTIVEOFF;
	}

}

# Method decide if group has to be exported, thus if is mandatory
# Return enum: Enums->GroupMandatory_<NO/YES>
sub OnGetGroupMandatory {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	#we want "out" group is not mandatory
	return Enums->GroupMandatory_NO;

}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = OutGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo  = $dataMngr->GetDefaultInfo();
	my $customerNote = $defaultInfo->GetCustomerNote();

	$groupData->SetExportCooper(0);
	$groupData->SetExportET(1);

	my $cooperStep      = "o+1";
	my $mpanelExist = $defaultInfo->StepExist("mpanel");

	if ($mpanelExist) {
		$cooperStep = "mpanel";
	}

	$groupData->SetCooperStep($cooperStep);

	my $exportControl = 0;

	if ( defined $customerNote->ExportDataControl() && $customerNote->ExportDataControl() == 1 ) {
		$exportControl = 1;
	}

	$groupData->SetExportControl($exportControl);
	
	$groupData->SetControlStep($cooperStep);

	return $groupData;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

