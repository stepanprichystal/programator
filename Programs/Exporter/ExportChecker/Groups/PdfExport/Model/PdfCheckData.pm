#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PdfExport::Model::PdfCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;

	my $groupData = $dataMngr->GetGroupData();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $defaultInfo = $dataMngr->GetDefaultInfo();
	my $customerNote = $defaultInfo->GetCustomerNote();

	# 1) Warning, when pcb is not pool and pdf control is not checked
	if ( !$defaultInfo->IsPool() && !$groupData->GetExportControl() ) {

		$dataMngr->_AddWarningResult( "Export pdf control", "Dps není v poolu, kontrolní pdf by mělo být vyexportováno." );

	}
	
	
	# 2) Check if customer dont ewant operator info, if it is disables
	if ($customerNote->NoInfoToPdf() && $groupData->GetInfoToPdf() ) {

		$dataMngr->_AddErrorResult( "Operator info in pdf", "Zákazník si nepřeje vkládat info o operátorovi TPV do pdf. Zruš volbu 'Operator info'" );
	}
 
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

