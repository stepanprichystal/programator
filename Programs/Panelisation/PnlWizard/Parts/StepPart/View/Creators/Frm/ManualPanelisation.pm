#-------------------------------------------------------------------------------------------#
# Description: Parse panelised panel bz user and retur SR repeats in JSON
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::ManualPanelisation;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;

use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class        = shift;
	my $parent       = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $step         = shift;
	my $btnTitle     = shift;
	my $pauseMessage = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	# PROPERTIES
	$self->{"inCAM"}        = $inCAM;
	$self->{"jobId"}        = $jobId;
	$self->{"step"}         = $step;
	$self->{"pauseMessage"} = $pauseMessage;
	$self->{"repeatsJSON"} = "";

	# EVENTS

	$self->{"prePanelisationEvt"}  = Event->new();    # Raise after click on button, before pause incam
	$self->{"postPanelisationEvt"} = Event->new();    # Return result after user finish panelisation

	$self->__SetLayout($btnTitle);

	return $self;
}

sub GetStepRepeatsJSON {

}

sub __SetLayout {
	my $self = shift;
	my $btnTitle = shift;

	#define panels

	# DEFINE CONTROLS

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $btn       = Wx::Button->new( $self, -1, $btnTitle, &Wx::wxDefaultPosition, [ -1, 24 ] );
	my $btnStorno = Wx::Button->new( $self, -1, "Clear",         &Wx::wxDefaultPosition, [ -1, 24 ] );
	my $indicator = ResultIndicator->new( $self, 20 );

	# SET EVENTS

	Wx::Event::EVT_BUTTON( $btn,       -1, sub { $self->__BtnClick() } );
	Wx::Event::EVT_BUTTON( $btnStorno, -1, sub { $self->__BtnStornoClick() } );

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $btn,       0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $indicator, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $btnStorno, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"indicator"} = $indicator;
}

sub __BtnClick {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $result = 1;

#	$self->{"prePanelisationEvt"}->Do();
# 
#	$self->{"postPanelisationEvt"}->Do( $result, $errMess );

}

sub __BtnStornoClick {
	my $self = shift;

	$self->{"repeatsJSON"} = "";

	$self->{"indicator"}->SetStatus( EnumsGeneral->ResultType_NA );
}

sub __Check {
	my $self    = shift;
	my $errMess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $result = 1;

	# 1) Check if step exist
	unless ( CamHelper->StepExists( $inCAM, $jobId, $step ) ) {

		$$errMess .= "Step: $step doesn't exist";
		$result   = 0;

		return $result;

	}

	my @steps = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $step );

	if ( scalar(@steps) == 0 ) {

		$$errMess .=  "No nested step in panel";
		$result   = 0;
	}

	return $result;
}

1;
