
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::StepPart::Control::StepPart;
use base 'Programs::Panelisation::PnlWizard::Parts::PartBase';

use Class::Interface;
&implements('Programs::Panelisation::PnlWizard::Parts::IPart');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Model::StepPartModel'   => 'PartModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::StepPartFrm'      => 'PartFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Control::StepPartCheck' => 'PartCheckClass';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::Helper'                        => "CreatorHelper";
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlToJSON';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new( Enums->Part_PNLSTEPS, @_ );
	bless $self;

	# PROPERTIES

	$self->{"model"}      = PartModel->new();         # Data model for view
	$self->{"checkClass"} = PartCheckClass->new();    # Checking model before panelisation

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Interface method
#-------------------------------------------------------------------------------------------#

# Set part View
# Dock part View into passed View wrapper
sub InitForm {
	my $self        = shift;
	my $partWrapper = shift;
	my $inCAM       = shift;

	my $parent = $partWrapper->GetParentForPart();

	$self->{"form"} = PartFrm->new( $parent, $inCAM, $self->{"jobId"}, $self->{"model"} );

	$self->{"form"}->{"manualPlacementEvt"}->Add( sub { $self->__OnManualPlacementHndl(@_) } );

	$self->SUPER::_InitForm($partWrapper);

}

# Initialize part model by:
# - Restored data from disc
# - Default depanding on panelisation type
sub InitPartModel {
	my $self          = shift;
	my $inCAM         = shift;
	my $restoredModel = shift;

	if ( defined $restoredModel ) {

		# Load settings from restored data

		$self->{"model"} = $restoredModel;
	}
	else {

		# Init default
		# Init default
		my $defCreator = @{ $self->{"model"}->GetCreators() }[0];
		$self->{"model"}->SetSelectedCreator( $defCreator->GetModelKey() );
	}
}

sub __OnManualPlacementHndl {
	my $self      = shift;
	my $pauseText = shift;

	# Check if preview mode is active
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	unless ( $self->GetPreview() ) {

		my $messMngr = $self->{"partWrapper"}->GetMessMngr();
		my @mess     = ();
		push( @mess, " \"Preview mode\" must be active for manual panel pick/adjust." );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

		return 0;
	}

	# Do check of selected creator
	my $creatorKey   = $self->{"form"}->GetSelectedCreator();
	my $creatorModel = $self->{"form"}->GetCreators($creatorKey)->[0];
	$creatorModel->SetManualPlacementJSON(undef);
	$creatorModel->SetManualPlacementStatus( EnumsGeneral->ResultType_NA );

	my $creator = CreatorHelper->GetPnlCreatorByKey( $self->{"jobId"}, $self->{"pnlType"}, $creatorKey );

	$creator->ImportSettings( $creatorModel->ExportCreatorSettings() );

	my $errMess = "";
	my $result  = 0;    # succes / failure od manual step placement

	if ( $creator->Check( $inCAM, \$errMess ) ) {

		my $step = $creatorModel->GetStep();

		# Remove steps
		if (    $creatorKey eq PnlCreEnums->StepPnlCreator_AUTOUSER
			 || $creatorKey eq PnlCreEnums->StepPnlCreator_AUTOHEG
			 || $creatorKey eq PnlCreEnums->StepPnlCreator_SET )
		{

			foreach my $s ( CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step ) ) {
				CamStepRepeat->DeleteStepAndRepeat( $inCAM, $jobId, $step, $s->{"stepName"} );
			}
		}

		# Hide form
		$self->{"showPnlWizardFrmEvt"}->Do(0);
		$inCAM->PAUSE($pauseText);
		$self->{"showPnlWizardFrmEvt"}->Do(1);

		# Show form

		my $pnlToJSON = PnlToJSON->new( $inCAM, $jobId, $step );

		my $errMessJSON = "";

		if ( $pnlToJSON->CheckBeforeParse( \$errMessJSON ) ) {

			my $JSON = $pnlToJSON->ParsePnlToJSON();

			if ( defined $JSON ) {

				$creatorModel->SetManualPlacementJSON($JSON);
				$creatorModel->SetManualPlacementStatus( EnumsGeneral->ResultType_OK );

				$result = 1;
			}

		}
		else {

			$self->{"showPnlWizardFrmEvt"}->Do(1);

			my $messMngr = $self->{"partWrapper"}->GetMessMngr();
			my @mess     = ();
			push( @mess, "Manual step placement failed. Detail:\n\n" );
			push( @mess, $errMessJSON );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

		}

	}
	else {

		my $messMngr = $self->{"partWrapper"}->GetMessMngr();
		my @mess     = ();
		push( @mess, "Check before manual panel pick/adjus failed. Detail:\n\n" );
		push( @mess, $errMess );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

	}

	# Update form
	$self->{"frmHandlersOff"} = 1;

	$self->{"form"}->SetCreators( [$creatorModel] );

	$self->{"frmHandlersOff"} = 0;

	# Call change settings to return panel automatically to former settings if fail
	unless ($result) {

		$self->__OnCreatorSettingsChangedHndl($creatorKey);
	}

}

# Handler which catch change of creatores in other parts
# Creator settings changed riase in following situations:

sub OnOtherPartCreatorSelChangedHndl {
	my $self            = shift;
	my $partId          = shift;
	my $creatorKey      = shift;
	my $creatorSettings = shift;    # creator model

	#	# process creator if Part size was changed
	#	if ( $partId eq Enums->Part_PNLSIZE ) {
	#
	#		if ( $self->GetPreview() ) {
	#			$self->AsyncProcessSelCreatorModel();
	#		}
	#
	#	}

	print STDERR "Selection changed part id: $partId, creator key: $creatorKey\n";

}

# Handler which catch change of selected creatores settings in other parts
# Event is raised alwazs after AsyncCreatorProcess if specific part has active Preview
sub OnOtherPartCreatorSettChangedHndl {
	my $self            = shift;
	my $partId          = shift;
	my $creatorKey      = shift;
	my $creatorSettings = shift;    # creator model

	my $currCreatorKey = $self->{"model"}->GetSelectedCreator();

	if ( $partId eq Enums->Part_PNLSIZE ) {

		if ( $self->GetPreview() ) {

			if ( $creatorKey ne PnlCreEnums->SizePnlCreator_MATRIX ) {

				$self->AsyncProcessSelCreatorModel();

			}
		}

	}

	# Update creator Step Preview according Creator Size Preview
	if ( $partId eq Enums->Part_PNLSIZE && $creatorKey eq PnlCreEnums->SizePnlCreator_PREVIEW ) {

		# Update creator
		my $model = $self->{"model"}->GetCreatorModelByKey( PnlCreEnums->StepPnlCreator_PREVIEW );

		$model->SetSrcJobId( $creatorSettings->GetSrcJobId() );
		$model->SetPanelJSON( $creatorSettings->GetPanelJSON() );

		$self->{"form"}->SetCreators( [$model] );

	}

	print STDERR "Setting changed part id: $partId, creator key: $creatorKey\n";

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
