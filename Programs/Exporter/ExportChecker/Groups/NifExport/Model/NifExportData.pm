
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for creation:
# - Export data, (from prepared group data), which will consume exporter utility. Handler: OnExportGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifExportData;

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
 
use aliased 'Programs::Exporter::DataTransfer::UnitsDataContracts::NifData';

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

	my $exportData = NifData->new();

	# Author
	$exportData->SetZpracoval( $ENV{"LOGNAME"} );
	
	# Other
	$exportData->SetTenting( $groupData->GetTenting() );
	$exportData->SetMaska01( $groupData->GetMaska01() );
	$exportData->SetPressfit( $groupData->GetPressfit() );
	$exportData->SetNotes( $groupData->GetNotes() );
	$exportData->SetDatacode( $groupData->GetDatacode() );
	$exportData->SetUlLogo( $groupData->GetUlLogo() );
	$exportData->SetJumpScoring( $groupData->GetJumpScoring() );

	# Mask, Silk color
	$exportData->SetC_mask_colour( $groupData->GetC_mask_colour() );
	$exportData->SetS_mask_colour( $groupData->GetS_mask_colour() );
	$exportData->SetC_silk_screen_colour( $groupData->GetC_silk_screen_colour() );
	$exportData->SetS_silk_screen_colour( $groupData->SetS_silk_screen_colour() );

	# Dimension
	$exportData->SetSingle_x( $groupData->GetSingle_x() );
	$exportData->SetSingle_y( $groupData->GetSingle_y() );
	$exportData->SetPanel_x( $groupData->GetPanel_x() );
	$exportData->SetPanel_y( $groupData->GetPanel_y() );
	$exportData->SetNasobnost_panelu( $groupData->GetNasobnost_panelu() );
	$exportData->SetNasobnost( $groupData->GetNasobnost() );

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

