
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for create final export data for group.
# Structure for export data is defined by "data contracts" see ..DataTransfer::UnitsDataContracts..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifExportData;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::NifData';
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

	my $stepName = "panel";

	my $exportData = NifData->new();

	# Author
	my $name = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "user_name" );
	$exportData->SetZpracoval($name);

	#$exportData->SetZpracoval( $ENV{"LOGNAME"} );

	# Other
	$exportData->SetTenting( $groupData->GetTenting() );
	$exportData->SetTechnology( $groupData->GetTechnology() );
	$exportData->SetMaska01( $groupData->GetMaska01() );
	$exportData->SetPressfit( $groupData->GetPressfit() );
	$exportData->SetToleranceHole( $groupData->GetToleranceHole() );
	$exportData->SetChamferEdges( $groupData->GetChamferEdges() );
	$exportData->SetQuickNotes( $groupData->GetQuickNotes() );
	$exportData->SetNotes( $groupData->GetNotes() );
	$exportData->SetDatacode( $groupData->GetDatacode() );
	$exportData->SetUlLogo( $groupData->GetUlLogo() );
	$exportData->SetJumpScoring( $groupData->GetJumpScoring() );

	# Mask, Silk color
	$exportData->SetS_silk_screen_colour2( $groupData->GetS_silk_screen_colour2() );
	$exportData->SetC_silk_screen_colour2( $groupData->GetC_silk_screen_colour2() );
	$exportData->SetFlexi_maska( $groupData->GetFlexi_maska() );
	$exportData->SetC_mask_colour( $groupData->GetC_mask_colour() );
	$exportData->SetS_mask_colour( $groupData->GetS_mask_colour() );
	$exportData->SetC_mask_colour2( $groupData->GetC_mask_colour2() );
	$exportData->SetS_mask_colour2( $groupData->GetS_mask_colour2() );
	$exportData->SetC_silk_screen_colour( $groupData->GetC_silk_screen_colour() );
	$exportData->SetS_silk_screen_colour( $groupData->GetS_silk_screen_colour() );

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

}

1;

