
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifUnit;
use base 'Programs::Exporter::ExportChecker::Groups::UnitBase';

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm';

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifCheckData';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifPrepareData';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifExportData';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	#uique key within all units
	$self->{"unitId"} = "nifUnit";

	my $checkData   = NifCheckData->new();
	my $prepareData = NifPrepareData->new();
	my $exportData  = NifExportData->new();

	$self->{"dataMngr"} = GroupDataMngr->new( $self->{"jobId"}, $prepareData, $checkData, $exportData );

	return $self;    # Return the reference to the hash.
}

#posloupnost volani metod
#1) new()
#2) InitForm()
#3) BuildGUI()
#4) InitDataMngr()
#5) RefreshGUI()
#==> export
#6) CheckBeforeExport()
#7) GetGroupData()

sub InitForm {
	my $self         = shift;
	my $groupWrapper = shift;
	my $inCAM        = shift;

	$self->{"groupWrapper"} = $groupWrapper;

	my $parent = $groupWrapper->GetParentForGroup();
	$self->{"form"} = NifUnitForm->new( $parent, $inCAM, $self->{"jobId"}, $self->{"title"} );
}



sub RefreshGUI {
	my $self = shift;

	my $groupData->{"data"} = $self->{"dataMngr"}->GetGroupData();

	#refresh group form
	$self->{"form"}->SetTenting( $groupData->{"tenting"} );
	$self->{"form"}->SetMaska01( $groupData->{"maska01"} );
	$self->{"form"}->SetPressfit( $groupData->{"pressfit"} );
	$self->{"form"}->SetNotes( $groupData->{"notes"} );
	$self->{"form"}->SetDatacode( $groupData->{"datacode"} );
	$self->{"form"}->SetUlLogo( $groupData->{"ul_logo"} );
	$self->{"form"}->SetJumpScoring( $groupData->{"prerusovana_drazka"} );

	#refresh wrapper
	$self->_RefreshWrapper();
}

sub GetGroupData {

	my $self = shift;

	my $frm = $self->{"form"};

	my $groupData;

	#if form is init/showed to user, return group data created by form
	#else return default group data, not processed by form

	if ($frm) {
		$groupData = NifGroupData->new();
		$groupData->SetTenting( $frm->GetTenting() );
		$groupData->SetMaska01( $frm->GetMaska01() );
		$groupData->SetPressfit( $frm->GetPressfit() );
		$groupData->SetNotes( $frm->GetNotes() );
		$groupData->SetDatacode( $frm->GetDatacode() );
		$groupData->SetUlLogo( $frm->GetUlLogo() );
		$groupData->SetJumpScoring( $frm->GetJumpScoring() );

	}
	else {

		$groupData = $self->{"dataMngr"}->GetGroupData();
	}

	return $groupData;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

