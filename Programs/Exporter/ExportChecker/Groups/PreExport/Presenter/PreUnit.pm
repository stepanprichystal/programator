
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::Presenter::PreUnit;
use base 'Programs::Exporter::ExportChecker::Groups::UnitBase';

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::PreUnitFormEvt';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::PreUnitForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Model::PreCheckData';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Model::PrePrepareData';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Model::PreExportData';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Model::PreGroupData';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	#uique key within all units
	$self->{"unitId"} = UnitEnums->UnitId_PRE;

	# GUI exist
	$self->{"formLess"} = 0;

	# init class for model
	my $checkData   = PreCheckData->new();
	my $prepareData = PrePrepareData->new();
	my $exportData  = PreExportData->new();

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
	$self->{"form"} = PreUnitForm->new( $parent, $inCAM, $self->{"jobId"}, $self->{"dataMngr"}->GetDefaultInfo() );

	# init base class with event class
	$self->{"eventClass"} = PreUnitFormEvt->new( $self->{"form"} );

	$self->_SetHandlers();

}

sub RefreshGUI {
	my $self = shift;

	my $groupData = $self->{"dataMngr"}->GetGroupData();

	#refresh group form
	$self->{"form"}->SetSignalLayers( $groupData->GetSignalLayers() );
	$self->{"form"}->SetOtherLayers( $groupData->GetOtherLayers() );
	$self->{"form"}->SetNCLayersSett( $groupData->GetNCLayersSett() );

}

# Update groupd data with values from GUI
sub UpdateGroupData {
	my $self = shift;

	my $frm = $self->{"form"};

	#if form is init/showed to user, return group data edited by form
	#else return default group data, not processed by form

	if ($frm) {
		my $groupData = $self->{"dataMngr"}->GetGroupData();

		$groupData->SetSignalLayers( $frm->GetSignalLayers() );
		$groupData->SetOtherLayers( $frm->GetOtherLayers() );
		$groupData->SetNCLayersSett( $frm->GetNCLayersSett() );

	}
	 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

