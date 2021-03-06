
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for creation:
# - Export data, (from prepared group data), which will consume exporter utility. Handler: OnExportGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::StnclExport::Model::StnclExportData;

#3th party library
use strict;
use warnings;
use File::Copy;

#local library

use aliased 'Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::StnclData';
use aliased 'Programs::Stencil::StencilSerializer::StencilSerializer';

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

	# Store info from export to stencil params file

	my $ser = StencilSerializer->new($jobId);
	my $par = $ser->LoadStenciLParams();

	# Fiducials
	$par->SetFiducial( $groupData->GetFiducialInfo() );

	# Stencil thickness
	$par->SetThickness( $groupData->GetThickness() );

	$ser->SaveStencilParams($par);

	my $exportData = StnclData->new();

	$exportData->SetThickness( $groupData->GetThickness() );
	$exportData->SetExportNif( $groupData->GetExportNif() );
	$exportData->SetExportData( $groupData->GetExportData() );
	$exportData->SetExportPdf( $groupData->GetExportPdf() );
	$exportData->SetDim2ControlPdf( $groupData->GetDim2ControlPdf() );
	$exportData->SetExportMeasureData( $groupData->GetExportMeasureData() );
	$exportData->SetFiducialInfo( $groupData->GetFiducialInfo() );

	return $exportData;

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

