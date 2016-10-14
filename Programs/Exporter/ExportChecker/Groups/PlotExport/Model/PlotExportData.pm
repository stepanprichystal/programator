
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for create final export data for group.
# Structure for export data is defined by "data contracts" see ..DataTransfer::UnitsDataContracts..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PlotExport::Model::PlotExportData;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Programs::Exporter::DataTransfer::UnitsDataContracts::PlotData';
use aliased 'CamHelpers::CamAttributes';
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

	my $exportData = PlotData->new();

	# Other
	$exportData->SetSendToPlotter( $groupData->GetSendToPlotter() );
	$exportData->SetLayers( $groupData->GetLayers() );
	 

	return $exportData;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

