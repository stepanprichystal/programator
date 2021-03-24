
#-------------------------------------------------------------------------------------------#
# Description: Part view, contain list of creators
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
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::UserFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::HEGFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::MatrixFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::ClassUserFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::ClassHEGFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::PreviewFrm';

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

	if ( $creatorKey eq PnlCreEnums->SizePnlCreator_USER ) {

		$content = UserFrm->new($parent);
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_HEG ) {

		$content = HEGFrm->new($parent);
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_MATRIX ) {

		$content = MatrixFrm->new($parent);
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSUSER ) {

		$content = ClassUserFrm->new($parent);
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSHEG ) {

		$content = ClassHEGFrm->new($parent);
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_PREVIEW ) {

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

			if ( $modelKey eq PnlCreEnums->SizePnlCreator_USER || $modelKey eq PnlCreEnums->SizePnlCreator_HEG ) {

				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );
				$creatorFrm->SetBorderLeft( $model->GetBorderLeft() );
				$creatorFrm->SetBorderRight( $model->GetBorderRight() );
				$creatorFrm->SetBorderTop( $model->GetBorderTop() );
				$creatorFrm->SetBorderBot( $model->GetBorderBot() );
				$creatorFrm->SetStep( $model->GetStep() );

			}

			elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_MATRIX ) {
				die "Not impemented";
			}
			elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_CLASSUSER ) {

				# Specific for class
				$creatorFrm->SetPnlClasses( $model->GetPnlClasses() );
				$creatorFrm->SetDefPnlClass( $model->GetDefPnlClass() );
				$creatorFrm->SetDefPnlSize( $model->GetDefPnlSize() );
				$creatorFrm->SetDefPnlBorder( $model->GetDefPnlBorder() );

				# Base property
				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );
				$creatorFrm->SetBorderLeft( $model->GetBorderLeft() );
				$creatorFrm->SetBorderRight( $model->GetBorderRight() );
				$creatorFrm->SetBorderTop( $model->GetBorderTop() );
				$creatorFrm->SetBorderBot( $model->GetBorderBot() );
				$creatorFrm->SetStep( $model->GetStep() );

			}
			elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_CLASSHEG ) {
				die "Not impemented";
			}
			elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_PREVIEW ) {
				die "Not impemented";
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

		if ( $modelKey eq PnlCreEnums->SizePnlCreator_USER || $modelKey eq PnlCreEnums->SizePnlCreator_HEG ) {

			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );
			$model->SetBorderLeft( $creatorFrm->GetBorderLeft() );
			$model->SetBorderRight( $creatorFrm->GetBorderRight() );
			$model->SetBorderTop( $creatorFrm->GetBorderTop() );
			$model->SetBorderBot( $creatorFrm->GetBorderBot() );
			$model->SetStep( $creatorFrm->GetStep() );

		}

		elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_MATRIX ) {
			die "Not impemented";
		}
		elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_CLASSUSER ) {

			# Specific for class
			$model->SetPnlClasses( $creatorFrm->GetPnlClasses() );
			$model->SetDefPnlClass( $creatorFrm->GetDefPnlClass() );
			$model->SetDefPnlSize( $creatorFrm->GetDefPnlSize() );
			$model->SetDefPnlBorder( $creatorFrm->GetDefPnlBorder() );

			# Base property
			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );
			$model->SetBorderLeft( $creatorFrm->GetBorderLeft() );
			$model->SetBorderRight( $creatorFrm->GetBorderRight() );
			$model->SetBorderTop( $creatorFrm->GetBorderTop() );
			$model->SetBorderBot( $creatorFrm->GetBorderBot() );
			$model->SetStep( $creatorFrm->GetStep() );
		}
		elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_CLASSHEG ) {
			die "Not impemented";
		}
		elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_PREVIEW ) {
			die "Not impemented";
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

