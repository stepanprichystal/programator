
#-------------------------------------------------------------------------------------------#
# Description: Part view, contain list of creators
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SchemePart::View::SchemePartFrm;
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
use aliased 'Programs::Panelisation::PnlWizard::Parts::SchemePart::View::Creators::LibraryFrm';

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

	my $frmHeight = 193; # height of part, constant for all creators
	 
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

	if ( $creatorKey eq PnlCreEnums->SchemePnlCreator_LIBRARY ) {

		$content = LibraryFrm->new( $parent, $inCAM, $jobId, $pnlType );
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

			if ( $modelKey eq PnlCreEnums->SchemePnlCreator_LIBRARY ) {

				$creatorFrm->SetStdSchemeList( $model->GetStdSchemeList() );
				$creatorFrm->SetSpecSchemeList( $model->GetSpecSchemeList() );
				$creatorFrm->SetSchemeType( $model->GetSchemeType() );
				$creatorFrm->SetScheme( $model->GetScheme() );
				$creatorFrm->SetSignalLayerSpecFill( $model->GetSignalLayerSpecFill() );

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

		if ( $modelKey eq PnlCreEnums->SchemePnlCreator_LIBRARY ) {

			$model->SetStdSchemeList( $creatorFrm->GetStdSchemeList() );
			$model->SetSpecSchemeList( $creatorFrm->GetSpecSchemeList() );
			$model->SetSchemeType( $creatorFrm->GetSchemeType() );
			$model->SetScheme( $creatorFrm->GetScheme() );
			$model->SetSignalLayerSpecFill( $creatorFrm->GetSignalLayerSpecFill() );

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

