
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for create final export data for group.
# Structure for export data is defined by "data contracts" see ..DataTransfer::UnitsDataContracts..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCExportData;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::NCData';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;
}

# Export data, (from prepared group data), which will consume exporter utility
# are prepared in this method
sub OnExportGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = $dataMngr->GetGroupData();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $stepName = "panel";

	my $exportData = NCData->new();
 
	$exportData->SetExportSingle( $groupData->GetExportSingle() );
	$exportData->SetPltLayers( $groupData->GetPltLayers() );
	$exportData->SetNPltLayers( $groupData->GetNPltLayers() );
	 
	return $exportData;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

