#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package PureWindow;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;
use Win32::GUI;

#local library

use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Reorder::ReorderApp::Enums';
use aliased 'Popup';
#use aliased 'Managers::AbstractQueue::NotifyMngr::NotifyMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my @params = @_;
 
	my $title     = "My title";
	my $w         = 500;
	my $h         = 700;
	my @dimension = ( $w, $h );

	my $self = $class->SUPER::new( -1, $title, \@dimension, undef );

	bless($self);

	$self->__SetLayout();
 
	# Properties

	return $self;
}

sub Run {
	my $self = shift;

	$self->{"mainFrm"}->Show(1);

}

sub Init {
	my $self     = shift;
	my $launcher = shift;    # Launcher cobject

}

#-------------------------------------------------------------------------------------------#
#  Set layout
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Content definition	
	my $content = $self->__SetContentLayout( $self->{"mainFrm"} );

	$self->AddContent($content);

	# Button height
	$self->SetButtonHeight(30);

	# Button definition
	my $btnTest = $self->AddButton( "notify 1", sub { $self->test1(@_) } );
	my $btnTest2 = $self->AddButton( "notify 2", sub { $self->test2(@_) } );
	my $btnTest3 = $self->AddButton( "test 3",      sub { $self->test3(@_) } );

	# DEFINE LAYOUT STRUCTURE

	# KEEP REFERENCES

}

sub __SetContentLayout {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'My content' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS

	my $signalChb = Wx::CheckBox->new( $statBox, -1, "Signal layers", &Wx::wxDefaultPosition );
	my $maskChb   = Wx::CheckBox->new( $statBox, -1, "Mask layers",   &Wx::wxDefaultPosition );
	my $plugChb   = Wx::CheckBox->new( $statBox, -1, "Plug layers",   &Wx::wxDefaultPosition );
	my $goldChb   = Wx::CheckBox->new( $statBox, -1, "Gold layers",   &Wx::wxDefaultPosition );

	# SET EVENTS
	Wx::Event::EVT_CHECKBOX( $signalChb, -1, sub { $self->__OnCheckboxChecked("Ahoj") } );
	Wx::Event::EVT_CHECKBOX( $maskChb, -1, sub { $self->__OnCheckboxChecked("Hi") } );
	Wx::Event::EVT_CHECKBOX( $plugChb, -1, sub { $self->__OnCheckboxChecked("Hallo") } );
	Wx::Event::EVT_CHECKBOX( $goldChb, -1, sub { $self->__OnCheckboxChecked("Ciao") } );

	# BUILD STRUCTURE OF LAYOUT

	$szStatBox->Add( $signalChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $maskChb,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $plugChb,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $goldChb,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"signalChb"} = $signalChb;
	$self->{"maskChb"}   = $maskChb;
	$self->{"plugChb"}   = $plugChb;
	$self->{"goldChb"}   = $goldChb;

	return $szStatBox;
}


#-------------------------------------------------------------------------------------------#
#  Handlers
#-------------------------------------------------------------------------------------------#

sub test1 {
	my $self = shift;

 print STDERR "notify 1\n";

}
sub test2 {
	my $self = shift;
	
	print STDERR "notify 2\n";

}

sub test3 {
	my $self = shift;

	 print STDERR "notify 3\n";
}

sub __OnCheckboxChecked {
	my $self = shift;
	my $greeting = shift;

	 print STDERR "$greeting\n";
}



#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

1;

