
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
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Model::StepPartModel'   => 'PartModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::StepPartFrm'      => 'PartFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Control::StepPartCheck' => 'PartCheckClass';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::Helper'                        => "CreatorHelper";
use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlToJSON';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::Helper' => "PnlCreHelper";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new( Enums->Part_PNLSTEPS, @_ );
	bless $self;

	# PROPERTIES

	my @editSteps = PnlCreHelper->GetEditSteps( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"isCustomerSet"} = scalar(@editSteps) > 1 ? 1 : 0;

	$self->{"model"}      = PartModel->new();         # Data model for view
	$self->{"checkClassName"} = ref(PartCheckClass->new());
	

	# handle events
	$self->{"asyncCreatorProcessedEvt"}->Add( sub { $self->__UpdatePartStepInfo(@_) } );

	$self->__SetActiveCreators();

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

	my $result = 0; # succes / failure od manual step placement

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

	# If panel is laready adjusted, only show InCAM
	if ( $creatorModel->GetManualPlacementStatus() eq EnumsGeneral->ResultType_OK ) {

		my $step = $creatorModel->GetStep();

		$inCAM->COM( "set_subsystem", "name" => "Panel-Design" );
		CamHelper->SetStep( $inCAM, $step );

		# Hide form
		$self->{"showPnlWizardFrmEvt"}->Do(0);
		while (1) {

			$inCAM->PAUSE("Edit panel and continue.");

			my @steps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step );

			if ( scalar(@steps) == 0 ) {

				my $messMngr = $self->{"partWrapper"}->GetMessMngr();
				my @mess     = ();
				push( @mess, "There is no nested step in panel. Do you want continue?\n" );

				$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, [ "No, I will correct panel", "Yes, it is OK" ] );

				if ( $messMngr->Result() == 1 ) {
					last;
				}
			}
			else {

				last;
			}

		}

		# Show form

		my $pnlToJSON = PnlToJSON->new( $inCAM, $jobId, $step );

		my $errMessJSON = "";

		if ( $pnlToJSON->CheckBeforeParse( \$errMessJSON ) ) {

			my $JSON = $pnlToJSON->ParsePnlToJSON( 1, 1, 0, 0 );

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

		$self->{"showPnlWizardFrmEvt"}->Do(1);

	}
	else {

		$creatorModel->SetManualPlacementJSON(undef);
		$creatorModel->SetManualPlacementStatus( EnumsGeneral->ResultType_NA );

		my $creator = CreatorHelper->GetPnlCreatorByKey( $self->{"jobId"}, $self->{"pnlType"}, $creatorKey );

		$creator->ImportSettings( $creatorModel->ExportCreatorSettings() );

		my $errMess = "";
		

		if ( $creator->Check( $inCAM, \$errMess ) ) {

			my $step = $creatorModel->GetStep();

			# Remove steps
			if (    $creatorKey eq PnlCreEnums->StepPnlCreator_CLASSUSER
				 || $creatorKey eq PnlCreEnums->StepPnlCreator_CLASSHEG )
			{

				foreach my $s ( CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step ) ) {
					CamStepRepeat->DeleteStepAndRepeat( $inCAM, $jobId, $step, $s->{"stepName"} );
				}
			}

			$inCAM->COM( "set_subsystem", "name" => "Panel-Design" );
			CamHelper->SetStep( $inCAM, $step );

			# Hide form
			$self->{"showPnlWizardFrmEvt"}->Do(0);

			while (1) {

				$inCAM->PAUSE($pauseText);

				my @steps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step );

				if ( scalar(@steps) == 0 ) {

					my $messMngr = $self->{"partWrapper"}->GetMessMngr();
					my @mess     = ();
					push( @mess, "There is no nested step in panel. Do you want continue?\n" );

					$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess, [ "No, I will correct panel", "Yes, it is OK" ] );

					if ( $messMngr->Result() == 1 ) {
						last;
					}
				}
				else {

					last;
				}

			}

			$self->{"showPnlWizardFrmEvt"}->Do(1);

			# Show form

			my $pnlToJSON = PnlToJSON->new( $inCAM, $jobId, $step );

			my $errMessJSON = "";

			if ( $pnlToJSON->CheckBeforeParse( \$errMessJSON ) ) {

				my $JSON = $pnlToJSON->ParsePnlToJSON( 1, 1, 0, 0 );

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
	}

	$creatorModel->SetManualPlacementStatus( EnumsGeneral->ResultType_FAIL ) unless ($result);

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
# Reise imidiatelly after slection change, do not wait on asznchrounous task
sub OnOtherPartCreatorSelChangedHndl {
	my $self       = shift;
	my $partId     = shift;
	my $creatorKey = shift;

	$self->EnableCreators( $partId, $creatorKey );

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
#  Private method
#-------------------------------------------------------------------------------------------#

# Disable creators which are not needed for specific panelisation type
sub __SetActiveCreators {
	my $self = shift;

	my @currCreators   = @{ $self->GetModel(1)->GetCreators() };
	my @activeCreators = ();

	if ( $self->_GetPnlType() eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		foreach my $c (@currCreators) {

			if ( !$self->{"isCustomerSet"} ) {
				push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->StepPnlCreator_CLASSUSER );
				push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->StepPnlCreator_CLASSHEG );
				push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->StepPnlCreator_MATRIX );
				push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->StepPnlCreator_PREVIEW );
			}
			else {
				# Activate if there is more than one "edit step";
				push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->StepPnlCreator_SET );
			}

		}

	}
	elsif ( $self->_GetPnlType() eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {
		foreach my $c (@currCreators) {

			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->StepPnlCreator_CLASSUSER );
			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->StepPnlCreator_CLASSHEG );

		}
	}

	$self->GetModel(1)->SetCreators( \@activeCreators );

}

sub EnableCreators {
	my $self       = shift;
	my $partId     = shift;    # Previous part
	my $creatorKey = shift;    # Selected creator from previous part
	my $setDefault = shift // 1; # set default creator

	# Disable specific creators depand on preview part (size creator)
	if ( $partId eq Enums->Part_PNLSIZE ) {

		my @enableCreators  = ();
		my $selectedCreator = undef;

		if ( $self->_GetPnlType() eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

			if ( $creatorKey eq PnlCreEnums->SizePnlCreator_USER ) {

				push( @enableCreators, PnlCreEnums->StepPnlCreator_CLASSUSER );
				push( @enableCreators, PnlCreEnums->StepPnlCreator_CLASSHEG );
				push( @enableCreators, PnlCreEnums->StepPnlCreator_SET );

				if ( $self->{"isCustomerSet"} ) {
					$selectedCreator = PnlCreEnums->StepPnlCreator_SET;
				}
				else {
					$selectedCreator = PnlCreEnums->StepPnlCreator_CLASSUSER;
				}

			}
			elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_HEG ) {

				push( @enableCreators, PnlCreEnums->StepPnlCreator_CLASSUSER );
				push( @enableCreators, PnlCreEnums->StepPnlCreator_CLASSHEG );
				push( @enableCreators, PnlCreEnums->StepPnlCreator_SET );

				if ( $self->{"isCustomerSet"} ) {
					$selectedCreator = PnlCreEnums->StepPnlCreator_SET;
				}
				else {
					$selectedCreator = PnlCreEnums->StepPnlCreator_CLASSHEG;
				}

			}
			elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_MATRIX ) {

				push( @enableCreators, PnlCreEnums->StepPnlCreator_MATRIX );

				$selectedCreator = PnlCreEnums->StepPnlCreator_MATRIX;

			}
			elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSUSER ) {

				push( @enableCreators, PnlCreEnums->StepPnlCreator_CLASSUSER );
				push( @enableCreators, PnlCreEnums->StepPnlCreator_SET );

				if ( $self->{"isCustomerSet"} ) {
					$selectedCreator = PnlCreEnums->StepPnlCreator_SET;
				}
				else {
					$selectedCreator = PnlCreEnums->StepPnlCreator_CLASSUSER;
				}
			}
			elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSHEG ) {

				push( @enableCreators, PnlCreEnums->StepPnlCreator_CLASSUSER );
				push( @enableCreators, PnlCreEnums->StepPnlCreator_CLASSHEG );
				push( @enableCreators, PnlCreEnums->StepPnlCreator_SET );

				if ( $self->{"isCustomerSet"} ) {
					$selectedCreator = PnlCreEnums->StepPnlCreator_SET;
				}
				else {
					$selectedCreator = PnlCreEnums->StepPnlCreator_CLASSHEG;
				}

			}
			elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_PREVIEW ) {

				push( @enableCreators, PnlCreEnums->StepPnlCreator_PREVIEW );

				$selectedCreator = PnlCreEnums->StepPnlCreator_PREVIEW;
			}

		}
		elsif ( $self->_GetPnlType() eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

			if ( $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSUSER ) {

				push( @enableCreators, PnlCreEnums->StepPnlCreator_CLASSUSER );
				push( @enableCreators, PnlCreEnums->StepPnlCreator_CLASSHEG );

				$selectedCreator = PnlCreEnums->StepPnlCreator_CLASSUSER;

			}
			elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSHEG ) {

				push( @enableCreators, PnlCreEnums->StepPnlCreator_CLASSUSER );
				push( @enableCreators, PnlCreEnums->StepPnlCreator_CLASSHEG );

				$selectedCreator = PnlCreEnums->StepPnlCreator_CLASSHEG;
			}
		}

		# Select creator
		$self->{"form"}->SetSelectedCreator($selectedCreator) if($setDefault);

		# Enable/diasble step cretors
		$self->{"form"}->EnableCreators( \@enableCreators );

	}
}

sub __UpdatePartStepInfo {
	my $self       = shift;
	my $creatorKey = shift;
	my $result     = shift;
	my $errMess    = shift;
	my $resultData = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( $self->GetPreview() ) {

		my $total       = "NA";
		my $utilisation = undef;
		if ($result) {

			# Total step cnt - mandatory
			if ( !defined $resultData->{"totalStepCnt"} || $resultData->{"totalStepCnt"} eq "" ) {
				die "Result data from CreatorProcess event has not defined key: totalStepCnt";
			}
			else {
				$total = $resultData->{"totalStepCnt"};
			}

			$self->{"partWrapper"}->SetPreviewInfoTextRow1("Step cnt: $total");

			# Panelise utilisation - optional
			if ( defined $resultData->{"utilization"} && $resultData->{"utilization"} ne "" ) {
				$utilisation = "Util.: " . int( $resultData->{"utilization"} ) . "%";
			}

			$self->{"partWrapper"}->SetPreviewInfoTextRow2($utilisation);

		}
		else {
			$self->{"partWrapper"}->SetPreviewInfoTextRow1(undef);
			$self->{"partWrapper"}->SetPreviewInfoTextRow2(undef);
		}

	}
	else {

		$self->{"partWrapper"}->SetPreviewInfoTextRow1(undef);
		$self->{"partWrapper"}->SetPreviewInfoTextRow2(undef);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
