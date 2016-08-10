
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for creation:
# - Export data, (from prepared group data), which will consume exporter utility. Handler: OnExportGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCExportData;
 

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
#use aliased 'CamHelpers::CamJob';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamLayer';
#use aliased 'CamHelpers::CamAttributes';
#
#
#use aliased 'CamHelpers::CamDrilling';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Enums::EnumsGeneral';
#use aliased 'Helpers::JobHelper';
#use aliased 'Packages::InCAM::InCAM';
#use aliased 'Enums::EnumsMachines';
#use aliased 'Helpers::GeneralHelper';
#use aliased 'Packages::Events::Event';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Managers::MessageMngr::MessageMngr';

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
	my $self    = shift;
	my $dataMngr = shift;	#instance of GroupDataMngr	
 
	my %groupData = $dataMngr->GetGroupData();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};
 
	my $stepName = "panel";
	
	my %exportData = ();
	
	$exportData{"exportSingle"} = $groupData{"exportSingle"};
	$exportData{"pltLayers"}    = $groupData{"pltLayers"};
	$exportData{"npltLayers"}   = $groupData{"npltLayers"};

	return %exportData;
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














