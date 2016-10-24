
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

use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Model::PreCheckData';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Model::PrePrepareData';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Model::PreExportData';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::Model::PreGroupData';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::UnitEnums';
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
	$self->{"formLess"} = 1;

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

	unless($self->IsFormLess()){
			
			my $parent = $groupWrapper->GetParentForGroup();
			$self->{"form"} = undef;
	}

	
	# init base class with event class
	$self->{"eventClass"}  = PreUnitFormEvt->new($self);

	$self->_SetHandlers();

}

sub RefreshGUI {
	my $self = shift;

	#my $groupData = $self->{"dataMngr"}->GetGroupData();

	#refresh group form
	#$self->{"form"}->SetSendToPlotter( $groupData->GetSendToPlotter() );
	#$self->{"form"}->SetLayers( $groupData->GetLayers() );

	#refresh wrapper
	#$self->_RefreshWrapper();
}

sub GetGroupData {

	my $self = shift;

	#my $frm = $self->{"form"};
	my $groupData = $self->{"dataMngr"}->GetGroupData();

	# Check changes during setting of export

	if ( defined $self->{"tentingCS"} ) {

		my $etchType;
		if ( $self->{"tentingCS"} == 1 ) {
			$etchType = EnumsGeneral->Etching_TENTING;
		}
		else {
			$etchType = EnumsGeneral->Etching_PATTERN;
		}

		my @layers = $groupData->GetSignalLayers();
		foreach my $l (@layers) {

			if ( $l->{"name"} =~ /^[cs]$/ ) {
				$l->{"etchingType"} = $etchType;
			}
		}

		$groupData->SetSignalLayers(\@layers );
	}

	return $groupData;
}

# --------------------------------------------------------------
# Handlers, which handle events from another units/groups
# --------------------------------------------------------------

sub ChangeTentingHandler {
	my $self      = shift;
	my $tentingCS = shift;

	# save new settings to object

	$self->{"tentingCS"} = $tentingCS;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

