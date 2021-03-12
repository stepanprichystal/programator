
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SizePart::Control::SizePart;
use base 'Programs::Panelisation::PnlWizard::Parts::PartBase';

use Class::Interface;
&implements('Programs::Panelisation::PnlWizard::Parts::IPart');

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm';

#use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpCheckData';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpPrepareData';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpExportData';
#use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::View::ImpUnitForm';

use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Model::SizePartModel'   => 'PartModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::SizePartFrm'      => 'PartFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Control::SizePartCheck' => 'PartCheckClass';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new( Enums->Part_PNLSIZE, @_ );
	bless $self;

	#uique key within all units

	$self->{"model"} = PartModel->new();

	$self->{"checkClass"} = PartCheckClass->new();

	$self->{"frmHandlersOff"} = 0;

	$self->{"isPartFullyInited"} = 0;
	#
	#	my $checkData = ImpCheckData->new();
	#	my $prepareData = ImpPrepareData->new();
	#	my $exportData = ImpExportData->new();
	#
	#
	#	$self->{"dataMngr"} = GroupDataMngr->new( $self->{"jobId"}, $prepareData, $checkData, $exportData);

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
	my $self        = shift;
	my $partWrapper = shift;
	my $inCAM       = shift;

	my $parent = $partWrapper->GetParentForPart();

	$self->{"form"} = PartFrm->new( $parent, $inCAM, $self->{"jobId"}, $self->{"model"} );

	#$self->{"form"}->{"oncreatorSelectionChangedEvt"}->Add( sub { $self->__OnCreatorSelectionChangedHndl(@_) } );
	$self->{"form"}->{"creatorSelectionChangedEvt"}->Add( sub { $self->__OnCreatorSelectionChangedHndl(@_) } );

	$self->SUPER::_InitForm($partWrapper);

}

sub InitPartModel {
	my $self          = shift;
	my $inCAM         = shift;
	my $restoredModel = shift;

	if ( defined $restoredModel ) {

		# Load settings from history

		$self->{"model"} = $restoredModel;
	}
	else {

		# Init default
	}
}

sub OnOtherPartCreatorSelChangedHndl {
	my $self            = shift;
	my $partId          = shift;
	my $creatorKey      = shift;
	my $creatorSettings = shift;

}

sub OnOtherPartCreatorSettChangedHndl {
	my $self       = shift;
	my $partId     = shift;
	my $creatorKey = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

