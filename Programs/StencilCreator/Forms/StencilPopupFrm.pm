#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Forms::StencilPopupFrm;
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

	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my @dimension = ( 430, 200 );

	my $title = "Stencil creator ($jobId)";

	my $flags = &Wx::wxSTAY_ON_TOP | &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxMINIMIZE_BOX | &Wx::wxMAXIMIZE_BOX | &Wx::wxCLOSE_BOX;

	my $self = $class->SUPER::new( $parent, $title, \@dimension, $flags );

	bless($self);

	# Properties

	# Set layout
	$self->__SetLayout();

	# Events
	$self->{"warnIndClickEvent"} = Event->new();
	$self->{"errIndClickEvent"}  = Event->new();

	$self->{"outputForceClick"} = Event->new();
	$self->{"cancelClick"}      = Event->new();

	return $self;
}

sub SetErrIndicator {
	my $self = shift;
	my $cnt  = shift;

	if ($cnt) {

		$self->{"errInd"}->SetErrorCnt($cnt);
	}
}

sub SetWarnIndicator {
	my $self = shift;
	my $cnt  = shift;

	if ($cnt) {

		$self->{"warnInd"}->SetErrorCnt($cnt);
	}
}

sub HideGauge {
	my $self = shift;
	my $cnt  = shift;

	$self->{"gauge"}->Hide();

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
	my $self = shift;

	# DEFINE CONTROLS
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $check = $self->__SetLayoutChecks( $self->{"mainFrm"} );

	$szMain->Add( $check, 1, &Wx::wxEXPAND );

	$self->AddContent($szMain);

	$self->SetButtonHeight(20);

	my $btnForce  = $self->AddButton( "Output force", sub { $self->{"outputForceClick"}->Do(@_) } );
	my $btnCancel = $self->AddButton( "Close",        sub { $self->{"cancelClick"}->Do(@_) } );

	$btnForce->Disable();
	$btnCancel->Disable();

	# EVENTS

	# when click on WINDOWS close button (), behaviour like click on close button in status bar
	$self->{"mainFrm"}->{'onClose'}->Add( sub { $self->{"cancelClick"}->Do(@_) } );

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES

	$self->{"btnForce"}  = $btnForce;
	$self->{"btnCancel"} = $btnCancel;

}

sub __SetLayoutChecks {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Check before output' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#my $szRow5 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $warnTxt = Wx::StaticText->new( $statBox, -1, "Warnings", &Wx::wxDefaultPosition, [ 200, 30 ] );

	my $warnInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_WARNING, 20, undef, $self->{"jobId"} );

	my $errTxt = Wx::StaticText->new( $statBox, -1, "Errors:", &Wx::wxDefaultPosition, [ 200, 30 ] );

	my $errInd = ErrorIndicator->new( $statBox, EnumsGeneral->MessageType_ERROR, 20, undef, $self->{"jobId"} );

	#my $progressTxt = Wx::StaticText->new( $statBox, -1, "0%", &Wx::wxDefaultPosition, [ 30, 30 ] );

	my $gauge = Wx::Gauge->new( $statBox, -1, 100, [ -1, -1 ], [ -1, 5 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(100);
	$gauge->Pulse();

	$warnInd->{"onClick"}->Add( sub { $self->{"warnIndClickEvent"}->Do(@_) } );
	$errInd->{"onClick"}->Add( sub  { $self->{"errIndClickEvent"}->Do(@_) } );

	$szRow1->Add( $warnTxt, 0 );
	$szRow1->Add( $warnInd, 0 );

	$szRow2->Add( $errTxt, 0 );
	$szRow2->Add( $errInd, 0 );

	$szRow3->Add( $gauge, 1, &Wx::wxLEFT, 5 );

	$szStatBox->Add( 10, 10 );
	$szStatBox->Add( $szRow1, 0,  &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow2, 0,  &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( 10,      10, 1,                          &Wx::wxEXPAND );
	$szStatBox->Add( $szRow3, 0,  &Wx::wxEXPAND | &Wx::wxALL, 1 );

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

	#	use aliased 'Programs::StencilCreator::Forms::StencilPopupFrm';
	#
	#	my $form = StencilPopupFrm->new();
	#	$form->{"mainFrm"}->Show();
	#	$form->MainLoop();

}

1;

