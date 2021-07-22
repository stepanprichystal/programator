
#-------------------------------------------------------------------------------------------#
# Description: Controler for creating profile size
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SchemePart::Control::SchemePart;
use base 'Programs::Panelisation::PnlWizard::Parts::PartBase';

use Class::Interface;
&implements('Programs::Panelisation::PnlWizard::Parts::IPart');

#3th party library
use strict;
use warnings;
use List::Util qw[max min first];

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SchemePart::Model::SchemePartModel'   => 'PartModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SchemePart::View::SchemePartFrm'      => 'PartFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SchemePart::Control::SchemePartCheck' => 'PartCheckClass';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new( Enums->Part_PNLSCHEME, @_ );
	bless $self;

	# PROPERTIES

	$self->{"model"}      = PartModel->new();         # Data model for view
	$self->{"checkClass"} = PartCheckClass->new();    # Checking model before panelisation

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
	my $pnlType     = shift;

	my $parent = $partWrapper->GetParentForPart();

	$self->{"form"} = PartFrm->new( $parent, $inCAM, $self->{"jobId"}, $self->{"model"}, $pnlType );

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

# Handler which catch change of creatores in other parts
# Reise imidiatelly after slection change, do not wait on asznchrounous task
sub OnOtherPartCreatorSelChangedHndl {
	my $self       = shift;
	my $partId     = shift;
	my $creatorKey = shift;

	$self->__EnableCreators( $partId, $creatorKey );

	print STDERR "Selection changed part id: $partId, creator key: $creatorKey\n";

}

# Handler which catch change of selected creatores settings in other parts
sub OnOtherPartCreatorSettChangedHndl {
	my $self        = shift;
	my $partId      = shift;
	my $creatorKey  = shift;
	my $creatorSett = shift;

	my $currCreatorKey = $self->{"model"}->GetSelectedCreator();

	if ( $self->_GetPnlType() eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		# Try to set scheme by pabel border
		if ( $partId eq Enums->Part_PNLSIZE ) {

			if (
				   $creatorKey eq PnlCreEnums->SizePnlCreator_USER
				|| $creatorKey eq PnlCreEnums->SizePnlCreator_HEG
				|| $creatorKey eq PnlCreEnums->SizePnlCreator_MATRIX
				|| $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSUSER
				|| $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSHEG

			  )
			{

				my $TB = $creatorSett->GetBorderTop();
				my $BB = $creatorSett->GetBorderBot();
				my $LB = $creatorSett->GetBorderLeft();
				my $RB = $creatorSett->GetBorderRight();

				my $maxBorder = int(max( $TB, $BB, $LB, $RB ));

				my @schemas = ();
				my $model   = $self->{"model"}->GetCreatorModelByKey( $self->{"model"}->GetSelectedCreator() );

				if ( $model->GetSchemeType() eq "standard" ) {

					@schemas = @{ $model->GetStdSchemeList() };
				}
				elsif ( $model->GetSchemeType() eq "special" ) {

					@schemas = @{ $model->GetSpecSchemeList() };

				}

				# Filter if there is some schema with specific border
				my $scheme = first { $_ =~ /$maxBorder/ } @schemas;

				if ( defined $scheme ) {

					my $frm = $self->{"form"}->GetCreatorFrm( $self->{"model"}->GetSelectedCreator() );
					$frm->SetScheme($scheme);
				}

			}

		}

		if ( $partId eq Enums->Part_PNLSTEPS && $self->GetPreview() ) {

			$self->AsyncProcessSelCreatorModel();
		}
	}
	elsif ( $self->_GetPnlType() eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

		if ( $partId eq Enums->Part_PNLSTEPS && $self->GetPreview() ) {

			# if there is no coupon part, do process
			my @pnlStep =
			  map { $_->{"stepName"} } CamStepRepeat->GetUniqueStepAndRepeat( $self->{"inCAM"}, $self->{"jobId"}, $self->{"model"}->GetStep() );
			if ( scalar( grep { $_ =~ /coupon_/ } @pnlStep ) == 0 ) {

				$self->AsyncProcessSelCreatorModel();
			}
		}
		elsif ( $partId eq Enums->Part_PNLCPN && $self->GetPreview() ) {

			# if there is no coupon part, do process

			$self->AsyncProcessSelCreatorModel();
		}
	}
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

			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->SchemePnlCreator_LIBRARY );

		}

	}
	elsif ( $self->_GetPnlType() eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {
		foreach my $c (@currCreators) {

			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->SchemePnlCreator_LIBRARY );

		}
	}

	$self->GetModel(1)->SetCreators( \@activeCreators );

}

sub __EnableCreators {
	my $self       = shift;
	my $partId     = shift;
	my $creatorKey = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

