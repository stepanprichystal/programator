
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for creation:
# - Export data, (from prepared group data), which will consume exporter utility. Handler: OnExportGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::OutExport::Model::OutExportData;
 

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'Programs::Exporter::DataTransfer::UnitsDataContracts::OutData';

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

	my $exportData = OutData->new();
 
 	$exportData->SetExportCooper( $groupData->GetExportCooper() );
	$exportData->SetExportET( $groupData->GetExportET() );
	$exportData->SetCooperStep( $groupData->GetCooperStep() );
  	$exportData->SetExportControl( $groupData->GetExportControl() );
  	$exportData->SetControlStep( $groupData->GetControlStep() );
 
  	
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



