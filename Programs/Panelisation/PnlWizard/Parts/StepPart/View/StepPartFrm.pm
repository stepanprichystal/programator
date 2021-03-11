
#-------------------------------------------------------------------------------------------#
# Description:
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
use aliased 'Programs::Panelisation::PnlWizard::Forms::CreatorListFrm';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::UserDefinedFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::AutopartFrm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $model  = shift;    # model forfrist form inittialization

	my $self = $class->SUPER::new( $parent, $inCAM, $jobId, $model );

	bless($self);

	$self->__SetLayout();

	# PROPERTIES

	# DEFINE EVENTS

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# Call base class
	$self->SUPER::_SetLayout();

	# Adjust base class layout

}

sub OnGetCreatorLayout {
	my $self       = shift;
	my $creatorKey = shift;
	my $parent     = shift;

	my $content = undef;

	if ( $creatorKey eq PnlCreEnums->StepPnlCreator_USERDEFINED ) {

		$content = UserDefinedFrm->new($parent);

	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_AUTOPART ) {

		$content = AutopartFrm->new($parent);
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

			if ( $modelKey eq PnlCreEnums->StepPnlCreator_USERDEFINED ) {

				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );

			}
			elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_AUTOPART ) {

				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );

			}
		}

	}

}

# override base class method
sub GetCreators {
	my $self = shift;

	my @models = ();

	foreach my $model ( @{ $self->{"creatorModels"} } ) {

		my $modelKey = $model->GetModelKey();

		my $creatorFrm = $self->{"notebook"}->GetPage($modelKey)->GetPageContent();

		if ( $modelKey eq PnlCreEnums->StepPnlCreator_USERDEFINED ) {

			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );

		}
		elsif ( $modelKey eq PnlCreEnums->StepPnlCreator_AUTOPART ) {

			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );

		}

		push( @models, $model );

	}

	# return updated model
	return \@models;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

