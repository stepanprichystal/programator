
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::AOIExport::Presenter::AOIUnit;
use base 'Programs::Exporter::ExportChecker::Groups::UnitBase';

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm';
 
use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::AOIExport::Model::AOICheckData';
use aliased 'Programs::Exporter::ExportChecker::Groups::AOIExport::Model::AOIPrepareData';
use aliased 'Programs::Exporter::ExportChecker::Groups::AOIExport::Model::AOIExportData';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Programs::Exporter::ExportChecker::Groups::AOIExport::View::AOIUnitForm';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	#uique key within all units
	$self->{"unitId"} = UnitEnums->UnitId_AOI;

	my $checkData = AOICheckData->new();
	my $prepareData = AOIPrepareData->new();
	my $exportData = AOIExportData->new();
		
	
	$self->{"dataMngr"} = GroupDataMngr->new( $self->{"jobId"}, $prepareData, $checkData, $exportData);

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
	$self->{"form"} = AOIUnitForm->new( $parent, $inCAM, $self->{"jobId"} );

	$self->_SetHandlers();

}

sub RefreshGUI {
	my $self = shift;

	my $groupData = $self->{"dataMngr"}->GetGroupData();

	#refresh group form
	$self->{"form"}->SetStepToTest( $groupData->GetStepToTest() );
	$self->{"form"}->SetLayers( $groupData->GetLayers() );
	$self->{"form"}->SetSendToServer( $groupData->GetSendToServer() );
	$self->{"form"}->SetIncldMpanelFrm( $groupData->GetIncldMpanelFrm() );

}

# Update groupd data with values from GUI
sub UpdateGroupData {
	my $self = shift;

	my $frm = $self->{"form"};

	#if form is init/showed to user, return group data edited by form
	#else return default group data, not processed by form

	if ($frm) {
		my $groupData = $self->{"dataMngr"}->GetGroupData();
		
		$groupData->SetStepToTest( $frm->GetStepToTest() );
		$groupData->SetLayers( $frm->GetLayers() );
		$groupData->SetSendToServer( $frm->GetSendToServer() );
		$groupData->SetIncldMpanelFrm( $frm->GetIncldMpanelFrm() );
	
	}
	 
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

