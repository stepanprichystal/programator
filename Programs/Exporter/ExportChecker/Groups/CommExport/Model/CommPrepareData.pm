
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
use aliased 'CamHelpers::CamAttributes';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsIS';
use aliased 'Helpers::JobHelper';
use aliased 'Programs::Comments::CommMail::Enums' => 'MailEnums';

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

	if ( $defaultInfo->GetComments()->Exists() || JobHelper->GetJobIsOffer($jobId) ) {

		$state = Enums->GroupState_ACTIVEON;

	}
	else {

		$state = Enums->GroupState_DISABLE;
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

	my $comments = $defaultInfo->GetComments();
	
	 
	# Prder status 
	$groupData->SetChangeOrderStatus(0);
	$groupData->SetOrderStatus("");
	
	# sent mail
	$groupData->SetExportEmail(0);
	$groupData->SetEmailAction(MailEnums->EmailAction_SEND);
	$groupData->SetEmailToAddress([]);
	$groupData->SetEmailCCAddress([]);
	$groupData->SetEmailSubject("");
	$groupData->SetClearComments(0);
 
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

