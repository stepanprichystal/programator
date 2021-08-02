
#-------------------------------------------------------------------------------------------#
# Description: Controler for creating profile size
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SizePart::Control::SizePart;
use base 'Programs::Panelisation::PnlWizard::Parts::PartBase';

use Class::Interface;
&implements('Programs::Panelisation::PnlWizard::Parts::IPart');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Model::SizePartModel'   => 'PartModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::SizePartFrm'      => 'PartFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Control::SizePartCheck' => 'PartCheckClass';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::Helper'                        => "PnlCreHelper";
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new( Enums->Part_PNLSIZE, @_ );
	bless $self;

	# PROPERTIES

	$self->{"model"}      = PartModel->new();         # Data model for view
	$self->{"checkClass"} = PartCheckClass->new();    # Checking model before panelisation

	my @editSteps = PnlCreHelper->GetEditSteps( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"isCustomerSet"} = scalar(@editSteps) > 1 ? 1 : 0;
	$self->{"ISDimInfo"} = HegMethods->GetInfoDimensions( $self->{"jobId"} );

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

		my $defCreator = @{ $self->{"model"}->GetCreators() }[0]->GetModelKey();

		if ( $self->_GetPnlType() eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

			# Select creator

			# If HEG is set, select HEG creators
			if (    defined $self->{"ISDimInfo"}->{"panel_x"}
				 && defined $self->{"ISDimInfo"}->{"panel_x"} > 0
				 && defined $self->{"ISDimInfo"}->{"panel_y"}
				 && defined $self->{"ISDimInfo"}->{"panel_y"} > 0
				 && defined $self->{"ISDimInfo"}->{"nasobnost_panelu"}
				 && defined $self->{"ISDimInfo"}->{"nasobnost_panelu"} > 0 )
			{

				if ( $self->{"isCustomerSet"} ) {
					$defCreator = PnlCreEnums->SizePnlCreator_HEG;
				}
				else {
					$defCreator = PnlCreEnums->SizePnlCreator_CLASSHEG;
				}
			}

		}
		elsif ( $self->_GetPnlType() eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

			# Select creator

			# If HEG is set, select HEG creators
			if (    defined $self->{"ISDimInfo"}->{"rozmer_x"}
				 && defined $self->{"ISDimInfo"}->{"rozmer_x"} > 0
				 && defined $self->{"ISDimInfo"}->{"rozmer_y"}
				 && defined $self->{"ISDimInfo"}->{"rozmer_y"} > 0
				 && defined $self->{"ISDimInfo"}->{"nasobnost"}
				 && defined $self->{"ISDimInfo"}->{"nasobnost"} > 0 )
			{

				$defCreator = PnlCreEnums->SizePnlCreator_CLASSHEG;
			}

		}

		$self->{"model"}->SetSelectedCreator($defCreator);
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
sub OnOtherPartCreatorSettChangedHndl {
	my $self        = shift;
	my $partId      = shift;
	my $creatorKey  = shift;
	my $creatorSett = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( $partId eq Enums->Part_PNLSTEPS ) {

		if ( $creatorKey eq PnlCreEnums->StepPnlCreator_MATRIX ) {

			my $spaceX   = $creatorSett->GetStepSpaceX();
			my $spaceY   = $creatorSett->GetStepSpaceY();
			my $rotation = $creatorSett->GetStepRotation();
			my $multiplX = $creatorSett->GetStepMultiplX();
			my $multiplY = $creatorSett->GetStepMultiplY();

			# recompute width and height of panel
			my %profLim   = CamJob->GetProfileLimits2( $inCAM, $jobId, $creatorSett->GetPCBStep() );
			my $nestStepW = abs( $profLim{"xMax"} - $profLim{"xMin"} );
			my $nestStepH = abs( $profLim{"yMax"} - $profLim{"yMin"} );

			my $areaW = $multiplX * ( ( $rotation / 90 ) % 2 == 0 ? $nestStepW : $nestStepH ) + ( $multiplX - 1 ) * $spaceX;
			my $areaH = $multiplY * ( ( $rotation / 90 ) % 2 == 0 ? $nestStepH : $nestStepW ) + ( $multiplY - 1 ) * $spaceY;

			if ( $areaW > 0 && $areaH > 0 ) {

				# Update creator form
				my $creatorFrm = $self->{"form"}->GetCreatorFrm( PnlCreEnums->SizePnlCreator_MATRIX );

				$creatorFrm->UpdateActiveArea( $areaW, $areaH );

				$creatorFrm->ActiveAreaChanged();

			}

		}

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

			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->SizePnlCreator_USER );
			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->SizePnlCreator_HEG );
			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->SizePnlCreator_MATRIX && !$self->{"isCustomerSet"} );
			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->SizePnlCreator_CLASSUSER );
			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->SizePnlCreator_CLASSHEG );
			push( @activeCreators, $c )
			  if (    $c->GetModelKey() eq PnlCreEnums->SizePnlCreator_PREVIEW
				   && !$self->{"isCustomerSet"}
				   && !JobHelper->GetJobIsOffer( $self->{"jobId"} ) );

		}

	}
	elsif ( $self->_GetPnlType() eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {
		foreach my $c (@currCreators) {

			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->SizePnlCreator_CLASSUSER );
			push( @activeCreators, $c ) if ( $c->GetModelKey() eq PnlCreEnums->SizePnlCreator_CLASSHEG );

		}
	}

	$self->GetModel(1)->SetCreators( \@activeCreators );

}

sub EnableCreators {
	my $self       = shift;
	my $partId     = shift;    # Previous part
	my $creatorKey = shift;    # Selected creator from previous part

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

