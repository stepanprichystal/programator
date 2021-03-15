
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
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::AutoHegFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::AutoUserFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::MatrixFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::SetFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::PreviewFrm';

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

	if ( $creatorKey eq PnlCreEnums->StepPnlCreator_AUTOHEG ) {

		$content = AutoHegFrm->new($parent);
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_AUTOUSER ) {

		$content = AutoUserFrm->new($parent);
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_MATRIX ) {

		$content = MatrixFrm->new($parent);
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_SET ) {

		$content = SetFrm->new($parent);
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_PREVIEW ) {

		$content = PreviewFrm->new($parent);
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

			print STDERR $model->GetWidth() . "\n";

			if ( $modelKey eq PnlCreEnums->StepPnlCreator_AUTOUSER ) {

				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );
				$creatorFrm->SetStep( $model->GetStep() );

			}
			elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_AUTOHEG ) {

				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );
				$creatorFrm->SetStep( $model->GetStep() );

			}
			elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_MATRIX ) {

			}
			elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_SET ) {

			}
			elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_PREVIEW ) {

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

		if ( $modelKey eq PnlCreEnums->StepPnlCreator_AUTOUSER ) {

			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );
			$model->SetStep( $creatorFrm->GetStep() );

		}
		elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_AUTOHEG ) {

			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );
			$model->SetStep( $creatorFrm->GetStep() );

		}
		elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_MATRIX ) {

		}
		elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_SET ) {

		}
		elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_PREVIEW ) {

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

