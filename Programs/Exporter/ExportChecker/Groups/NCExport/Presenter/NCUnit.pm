
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NCExport::Presenter::NCUnit;
use base 'Programs::Exporter::ExportChecker::Groups::UnitBase';

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::View::NCUnitForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::View::NCUnitFormEvt';
use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCCheckData';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCPrepareData';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCExportData';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCGroupData';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	#uique key within all units
	$self->{"unitId"} = UnitEnums->UnitId_NC;

	# init class for model
	my $checkData   = NCCheckData->new();
	my $prepareData = NCPrepareData->new();
	my $exportData  = NCExportData->new();

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
	$self->{"form"} = NCUnitForm->new( $parent, $inCAM, $self->{"jobId"} );

	# init base class with event class
	$self->{"eventClass"} = NCUnitFormEvt->new( $self->{"form"} );

	$self->_SetHandlers();

}

sub RefreshGUI {
	my $self = shift;

	my $groupData = $self->{"dataMngr"}->GetGroupData();

	#refresh group form
	$self->{"form"}->SetExportMode( $groupData->GetExportMode() );
	$self->{"form"}->SetAllModeLayers( $groupData->GetAllModeLayers() );
	$self->{"form"}->SetAllModeExportPnl( $groupData->GetAllModeExportPnl() );
	$self->{"form"}->SetAllModeExportPnlCpn( $groupData->GetAllModeExportPnlCpn() );
	$self->{"form"}->SetSingleModePltLayers( $groupData->GetSingleModePltLayers() );
	$self->{"form"}->SetSingleModeNPltLayers( $groupData->GetSingleModeNPltLayers() );

}

# Update groupd data with values from GUI
sub UpdateGroupData {
	my $self = shift;

	my $frm = $self->{"form"};

	#if form is init/showed to user, return group data edited by form
	#else return default group data, not processed by form

	if ($frm) {
		my $groupData = $self->{"dataMngr"}->GetGroupData();
		$groupData->SetExportMode( $frm->GetExportMode() );
		$groupData->SetAllModeLayers( $frm->GetAllModeLayers() );
		$groupData->SetAllModeExportPnl( $frm->GetAllModeExportPnl() );
		$groupData->SetAllModeExportPnlCpn( $frm->GetAllModeExportPnlCpn() );
		$groupData->SetSingleModePltLayers( $frm->GetSingleModePltLayers() );
		$groupData->SetSingleModeNPltLayers( $frm->GetSingleModeNPltLayers() );

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

