#-------------------------------------------------------------------------------------------#
# Description: GUI of stencil creator
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::PopupChecker::PopupCheckerFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
use aliased 'Widgets::Forms::ErrorIndicator::ErrorIndicator';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class         = shift;
	my $parent        = shift;
	my $jobId         = shift;
	my $frmTitle      = shift // "No title";
	my $forceBtnTitle = shift // "Force";
	my $stopBtn       = shift // 1;

	my @dimension = ( 370, 200 );

	my $flags = &Wx::wxSTAY_ON_TOP | &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxMINIMIZE_BOX | &Wx::wxMAXIMIZE_BOX | &Wx::wxCLOSE_BOX;

	my $self = $class->SUPER::new( $parent, $frmTitle, \@dimension, $flags );

	bless($self);

	# Properties

	# Set layout
	$self->__SetLayout( $forceBtnTitle, $stopBtn );

	# Events
	$self->{"warnIndClickEvent"} = Event->new();
	$self->{"errIndClickEvent"}  = Event->new();

	$self->{"stopClickEvt"}   = Event->new();
	$self->{"forceClickEvt"}  = Event->new();
	$self->{"cancelClickEvt"} = Event->new();

	return $self;
}

sub SetErrIndicator {
	my $self = shift;
	my $cnt  = shift;

		$self->{"errInd"}->SetErrorCnt($cnt);
	
}

sub SetWarnIndicator {
	my $self = shift;
	my $cnt  = shift;

		$self->{"warnInd"}->SetErrorCnt($cnt);
	
}

sub SetStatusText {
	my $self  = shift;
	my $value = shift;
	my $dots  = shift // 0;

	my $txt = $value;
	$value .= "..." if($dots);

	$self->{"statusTxt"}->SetLabel( $txt);

}

sub SetGaugeProgress {
	my $self  = shift;
	my $value = shift;

	$self->{"gauge"}->SetValue($value);

}

#sub HideGauge {
#	my $self = shift;
#	my $cnt  = shift;
#
#	$self->{"gauge"}->Hide();
#
#}

sub EnableStopBtn {
	my $self   = shift;
	my $enable = shift;

	if ($enable) {
		$self->{"btnStop"}->Enable();

	}
	else {
		$self->{"btnStop"}->Disable();

	}
}

sub EnableForceBtn {
	my $self   = shift;
	my $enable = shift;

	if ($enable) {
		$self->{"btnForce"}->Enable();

	}
	else {
		$self->{"btnForce"}->Disable();

	}
}

sub EnableCancelBtn {
	my $self   = shift;
	my $enable = shift;

	if ($enable) {
		$self->{"btnCancel"}->Enable();

	}
	else {
		$self->{"btnCancel"}->Disable();

	}

}

#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self          = shift;
	my $forceBtnTitle = shift;
	my $stopBtn       = shift;

	# DEFINE SIZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szStatus = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $classTxt    = Wx::StaticText->new( $self->{"mainFrm"}, -1, "Checking: ", &Wx::wxDefaultPosition );
	my $classValTxt = Wx::StaticText->new( $self->{"mainFrm"}, -1, "",           &Wx::wxDefaultPosition );

	my $check = $self->__SetLayoutChecks( $self->{"mainFrm"} );

	# BUILD LAYOUT

	$szStatus->Add( $classTxt, 0, &Wx::wxEXPAND );
	$szStatus->Add( $classValTxt, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 4 );

	$szMain->Add( $szStatus, 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szMain->Add( $check, 1, &Wx::wxEXPAND );

	$self->AddContent($szMain);

	$self->SetButtonHeight(25);

	my $btnStop   = $self->AddButton( "Stop checking", sub { $self->{"stopClickEvt"}->Do(@_) } );
	my $btnForce  = $self->AddButton( $forceBtnTitle,  sub { $self->{"forceClickEvt"}->Do(@_) } );
	my $btnCancel = $self->AddButton( "Close",         sub { $self->{"cancelClickEvt"}->Do(@_) } );

	$btnStop->Enable();
	$btnForce->Disable();
	$btnCancel->Disable();

	if ( !$stopBtn ) {
		$btnStop->Hide();
	}

	# EVENTS

	# when click on WINDOWS close button (), behaviour like click on close button in status bar
	$self->{"mainFrm"}->{'onClose'}->Add( sub { $self->{"cancelClickEvt"}->Do(@_) } );

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES
	$self->{"btnStop"}   = $btnStop;
	$self->{"btnForce"}  = $btnForce;
	$self->{"btnCancel"} = $btnCancel;
	$self->{"statusTxt"} = $classValTxt;

}

sub __SetLayoutChecks {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, '' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $warnTxt = Wx::StaticText->new( $statBox, -1, "Warnings:", &Wx::wxDefaultPosition, [ 150, -1 ] );

	my $warnInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_WARNING, 20, undef, $self->{"jobId"} );

	my $errTxt = Wx::StaticText->new( $statBox, -1, "Errors:", &Wx::wxDefaultPosition, [ 150, -1 ] );

	my $errInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_ERROR, 20, undef, $self->{"jobId"} );

	#my $progressTxt = Wx::StaticText->new( $statBox, -1, "0%", &Wx::wxDefaultPosition, [ 30, 30 ] );

	my $gauge = Wx::Gauge->new( $statBox, -1, 100, [ -1, -1 ], [ -1, 15 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(0);

	$warnInd->{"onClick"}->Add( sub { $self->{"warnIndClickEvent"}->Do(@_) } );
	$errInd->{"onClick"}->Add( sub  { $self->{"errIndClickEvent"}->Do(@_) } );

	$szRow1->Add( $warnTxt, 0, &Wx::wxEXPAND );
	$szRow1->Add( $warnInd, 0, &Wx::wxEXPAND );

	$szRow2->Add( $errTxt, 0, &Wx::wxEXPAND );
	$szRow2->Add( $errInd, 0, &Wx::wxEXPAND );

	$szRow3->Add( $gauge, 1, );

	$szStatBox->Add( 10, 10 );
	$szStatBox->Add( $szRow1, 0,  &Wx::wxEXPAND | &Wx::wxLEFT | &Wx::wxTOP,  5 );
	$szStatBox->Add( $szRow2, 0,  &Wx::wxEXPAND | &Wx::wxLEFT | &Wx::wxTOP,, 5 );
	$szStatBox->Add( 10,      10, 1,                                         &Wx::wxEXPAND );
	$szStatBox->Add( $szRow3, 0,  &Wx::wxEXPAND | &Wx::wxALL,                5 );

	# SAVE REFERENCES
	$self->{"warnInd"} = $warnInd;
	$self->{"errInd"}  = $errInd;
	$self->{"gauge"}   = $gauge;

	return $szStatBox;
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Programs::Stencil::StencilCreator::Forms::StencilPopupFrm';
	#
	#	my $form = StencilPopupFrm->new();
	#	$form->{"mainFrm"}->Show();
	#	$form->MainLoop();

}

1;

