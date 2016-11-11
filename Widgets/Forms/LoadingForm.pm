#-------------------------------------------------------------------------------------------#
# Description: Window showing single progress bar and label. Can use 
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::LoadingForm;
use base 'Wx::App';

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library
use aliased 'Widgets::Forms::MyWxFrame';

use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self   = shift;
	my $parent = shift;

	$self = {};

	if ( !defined $parent || $parent == -1 ) {
		$self = Wx::App->new( \&OnInit );
	}

	bless($self);

	# PROPERTIES

	$self->{"title"} = shift;

	#$self->{"groupBuilder"} = GroupBuilder->new($self);

	my $mainFrm = $self->__SetLayout($parent);

	$mainFrm->Show();

	#EVENTS

	return $self;
}

sub OnInit {
	my $self = shift;

	return 1;
}

sub __SetLayout {
	my $self   = shift;
	my $parent = shift;

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,                   # parent window
		-1,                        # ID -1 means any
		"Exporter checker",        # title
		&Wx::wxDefaultPosition,    # window position
		[ 300, 100 ],              # size
		&Wx::wxSTAY_ON_TOP | &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION |    &Wx::wxCLOSE_BOX
	);

	$mainFrm->Centre(&Wx::wxCENTRE_ON_SCREEN);
	 

	#DEFINE PANELS

	#DEFINE SIZERS

	#main sizer for top frame
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Sizer inside first static box
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#define staticboxes

	# DEFINE CONTROLS

	my $titleTxt = Wx::StaticText->new( $mainFrm, -1, $self->{"title"} );
	my $gauge = Wx::Gauge->new( $mainFrm, -1, 100, [ -1, -1 ], [ 200, 20 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(100);
	$gauge->Pulse();

	# REGISTER EVENTS

	$szRow1->Add( $titleTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szRow1->Add( 2, 2,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRow1->Add( $gauge,    1, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	
	$szMain->Add( $szRow1, 0, &Wx::wxEXPAND | &Wx::wxALL, 5);

	# SAVE CONTROLS

	$mainFrm->SetSizer($szMain);
	$self->{"mainFrm"} = $mainFrm;

	return $mainFrm;
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Widgets::Forms::LoadingForm';

	my $test = LoadingForm->new(-1, "Loading Exporter Checker...");

	$test->MainLoop();
}

1;

