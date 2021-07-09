
#-------------------------------------------------------------------------------------------#
# Description: Part view, contain list of creators
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::CpnPart::View::CpnPartFrm;
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
use aliased 'Programs::Panelisation::PnlWizard::Parts::CpnPart::View::Creators::SemiautoFrm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $model  = shift;    # model for initial inittialization

	my $self = $class->SUPER::new( $parent, $inCAM, $jobId, $model );

	bless($self);

	$self->__SetLayout();

	# PROPERTIES

	# DEFINE EVENTS

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

	my $content = undef;

	if ( $creatorKey eq PnlCreEnums->CpnPnlCreator_SEMIAUTO ) {

		$content = SemiautoFrm->new($parent);
	}

	return $content;
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

			if ( $modelKey eq PnlCreEnums->CpnPnlCreator_SEMIAUTO ) {

				# Base property

				$creatorFrm->SetImpCpnRequired( $model->GetImpCpnRequired() );
				$creatorFrm->SetImpCpnSett( $model->GetImpCpnSett() );

				$creatorFrm->SetIPC3CpnRequired( $model->GetIPC3CpnRequired() );
				$creatorFrm->SetIPC3CpnSett( $model->GetIPC3CpnSett() );

				$creatorFrm->SetZAxisCpnRequired( $model->GetZAxisCpnRequired() );
				$creatorFrm->SetZAxisCpnSett( $model->GetZAxisCpnSett() );

				$creatorFrm->SetPlacementType( $model->GetPlacementType() );
				$creatorFrm->SetManualPlacementJSON( $model->GetManualPlacementJSON() );
				$creatorFrm->SetManualPlacementStatus( $model->GetManualPlacementStatus() );

			}

		}

	}

}

# override base class method
sub GetCreators {
	my $self       = shift;
	my $creatorKey = shift;

	my @models = ();

	foreach my $model ( @{ $self->{"creatorModels"} } ) {

		my $modelKey = $model->GetModelKey();

		next if ( defined $creatorKey && $creatorKey ne $modelKey );

		my $creatorFrm = $self->{"notebook"}->GetPage($modelKey)->GetPageContent();

		$model->SetStep( $creatorFrm->GetStep() );

		if ( $modelKey eq PnlCreEnums->CpnPnlCreator_SEMIAUTO ) {

			# Base property

			$model->SetImpCpnRequired( $creatorFrm->GetImpCpnRequired() );
			$model->SetImpCpnSett( $creatorFrm->GetImpCpnSett() );

			$model->SetIPC3CpnRequired( $creatorFrm->GetIPC3CpnRequired() );
			$model->SetIPC3CpnSett( $creatorFrm->GetIPC3CpnSett() );

			$model->SetZAxisCpnRequired( $creatorFrm->GetZAxisCpnRequired() );
			$model->SetZAxisCpnSett( $creatorFrm->GetZAxisCpnSett() );

			$model->SetPlacementType( $creatorFrm->GetPlacementType() );
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

