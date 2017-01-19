
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PdfExport::Presenter::PdfUnit;
use base 'Programs::Exporter::ExportChecker::Groups::UnitBase';

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm';

use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::PdfExport::Model::PdfCheckData';
use aliased 'Programs::Exporter::ExportChecker::Groups::PdfExport::Model::PdfPrepareData';
use aliased 'Programs::Exporter::ExportChecker::Groups::PdfExport::Model::PdfExportData';
use aliased 'Programs::Exporter::UnitEnums';
use aliased 'Programs::Exporter::ExportChecker::Groups::PdfExport::View::PdfUnitForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PdfExport::View::PdfUnitFormEvt';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	#uique key within all units
	$self->{"unitId"} = UnitEnums->UnitId_PDF;

	my $checkData   = PdfCheckData->new();
	my $prepareData = PdfPrepareData->new();
	my $exportData  = PdfExportData->new();

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
	$self->{"form"} = PdfUnitForm->new( $parent, $inCAM, $self->{"jobId"} );

	# init base class with event class
	$self->{"eventClass"} = PdfUnitFormEvt->new( $self->{"form"} );

	$self->_SetHandlers();

}

sub RefreshGUI {
	my $self = shift;

	my $groupData = $self->{"dataMngr"}->GetGroupData();

	#refresh group form
	$self->{"form"}->SetExportControl( $groupData->GetExportControl() );
	$self->{"form"}->SetControlStep( $groupData->GetControlStep() );
	$self->{"form"}->SetControlLang( $groupData->GetControlLang() );
	$self->{"form"}->SetExportStackup( $groupData->GetExportStackup() );
	$self->{"form"}->SetInfoToPdf( $groupData->GetInfoToPdf() );
	

	#refresh wrapper
	$self->_RefreshWrapper();
}

sub GetGroupData {

	my $self = shift;

	my $frm = $self->{"form"};

	my $groupData;

	#if form is init/showed to user, return group data edited by form
	#else return default group data, not processed by form

	if ($frm) {
		$groupData = $self->{"dataMngr"}->GetGroupData();

		$groupData->SetExportControl( $frm->GetExportControl() );
		$groupData->SetControlStep( $frm->GetControlStep() );
		$groupData->SetControlLang( $frm->GetControlLang() );
		$groupData->SetExportStackup( $frm->GetExportStackup() );
		$groupData->SetInfoToPdf( $frm->GetInfoToPdf() );
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

