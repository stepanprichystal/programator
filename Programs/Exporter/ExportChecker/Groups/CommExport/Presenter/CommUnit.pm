
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::CommExport::Presenter::CommUnit;
use base 'Programs::Exporter::ExportChecker::Groups::UnitBase';

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm';
 
use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::Model::CommCheckData';
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::Model::CommPrepareData';
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::Model::CommExportData';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Programs::Exporter::ExportChecker::Groups::CommExport::View::CommUnitForm';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	#uique key within all units
	$self->{"unitId"} = UnitEnums->UnitId_Comm;

	my $checkData = CommCheckData->new();
	my $prepareData = CommPrepareData->new();
	my $exportData = CommExportData->new();
		
	
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
	$self->{"form"} = CommUnitForm->new( $parent, $inCAM, $self->{"jobId"}, $self->{"dataMngr"}->GetDefaultInfo() );

	$self->_SetHandlers();

}

sub RefreshGUI {
	my $self = shift;

	my $groupData = $self->{"dataMngr"}->GetGroupData();

	#refresh group form
	$self->{"form"}->SetStepToTest( $groupData->GetStepToTest(), $groupData->GetCreateEtStep() );
	$self->{"form"}->SetCreateEtStep( $groupData->GetCreateEtStep() );
	$self->{"form"}->SetKeepProfiles( $groupData->GetKeepProfiles() );
	$self->{"form"}->SetLocalCopy( $groupData->GetLocalCopy() );
	$self->{"form"}->SetServerCopy( $groupData->GetServerCopy() );	
 

}

sub GetGroupData {

	my $self = shift;

	my $frm = $self->{"form"};

	my $groupData;

	#if form is init/showed to user, return group data edited by form
	#else return default group data, not processed by form

	if ($frm) {
		$groupData = $self->{"dataMngr"}->GetGroupData();
		
		$groupData->SetStepToTest( $frm->GetStepToTest() );
		$groupData->SetCreateEtStep( $frm->GetCreateEtStep() );
		$groupData->SetKeepProfiles( $frm->GetKeepProfiles() );
		$groupData->SetLocalCopy( $frm->GetLocalCopy() );
		$groupData->SetServerCopy( $frm->GetServerCopy() );	
	 
			
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

