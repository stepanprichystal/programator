#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::MyGeneralDialog;

#use Wx ':everything';
use base 'Widgets::Forms::MyWxDialog';

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library
use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class     = shift;
	my $parent    = shift;
	my $id = 		shift;
	my $title     = shift;
	my $position  = shift;
	my $dimension = shift;
	my $style     = shift;

	unless ($position) {
		$position = &Wx::wxDefaultPosition;
	}

	my $self = {};

	if ( defined $parent && $parent == -1 ) {
		$parent = undef;
	}

	$self = $class->SUPER::new(
								$parent,      # parent window
								$id,           # ID -1 means any
								$title,       # title
								$position,    # window position
								$dimension,
								$style
	);

	bless($self);

	$self->__SetLayout();

	return $self;

}

sub OnInit {
	my $self = shift;

	return 1;
}

sub __SetLayout {
	my $self = shift;

	#define sizers
	my $szTop  = Wx::BoxSizer->new(&Wx::wxVERTICAL);      #top level sizer
	                                                      #my $szBody     = Wx::BoxSizer->new(&Wx::wxVERTICAL);    #top level sizer
	my $szFoot = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    #right column child of first row sizer
	my $szBtns = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    #sizer for buttons child of $szRightClmn

	#define of panels
	my $pnlBody = Wx::Panel->new( $self, -1, [ 1, 1 ] );
	my $pnlBtns = Wx::Panel->new( $self, -1, [ 1, 1 ] );

	#define controls

	#set colours and fonts
	$self->SetBackgroundColour($Widgets::Style::clrWhite);
	$pnlBtns->SetBackgroundColour($Widgets::Style::clrDefaultFrm);

	#create layoute structure

	#$szBtns->Add( $loadBtn, 0, &Wx::wxALIGN_RIGHT | &Wx::wxALL );
	$szFoot->Add( 10, 10, 1, &Wx::wxEXPAND );
	$szFoot->Add( $szBtns, 0, &Wx::wxEXPAND );
	$pnlBtns->SetSizer($szFoot);

	$szTop->Add( $pnlBody, 0, &Wx::wxEXPAND );
	$szTop->Add( $pnlBtns, 0, &Wx::wxEXPAND );

	$self->SetSizer($szTop);
	#$szTop->Layout();
	#$self->SetMinSize( $self->GetSize() );
	#$self->Fit();

	$self->{"pnlBody"} = $pnlBody;
	$self->{"szBtns"}  = $szBtns;
	$self->{"pnlBtns"} = $pnlBtns;

	return $self;

}

sub AddButton {
	my $self = shift;
	my $lbl  = shift;
	
	my $btn = Wx::Button->new( $self->{"pnlBtns"}, -1, $lbl );
	$btn->SetFont($Widgets::Style::fontBtn);

	$self->{"szBtns"}->Add( $btn, 0, &Wx::wxALIGN_RIGHT | &Wx::wxALL, 1 );
	
	#$self->{"szBtns"}->Layout();

	return $btn;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

if (0) {

	my $frm = Programs::CamGuide::Forms::LoadChildFrm->new( -1, "D3333", 2, "Guid vv" );
	$frm->ShowModal();

}

1;

