
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PlotExport::Presenter::PlotUnit;
use base 'Programs::Exporter::ExportChecker::Groups::UnitBase';

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotUnitForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotUnitFormEvt';

use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::Model::PlotCheckData';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::Model::PlotPrepareData';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::Model::PlotExportData';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::Model::PlotGroupData';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExporterUtility::UnitEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	#uique key within all units
	$self->{"unitId"} = UnitEnums->UnitId_PLOT;

	# init class for model
	my $checkData   = PlotCheckData->new();
	my $prepareData = PlotPrepareData->new();
	my $exportData  = PlotExportData->new();

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
	$self->{"form"} = PlotUnitForm->new( $parent, $inCAM, $self->{"jobId"});
	
	# init base class with event class
	$self->{"eventClass"} = PlotUnitFormEvt->new($self->{"form"});

	$self->_SetHandlers();

}

sub RefreshGUI {
	my $self = shift;

	my $groupData = $self->{"dataMngr"}->GetGroupData();

	#refresh group form
	$self->{"form"}->SetSendToPlotter( $groupData->GetSendToPlotter() );
	$self->{"form"}->SetLayers( $groupData->GetLayers() );
 
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
		
		$groupData->SetSendToPlotter( $frm->GetSendToPlotter() );
		$groupData->SetLayers( $frm->GetLayers() );
		 

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

