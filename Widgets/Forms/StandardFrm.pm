#-------------------------------------------------------------------------------------------#
# Description: Standard window, wchich allow add buttons to bottom part of window
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::StandardFrm;
use base 'Wx::App';



#3th party library
use strict;
use warnings;
use Wx;

#local library

use aliased 'Widgets::Forms::MyWxFrame';
use Widgets::Style;
use aliased 'Managers::MessageMngr::MessageMngr';

#tested form

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class      = shift;
	my $parent    = shift;
	my $title     = shift;
	my $dimension = shift;
	my $flags = shift;
	my $position = shift;
	 
	
	unless(defined $flags){
		$flags = &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX |  &Wx::wxCLOSE_BOX;
	}
	
	unless(defined $position){
		$position = &Wx::wxDefaultPosition;
	}
	
	my $self = {};


	# $parent:1 means there exist already Wx:App (caller), but don't use its parent frame
	if($parent == 1){
		
		$parent = undef;
	}
	# if no parent, we have to create new Wx::App
	elsif ( !defined $parent || $parent == -1) {
		
		$self = Wx::App->new( \&OnInit );
	}

	bless($self);

	my $mainFrm = $self->__SetLayout( $parent, $title, $dimension, $flags, $position );

	# Properties
	$self->{"btnHeight"} = 30;

	$self->{"messMngr"} = MessageMngr->new($title, $mainFrm); # standard message mngr


	return $self;
}

sub OnInit {
	my $self = shift;

	return 1;
}

sub SetButtonHeight {
	my $self = shift;
	my $h    = shift;

	$self->{"btnHeight"} = $h;
}

# add content to window, content has to be type of panel, frame
sub AddContent {
	my $self    = shift;
	my $content = shift;
	my $margin = shift // 4; # default margin 4 px 
	
 

	$self->{"szContainer"}->Add( $content, 1, &Wx::wxEXPAND | &Wx::wxALL, $margin );
}

sub AddButton {
	my $self    = shift;
	my $title   = shift;
	my $handler = shift; # fuc=nction , whic will be called when click
	my $width   = shift;

	my $w = -1;

	if ($width) {
		$w = $width;
	}

	my $btn = Wx::Button->new( $self->{"pnlBtns"}, -1, $title, &Wx::wxDefaultPosition, [ $w, $self->{"btnHeight"} ] );
	$btn->SetFont($Widgets::Style::fontBtn);
	$btn->SetFocus() ;    # focus on last button

	Wx::Event::EVT_BUTTON( $btn, -1, sub { $handler->(@_) } );

	$self->{"szBtnsChild"}->Add( $btn, 0, &Wx::wxALL, 1 );

	$self->{"mainFrm"}->Layout();
	
	return $btn;

}

# Show after hiding form
sub ShowFrm{
	my $self = shift;
	
	$self->{"mainFrm"}->Show();
	
}

# temporarily hides form
sub HideFrm{
	my $self = shift;
	
	$self->{"mainFrm"}->Hide();
	
}


sub _GetMessageMngr{
	my $self      = shift;
	
	return $self->{"messMngr"};
}



sub __SetLayout {
	my $self      = shift;
	my $parent    = shift;
	my $title     = shift;
	my $dimension = shift;
	my $flags = shift;
	my $position = shift;
	

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
								  $parent,                   # parent window
								  -1,                        # ID -1 means any
								  $title,                    # title
								  $position,    # window position
								  $dimension,                # size
								  $flags
	);

	if($position eq &Wx::wxDefaultPosition){

		$mainFrm->CentreOnParent(&Wx::wxBOTH);
	
	}

	# DEFINE SIZERS

	my $szMain      = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szContainer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE PNALES

	#my $pnlContainer = Wx::Panel->new( $mainFrm, -1 );

	my $pnlBtns = Wx::Panel->new( $mainFrm, -1 );
	$pnlBtns->SetBackgroundColour($Widgets::Style::clrDefaultFrm);
	my $szBtns      = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szBtnsChild = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	# DEFINE LAYOUT STRUCTURE

	$szBtns->Add( 10, 0, 1, &Wx::wxGROW );
	$szBtns->Add( $szBtnsChild, 0, &Wx::wxALIGN_RIGHT | &Wx::wxALL );
	$pnlBtns->SetSizer($szBtns);

	#$pnlContainer->SetSizer($szContainer);
	$szMain->Add( $szContainer, 1, &Wx::wxEXPAND );
	$szMain->Add( $pnlBtns,     0, &Wx::wxEXPAND );

	$mainFrm->SetSizer($szMain);
	$mainFrm->Layout();

	# SET REFERENCES

	$self->{"szBtnsChild"} = $szBtnsChild;
	$self->{"pnlBtns"}     = $pnlBtns;
	$self->{"mainFrm"}     = $mainFrm;
	$self->{"szContainer"} = $szContainer;

	return $mainFrm;
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased "Widgets::Forms::StandardFrm";

	my @dimension = ( 500, 800 );

	my $test = StandardFrm->new( -1, "Title", \@dimension );

	my $pnl = Wx::Panel->new( $test->{"mainFrm"}, -1, [ -1, -1 ], [ 100, 100 ] );
	$pnl->SetBackgroundColour($Widgets::Style::clrLightRed);
	$test->AddContent($pnl);

	$test->SetButtonHeight(20);

	$test->AddButton( "Set", sub { Test(@_) } );
	$test->AddButton( "EE",  sub { Test(@_) } );
	$test->{"mainFrm"}->Show();
	$test->MainLoop();
}

#sub Test {
#
#	print "yde";
#
#}

1;

