
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::StepPart::Control::StepPart;
use base 'Programs::Panelisation::PnlWizard::Parts::PartBase';

use Class::Interface;
&implements('Programs::Panelisation::PnlWizard::Parts::IPart');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Model::StepPartModel'   => 'PartModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::View::StepPartFrm'      => 'PartFrm';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Control::StepPartCheck' => 'PartCheckClass';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new( Enums->Part_PNLSTEPS, @_ );
	bless $self;

	# PROPERTIES

	$self->{"model"}      = PartModel->new();         # Data model for view
	$self->{"checkClass"} = PartCheckClass->new();    # Checking model before panelisation

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

	$self->{"form"}->{"manualPlacementEvt"}->Add( sub { $self->__OnManualPlacementHndl(@_) } );

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

sub __OnManualPlacementHndl {
	my $self = shift;

	unless ( $self->GetPreview() ) {

		return 0;
	}

	$self->{"inCAM"}->PAUSE("Upav panel");

	# Do check of user panelisation
	my $errMess = "";
	my $result  = 1;

	# 1) Check if step exist
	#	my $step = $self->{"model"}->GetStep();
	#
	#	my @steps = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $step );
	#
	#	if ( scalar(@steps) == 0 ) {
	#
	#		$errMess .=  "No nested step in panel";
	#		$result   = 0;
	#	}
	#
	#	if ( $result) {
	#
	#		# Prepare JSON
	#		my @steps = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $step );
	#		$self->{"indicator"}->SetStatus( EnumsGeneral->ResultType_OK );
	#	}
	#	else {
	#
	#		$self->{"indicator"}->SetStatus( EnumsGeneral->ResultType_FAIL );
	#		$result = 0;
	#	}

}

# Handler which catch change of creatores in other parts
# Creator settings changed riase in following situations:

sub OnOtherPartCreatorSelChangedHndl {
	my $self            = shift;
	my $partId          = shift;
	my $creatorKey      = shift;
	my $creatorSettings = shift;    # creator model

	#	# process creator if Part size was changed
	#	if ( $partId eq Enums->Part_PNLSIZE ) {
	#
	#		if ( $self->GetPreview() ) {
	#			$self->AsyncProcessSelCreatorModel();
	#		}
	#
	#	}

	print STDERR "Selection changed part id: $partId, creator key: $creatorKey\n";

}

# Handler which catch change of selected creatores settings in other parts
# Event is raised alwazs after AsyncCreatorProcess if specific part has active Preview
sub OnOtherPartCreatorSettChangedHndl {
	my $self       = shift;
	my $partId     = shift;
	my $creatorKey = shift;

	if ( $partId eq Enums->Part_PNLSIZE ) {

		if ( $self->GetPreview() ) {

			if ( $creatorKey ne PnlCreEnums->SizePnlCreator_MATRIX ) {

				$self->AsyncProcessSelCreatorModel();

			}
		}

	}

	print STDERR "Setting changed part id: $partId, creator key: $creatorKey\n";

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
