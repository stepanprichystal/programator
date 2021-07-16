
#-------------------------------------------------------------------------------------------#
# Description: Part view, contain list of creators
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::StepPart::View::StepPartFrm;
use base qw(Programs::Panelisation::PnlWizard::Forms::CreactorSelectorFrm);

#3th party library
use strict;
use warnings;
use Wx;
use List::Util qw(first);

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::ClassHEGFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::ClassUserFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::MatrixFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::SetFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::PreviewFrm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $parent  = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $model   = shift;    # model for initial inittialization
	my $pnlType = shift;

	my $frmHeight = 280;                                                                      # height of part, constant for all creators
	my $self = $class->SUPER::new( $parent, $frmHeight, $inCAM, $jobId, $model, $pnlType );

	bless($self);

	$self->__SetLayout();

	# PROPERTIES

	# DEFINE EVENTS
	$self->{"manualPlacementEvt"} = Event->new();

	return $self;
}

# Custom layout settings
sub __SetLayout {
	my $self = shift;

	# Call base class
	$self->SUPER::_SetLayout();

	# Adjust base class layout

}

# Return proper creator view form
sub OnGetCreatorLayout {
	my $self       = shift;
	my $creatorKey = shift;
	my $parent     = shift;

	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};
	my $pnlType = $self->{"pnlType"};

	my $content = undef;

	if ( $creatorKey eq PnlCreEnums->StepPnlCreator_CLASSHEG ) {

		$content = ClassHEGFrm->new( $parent, $inCAM, $jobId );

		$content->{"manualPlacementEvt"}->Add( sub { $self->{"manualPlacementEvt"}->Do(@_) } );
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_CLASSUSER ) {

		$content = ClassUserFrm->new( $parent, $inCAM, $jobId );

		$content->{"manualPlacementEvt"}->Add( sub { $self->{"manualPlacementEvt"}->Do(@_) } );
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_MATRIX ) {

		$content = MatrixFrm->new( $parent, $inCAM, $jobId );
		
		$content->{"manualPlacementEvt"}->Add( sub { $self->{"manualPlacementEvt"}->Do(@_) } );
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_SET ) {

		$content = SetFrm->new( $parent, $inCAM, $jobId );
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_PREVIEW ) {

		$content = PreviewFrm->new( $parent, $inCAM, $jobId );

		$content->{"manualPlacementEvt"}->Add( sub { $self->{"manualPlacementEvt"}->Do(@_) } );
	}

	return $content;
}

sub OnCreatorProcessedHndl {
	my $self       = shift;
	my $partId     = shift;
	my $creatorKey = shift;

	if (    $creatorKey eq PnlCreEnums->StepPnlCreator_CLASSHEG
		 || $creatorKey eq PnlCreEnums->StepPnlCreator_CLASSUSER
		 || $creatorKey eq PnlCreEnums->StepPnlCreator_MATRIX )
	{

		$self->GetCreatorFrm($creatorKey)->DisplayCvrlpinLayer();
	}
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

# override base class method
sub SetCreators {
	my $self           = shift;
	my $creatorsModels = shift;

	foreach my $modelKey ( $self->{"creatorList"}->GetAllCreatorKeys() ) {

		# Filter model from passed param
		my $model = first { $_->GetModelKey() eq $modelKey } @{$creatorsModels};

		if ( defined $model ) {

			my $creatorFrm = $self->{"notebook"}->GetPage($modelKey)->GetPageContent();
			$creatorFrm->SetStep( $model->GetStep() );

			if (    $modelKey eq PnlCreEnums->StepPnlCreator_CLASSUSER
				 || $modelKey eq PnlCreEnums->StepPnlCreator_CLASSHEG )
			{

				$creatorFrm->SetPCBStepsList( $model->GetPCBStepsList() );
				$creatorFrm->SetPCBStep( $model->GetPCBStep() );
				$creatorFrm->SetPCBStepProfile( $model->GetPCBStepProfile() );
				$creatorFrm->SetPnlClasses( $model->GetPnlClasses() );
				$creatorFrm->SetDefPnlClass( $model->GetDefPnlClass() );
				$creatorFrm->SetDefPnlSpacing( $model->GetDefPnlSpacing() );
				$creatorFrm->SetPlacementType( $model->GetPlacementType() );
				$creatorFrm->SetRotationType( $model->GetRotationType() );
				$creatorFrm->SetPatternType( $model->GetPatternType() );
				$creatorFrm->SetInterlockType( $model->GetInterlockType() );
				$creatorFrm->SetSpaceX( $model->GetSpaceX() );
				$creatorFrm->SetSpaceY( $model->GetSpaceY() );
				$creatorFrm->SetAlignType( $model->GetAlignType() );
				$creatorFrm->SetAmountType( $model->GetAmountType() );
				$creatorFrm->SetExactQuantity( $model->GetExactQuantity() );
				$creatorFrm->SetMaxQuantity( $model->GetMaxQuantity() );
				$creatorFrm->SetActionType( $model->GetActionType() );
				$creatorFrm->SetManualPlacementJSON( $model->GetManualPlacementJSON() );
				$creatorFrm->SetManualPlacementStatus( $model->GetManualPlacementStatus() );
				$creatorFrm->SetMinUtilization( $model->GetMinUtilization() );
				$creatorFrm->SetExactQuantity( $model->GetExactQuantity() );

				if ( $modelKey eq PnlCreEnums->StepPnlCreator_CLASSHEG ) {

					$creatorFrm->SetISMultiplFilled( $model->GetISMultiplFilled() );
				}

			}
			elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_MATRIX ) {

				$creatorFrm->SetPCBStepsList( $model->GetPCBStepsList() );
				$creatorFrm->SetPCBStep( $model->GetPCBStep() );
				$creatorFrm->SetPCBStepProfile( $model->GetPCBStepProfile() );
				$creatorFrm->SetStepMultiplX( $model->GetStepMultiplX() );
				$creatorFrm->SetStepMultiplY( $model->GetStepMultiplY() );
				$creatorFrm->SetStepSpaceX( $model->GetStepSpaceX() );
				$creatorFrm->SetStepSpaceY( $model->GetStepSpaceY() );
				$creatorFrm->SetStepRotation( $model->GetStepRotation() );
				$creatorFrm->SetManualPlacementJSON( $model->GetManualPlacementJSON() );
				$creatorFrm->SetManualPlacementStatus( $model->GetManualPlacementStatus() );

			}
			elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_PREVIEW ) {

				$creatorFrm->SetSrcJobId( $model->GetSrcJobId() );
				$creatorFrm->SetManualPlacementJSON( $model->GetManualPlacementJSON() );
				$creatorFrm->SetManualPlacementStatus( $model->GetManualPlacementStatus() );

			}

		}
	}
}

sub GetCreators {
	my $self       = shift;
	my $creatorKey = shift;

	my @models = ();

	foreach my $model ( @{ $self->{"creatorModels"} } ) {

		my $modelKey = $model->GetModelKey();

		next if ( defined $creatorKey && $creatorKey ne $modelKey );

		my $creatorFrm = $self->{"notebook"}->GetPage($modelKey)->GetPageContent();

		$model->SetStep( $creatorFrm->GetStep() );

		if (    $modelKey eq PnlCreEnums->StepPnlCreator_CLASSUSER
			 || $modelKey eq PnlCreEnums->StepPnlCreator_CLASSHEG )
		{

			$model->SetPnlClasses( $creatorFrm->GetPnlClasses() );
			$model->SetDefPnlClass( $creatorFrm->GetDefPnlClass() );
			$model->SetDefPnlSpacing( $creatorFrm->GetDefPnlSpacing() );

			$model->SetPCBStepsList( $creatorFrm->GetPCBStepsList() );
			$model->SetPCBStep( $creatorFrm->GetPCBStep() );
			$model->SetPCBStepProfile( $creatorFrm->GetPCBStepProfile() );
			$model->SetPlacementType( $creatorFrm->GetPlacementType() );
			$model->SetRotationType( $creatorFrm->GetRotationType() );
			$model->SetPatternType( $creatorFrm->GetPatternType() );
			$model->SetInterlockType( $creatorFrm->GetInterlockType() );
			$model->SetSpaceX( $creatorFrm->GetSpaceX() );
			$model->SetSpaceY( $creatorFrm->GetSpaceY() );
			$model->SetAlignType( $creatorFrm->GetAlignType() );
			$model->SetAmountType( $creatorFrm->GetAmountType() );
			$model->SetExactQuantity( $creatorFrm->GetExactQuantity() );
			$model->SetMaxQuantity( $creatorFrm->GetMaxQuantity() );
			$model->SetActionType( $creatorFrm->GetActionType() );
			$model->SetManualPlacementJSON( $creatorFrm->GetManualPlacementJSON() );
			$model->SetManualPlacementStatus( $creatorFrm->GetManualPlacementStatus() );
			$model->SetMinUtilization( $creatorFrm->GetMinUtilization() );
			$model->SetExactQuantity( $creatorFrm->GetExactQuantity() );

			if ( $modelKey eq PnlCreEnums->StepPnlCreator_CLASSHEG ) {

				$model->SetISMultiplFilled( $creatorFrm->GetISMultiplFilled() );
			}

		}
		elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_CLASSHEG ) {

			#			$model->SetWidth( $creatorFrm->GetWidth() );
			#			$model->SetHeight( $creatorFrm->GetHeight() );
			#			$model->SetStep( $creatorFrm->GetStep() );

		}
		elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_MATRIX ) {

			$model->SetPCBStepsList( $creatorFrm->GetPCBStepsList() );
			$model->SetPCBStep( $creatorFrm->GetPCBStep() );
			$model->SetPCBStepProfile( $creatorFrm->GetPCBStepProfile() );
			$model->SetStepMultiplX( $creatorFrm->GetStepMultiplX() );
			$model->SetStepMultiplY( $creatorFrm->GetStepMultiplY() );
			$model->SetStepSpaceX( $creatorFrm->GetStepSpaceX() );
			$model->SetStepSpaceY( $creatorFrm->GetStepSpaceY() );
			$model->SetStepRotation( $creatorFrm->GetStepRotation() );
			$model->SetManualPlacementJSON( $creatorFrm->GetManualPlacementJSON() );
			$model->SetManualPlacementStatus( $creatorFrm->GetManualPlacementStatus() );

		}
		elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_SET ) {
			die "not implemented";

		}
		elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_PREVIEW ) {

			$model->SetSrcJobId( $creatorFrm->GetSrcJobId() );
			$model->SetPanelJSON( $creatorFrm->GetPanelJSON() );
			$model->SetManualPlacementJSON( $creatorFrm->GetManualPlacementJSON() );
			$model->SetManualPlacementStatus( $creatorFrm->GetManualPlacementStatus() );

		}

		push( @models, $model );

	}

	# return updated model
	return \@models;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

1;

