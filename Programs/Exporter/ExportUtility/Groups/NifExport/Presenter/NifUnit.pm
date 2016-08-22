
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::NifExport::Presenter::NifUnit;
#use base 'Programs::Exporter::ExportChecker::Groups::UnitBase';

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
 

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifDataMngr';
 
use aliased 'Programs::Exporter::UnitEnums';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::GroupWrapperForm';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::Presenter::NifExport';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	#$self = $class->SUPER::new(@_);
	bless $self;

	#uique key within all units
	$self->{"unitId"} = UnitEnums->UnitId_NIF;
	$self->{"unitExport"} = NifExport->new($self->{"unitId"});

	# init class for model
	return $self;    # Return the reference to the hash.
}


sub GetExportClass{
	my $self = shift;
	
	return $self->{"unitExport"};
}

#
##posloupnost volani metod
##1) new()
##2) InitForm()
##3) BuildGUI()
##4) InitDataMngr()
##5) RefreshGUI()
##==> export
##6) CheckBeforeExport()
##7) GetGroupData()
#
sub InitForm {
	my $self         = shift;
	my $parent = shift;
	#my $inCAM        = shift;

	$self->{"form"} = GroupWrapperForm->new($parent);

 

}
#
#sub RefreshGUI {
#	my $self = shift;
#
#	my $groupData = $self->{"dataMngr"}->GetGroupData();
#
#	#refresh group form
#	$self->{"form"}->SetTenting( $groupData->{"data"}->{"tenting"} );
#	$self->{"form"}->SetMaska01( $groupData->{"data"}->{"maska01"} );
#	$self->{"form"}->SetPressfit( $groupData->{"data"}->{"pressfit"} );
#	$self->{"form"}->SetNotes( $groupData->{"data"}->{"notes"} );
#	$self->{"form"}->SetDatacode( $groupData->{"data"}->{"datacode"} );
#	$self->{"form"}->SetUlLogo( $groupData->{"data"}->{"ul_logo"} );
#	$self->{"form"}->SetJumpScoring( $groupData->{"data"}->{"prerusovana_drazka"} );
#
#	# Dimension
#
#	$self->{"form"}->SetSingle_x( $groupData->GetSingle_x() );
#	$self->{"form"}->SetSingle_y( $groupData->GetSingle_y() );
#	$self->{"form"}->SetPanel_x( $groupData->GetPanel_x() );
#	$self->{"form"}->SetPanel_y( $groupData->GetPanel_y() );
#	$self->{"form"}->SetNasobnost_panelu( $groupData->GetNasobnost_panelu() );
#	$self->{"form"}->SetNasobnost( $groupData->GetNasobnost() );
#
#	# Mask color
#
#	$self->{"form"}->SetC_mask_colour( $groupData->GetC_mask_colour() );
#	$self->{"form"}->SetS_mask_colour( $groupData->GetS_mask_colour() );
#	$self->{"form"}->SetC_silk_screen_colour( $groupData->GetC_silk_screen_colour() );
#	$self->{"form"}->SetS_silk_screen_colour( $groupData->GetS_silk_screen_colour() );
#
#	#refresh wrapper
#	$self->_RefreshWrapper();
#}
#
#sub GetGroupData {
#
#	my $self = shift;
#
#	my $frm = $self->{"form"};
#
#	my $groupData;
#
#	#if form is init/showed to user, return group data edited by form
#	#else return default group data, not processed by form
#
#	if ($frm) {
#		$groupData = $self->{"dataMngr"}->GetGroupData();
#		$groupData->SetTenting( $frm->GetTenting() );
#		$groupData->SetMaska01( $frm->GetMaska01() );
#		$groupData->SetPressfit( $frm->GetPressfit() );
#		$groupData->SetNotes( $frm->GetNotes() );
#		$groupData->SetDatacode( $frm->GetDatacode() );
#		$groupData->SetUlLogo( $frm->GetUlLogo() );
#		$groupData->SetJumpScoring( $frm->GetJumpScoring() );
#
#		# Dimension
#
#		$groupData->SetSingle_x( $frm->GetSingle_x() );
#		$groupData->SetSingle_y( $frm->GetSingle_y() );
#		$groupData->SetPanel_x( $frm->GetPanel_x() );
#		$groupData->SetPanel_y( $frm->GetPanel_y() );
#		$groupData->SetNasobnost_panelu( $frm->GetNasobnost_panelu() );
#		$groupData->SetNasobnost( $frm->GetNasobnost() );
#
#		# Mask color
#
#		$groupData->SetC_mask_colour( $frm->GetC_mask_colour() );
#		$groupData->SetS_mask_colour( $frm->GetS_mask_colour() );
#		$groupData->SetC_silk_screen_colour( $frm->GetC_silk_screen_colour() );
#		$groupData->SetS_silk_screen_colour( $frm->GetS_silk_screen_colour() );
#
#	}
#	else {
#
#		$groupData = $self->{"dataMngr"}->GetGroupData();
#	}
#
#	return $groupData;
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

