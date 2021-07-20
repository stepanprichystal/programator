#-------------------------------------------------------------------------------------------#
# Description: Parse panelised panel bz user and retur SR repeats in JSON
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::ManualPlacement;
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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class          = shift;
	my $parent         = shift;
	my $jobId          = shift;
	my $step           = shift;
	my $actionBtnTitle = shift;
	my $pauseMessText  = shift;
	my $showClearBtn   = shift // 1;
	my $clearBtnTitle  = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	# PROPERTIES
	 
	$self->{"jobId"}        = $jobId;
	$self->{"step"}         = $step;
	$self->{"pauseMessage"} = $pauseMessText;
	$self->{"JSON"}         = undef;

	# EVENTS

	$self->{"placementEvt"}      = Event->new();    # Raise after click on button, before pause incam
	$self->{"clearPlacementEvt"} = Event->new();    # Raise after click on clear btn

	$self->__SetLayout( $actionBtnTitle, $showClearBtn, $clearBtnTitle );

	return $self;
}

sub SetManualPlacementJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"JSON"} = $val;

}

sub GetManualPlacementJSON {
	my $self = shift;

	return $self->{"JSON"};

}

sub SetManualPlacementStatus {
	my $self = shift;
	my $val  = shift;

	$self->{"indicator"}->SetStatus($val);

	$self->__BtnRefresh();

}

sub GetManualPlacementStatus {
	my $self = shift;

	return $self->{"indicator"}->GetStatus();
}

sub __SetLayout {
	my $self           = shift;
	my $actionBtnTitle = shift;
	my $showClearBtn   = shift;
	my $clearBtnTitle  = shift;

	#define panels

	# DEFINE CONTROLS
 
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $btn       = Wx::Button->new( $self, -1, $actionBtnTitle, &Wx::wxDefaultPosition, [ 5, 24 ] );
	my $btnStorno = Wx::Button->new( $self, -1, $clearBtnTitle,  &Wx::wxDefaultPosition, [ 5, 24 ] );
	
	
	my $indicator = ResultIndicator->new( $self, 20 );
	
	$self->SetBackgroundColour( Wx::Colour->new( 255, 220, 0 ) );   

	$btnStorno->Hide() unless ($showClearBtn);

	# SET EVENTS

	Wx::Event::EVT_BUTTON( $btn,       -1, sub { $self->__BtnClick() } );
	Wx::Event::EVT_BUTTON( $btnStorno, -1, sub { $self->__BtnStornoClick() } );

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $btn,       55, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( $indicator, 15, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szMain->Add( $btnStorno, 30, &Wx::wxEXPAND | &Wx::wxALL, 2);

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"indicator"} = $indicator;
	$self->{"actionBtn"} = $btn;
	$self->{"clearBtn"}  = $btnStorno;
}

sub __BtnClick {
	my $self = shift;

	$self->{"placementEvt"}->Do( $self->{"pauseMessage"} );

}

sub __BtnStornoClick {
	my $self = shift;

	$self->{"JSON"} = undef;

	$self->{"indicator"}->SetStatus( EnumsGeneral->ResultType_NA );
	
	$self->__BtnRefresh();

	$self->{"clearPlacementEvt"}->Do();
}

sub __BtnRefresh {
	my $self = shift;

	if ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_NA ) {

		$self->{"actionBtn"}->Enable();
		$self->{"clearBtn"}->Disable();

	}
	elsif ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_OK ) {

		$self->{"actionBtn"}->Disable();
		$self->{"clearBtn"}->Enable();

	}
	elsif ( $self->GetManualPlacementStatus() eq EnumsGeneral->ResultType_FAIL ) {

		$self->{"actionBtn"}->Enable();
		$self->{"clearBtn"}->Disable();

	}

}

1;
