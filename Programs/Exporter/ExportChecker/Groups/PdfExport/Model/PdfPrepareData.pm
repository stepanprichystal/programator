
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnIsGroupAllowed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PdfExport::Model::PdfPrepareData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::PdfExport::Model::PdfGroupData';
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral'; 
use aliased 'Connectors::HeliosConnector::HegMethods';

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

	#we want nif group allow always, so return ACTIVE ON
	return Enums->GroupState_ACTIVEON;

}

# Default "group data" are prepared in this method
sub OnPrepareGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = PdfGroupData->new();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	# 1) Export control
	my $exportControl = 1;

	if ( $defaultInfo->IsPool() ) {
		$exportControl = 0;
	}

	# 2) define default step
	my $defStep = undef;

	if ( $defaultInfo->StepExist("mpanel") ) {
		$defStep = "mpanel";
	}
	else {
		$defStep = "o+1";
	}

	# 3) default lang
	my $defLang = "English";

	my %inf = %{HegMethods->GetCustomerInfo($jobId)};

	# if country CZ
	if ( $inf{"zeme"} eq 25 ) {
		$defLang = "Czech";
	}

	# 4) default stackup export
	my $defStackup = 0;
	
	if($defaultInfo->GetLayerCnt() > 2){
		
		$defStackup = 1;
	}
 
	$groupData->SetExportControl($exportControl);
	$groupData->SetControlStep($defStep);
	$groupData->SetControlLang($defLang);
	$groupData->SetExportStackup($defStackup);
 
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

