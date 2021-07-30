
#-------------------------------------------------------------------------------------------#
# Description: Part view, contain list of creators
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SizePart::View::SizePartFrm;
use base qw(Programs::Panelisation::PnlWizard::Forms::CreactorSelectorFrm);

use Class::Interface;
&implements('Programs::Panelisation::PnlWizard::Parts::IPartForm');

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
	my $class   = shift;
	my $parent  = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $model   = shift;    # model for initial inittialization
	my $pnlType = shift;

	my $frmHeight = 240;                                                                      # height of part, constant for all creators
	my $self = $class->SUPER::new( $parent, $frmHeight, $inCAM, $jobId, $model, $pnlType );

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

	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};
	my $pnlType = $self->{"pnlType"};

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

			$creatorFrm->SetStep( $model->GetStep() );

			if ( $modelKey eq PnlCreEnums->SizePnlCreator_USER || $modelKey eq PnlCreEnums->SizePnlCreator_HEG ) {

				# Base property

				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );
				$creatorFrm->SetBorderLeft( $model->GetBorderLeft() );
				$creatorFrm->SetBorderRight( $model->GetBorderRight() );
				$creatorFrm->SetBorderTop( $model->GetBorderTop() );
				$creatorFrm->SetBorderBot( $model->GetBorderBot() );

				if ( $modelKey eq PnlCreEnums->SizePnlCreator_HEG ) {

					$creatorFrm->SetISDimensionFilled( $model->GetISDimensionFilled() );

				}

			}

			elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_MATRIX ) {

				# Base property

				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );
				$creatorFrm->SetBorderLeft( $model->GetBorderLeft() );
				$creatorFrm->SetBorderRight( $model->GetBorderRight() );
				$creatorFrm->SetBorderTop( $model->GetBorderTop() );
				$creatorFrm->SetBorderBot( $model->GetBorderBot() );

			}
			elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_CLASSUSER || $modelKey eq PnlCreEnums->SizePnlCreator_CLASSHEG ) {

				# Specific for class - set before base proerty, 
				# because set value to combobox affect some textbox with base propertu
				$creatorFrm->SetPnlClasses( $model->GetPnlClasses() );
				$creatorFrm->SetDefPnlClass( $model->GetDefPnlClass() );
				$creatorFrm->SetDefPnlSize( $model->GetDefPnlSize() );
				$creatorFrm->SetDefPnlBorder( $model->GetDefPnlBorder() );

				if ( $modelKey eq PnlCreEnums->SizePnlCreator_CLASSHEG ) {

					$creatorFrm->SetISDimensionFilled( $model->GetISDimensionFilled() );

				}

				# Base property

				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );
				$creatorFrm->SetBorderLeft( $model->GetBorderLeft() );
				$creatorFrm->SetBorderRight( $model->GetBorderRight() );
				$creatorFrm->SetBorderTop( $model->GetBorderTop() );
				$creatorFrm->SetBorderBot( $model->GetBorderBot() );

			}

			elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_PREVIEW ) {

				# Base property

				$creatorFrm->SetWidth( $model->GetWidth() );
				$creatorFrm->SetHeight( $model->GetHeight() );
				$creatorFrm->SetBorderLeft( $model->GetBorderLeft() );
				$creatorFrm->SetBorderRight( $model->GetBorderRight() );
				$creatorFrm->SetBorderTop( $model->GetBorderTop() );
				$creatorFrm->SetBorderBot( $model->GetBorderBot() );

				# Specific for class
				$creatorFrm->SetSrcJobId( $model->GetSrcJobId() );
				$creatorFrm->SetSrcJobByOffer( $model->GetSrcJobByOffer() );
				$creatorFrm->SetSrcJobListByName( $model->GetSrcJobListByName() );
				$creatorFrm->SetSrcJobListByNote( $model->GetSrcJobListByNote() );
				$creatorFrm->SetPanelJSON( $model->GetPanelJSON() );

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

		if ( $modelKey eq PnlCreEnums->SizePnlCreator_USER || $modelKey eq PnlCreEnums->SizePnlCreator_HEG ) {

			# Base property
			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );
			$model->SetBorderLeft( $creatorFrm->GetBorderLeft() );
			$model->SetBorderRight( $creatorFrm->GetBorderRight() );
			$model->SetBorderTop( $creatorFrm->GetBorderTop() );
			$model->SetBorderBot( $creatorFrm->GetBorderBot() );

			# Sepcific class property
			if ( $modelKey eq PnlCreEnums->SizePnlCreator_HEG ) {

				$model->SetISDimensionFilled( $creatorFrm->GetISDimensionFilled() );
			}

		}

		elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_MATRIX ) {

			# Base property

			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );
			$model->SetBorderLeft( $creatorFrm->GetBorderLeft() );
			$model->SetBorderRight( $creatorFrm->GetBorderRight() );
			$model->SetBorderTop( $creatorFrm->GetBorderTop() );
			$model->SetBorderBot( $creatorFrm->GetBorderBot() );

		}
		elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_CLASSUSER || $modelKey eq PnlCreEnums->SizePnlCreator_CLASSHEG ) {

			# Base property
			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );
			$model->SetBorderLeft( $creatorFrm->GetBorderLeft() );
			$model->SetBorderRight( $creatorFrm->GetBorderRight() );
			$model->SetBorderTop( $creatorFrm->GetBorderTop() );
			$model->SetBorderBot( $creatorFrm->GetBorderBot() );

			# Specific for class
			$model->SetPnlClasses( $creatorFrm->GetPnlClasses() );
			$model->SetDefPnlClass( $creatorFrm->GetDefPnlClass() );
			$model->SetDefPnlSize( $creatorFrm->GetDefPnlSize() );
			$model->SetDefPnlBorder( $creatorFrm->GetDefPnlBorder() );

			if ( $modelKey eq PnlCreEnums->SizePnlCreator_CLASSHEG ) {

				$model->SetISDimensionFilled( $creatorFrm->GetISDimensionFilled() );
			}

		}
		elsif ( $modelKey eq PnlCreEnums->SizePnlCreator_PREVIEW ) {

			# Base property
			$model->SetWidth( $creatorFrm->GetWidth() );
			$model->SetHeight( $creatorFrm->GetHeight() );
			$model->SetBorderLeft( $creatorFrm->GetBorderLeft() );
			$model->SetBorderRight( $creatorFrm->GetBorderRight() );
			$model->SetBorderTop( $creatorFrm->GetBorderTop() );
			$model->SetBorderBot( $creatorFrm->GetBorderBot() );

			# Specific for class
			$model->SetSrcJobId( $creatorFrm->GetSrcJobId() );
			$model->SetSrcJobByOffer( $creatorFrm->GetSrcJobByOffer() );
			$model->SetSrcJobListByName( $creatorFrm->GetSrcJobListByName() );
			$model->SetSrcJobListByNote( $creatorFrm->GetSrcJobListByNote() );
			$model->SetPanelJSON( $creatorFrm->GetPanelJSON() );

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

