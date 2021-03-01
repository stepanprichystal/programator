
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
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Model::SizePartModel' => 'PartModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::SizePartFrm'    => 'PartFrm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	#uique key within all units
	$self->{"partId"} = Enums->Part_PNLSIZE;

	$self->{"model"} = PartModel->new();
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

	$self->{"partWrapper"} = $partWrapper;

	my $parent = $partWrapper->GetParentForPart();

	$self->{"form"} = PartFrm->new( $parent, $inCAM, $self->{"jobId"}, $self->{"model"} );
	#
	#	$self->_SetHandlers();

}

sub InitModel {
	my $self         = shift;
	my $restoredData = shift;

	if ( defined $restoredData ) {
		
		# Load settings from history

		$self->{"model"} = $restoredData;
	}
	else {
		
		# Set default settings
		#$self->{"model"}->SetSelectedCreator()
		
	}
}

sub ProcessPart{
	my $self = shift;
	
	$self->{"model"}->SetCreators( $self->{"form"}->GetCreators() );
	$self->{"model"}->SetSelectedCreator( $self->{"form"}->GetSelectedCreator() );
	
	 
	
}




sub RefreshGUI {
	my $self = shift;

	#my $groupData = $self->{"dataMngr"}->GetGroupData();

	#refresh group form
	$self->{"form"}->SetCreators( $self->{"model"}->GetCreators() );
	$self->{"form"}->SetSelectedCreator( $self->{"model"}->GetSelectedCreator() );

}

#
## Update groupd data with values from GUI
#sub UpdateGroupData {
#	my $self = shift;
#
#	my $frm = $self->{"form"};
#
#	#if form is init/showed to user, return group data edited by form
#	#else return default group data, not processed by form
#
#	if ($frm) {
#		my $groupData = $self->{"dataMngr"}->GetGroupData();
#
#		$groupData->SetExportMeasurePdf( $frm->GetExportMeasurePdf() );
#		$groupData->SetBuildMLStackup( $frm->GetBuildMLStackup() );
#
#	}
#
#}

#-------------------------------------------------------------------------------------------#
#  Handlers
#-------------------------------------------------------------------------------------------#

#sub __OnGetCreator


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

