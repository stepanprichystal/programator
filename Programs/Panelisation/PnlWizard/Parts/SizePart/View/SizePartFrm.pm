
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SizePart::View::SizePartFrm;
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
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::UserDefinedFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::HEGOrderFrm';

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

	if ( $creatorKey eq PnlCreEnums->SizePnlCreator_USERDEFINED ) {

		$content = UserDefinedFrm->new($parent);

	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_HEGORDER ) {

		$content = HEGOrderFrm->new($parent);
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

			if ( $modelKey eq PnlCreEnums->SizePnlCreator_USERDEFINED ) {

				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );
				$creatorFrm->SetStep( $model->GetStep() );

			}
			elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_HEGORDER ) {

				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );
				$creatorFrm->SetStep( $model->GetStep() );

			}
		}

	}

}

# override base class method
sub GetCreators {
	my $self = shift;
	my $creatorKey = shift;

	my @models = ();

	foreach my $model ( @{ $self->{"creatorModels"} } ) {
		
		

		my $modelKey = $model->GetModelKey();
		
		next if(defined $creatorKey && $creatorKey ne $modelKey);

		my $creatorFrm = $self->{"notebook"}->GetPage($modelKey)->GetPageContent();

		if ( $modelKey eq PnlCreEnums->SizePnlCreator_USERDEFINED ) {

			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );
			$model->SetStep( $creatorFrm->GetStep() );

		}
		elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_HEGORDER ) {

			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );
			$model->SetStep( $creatorFrm->GetStep() );

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

