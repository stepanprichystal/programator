#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::CamGuide::Forms::LoadChildFrm;

#use Wx ':everything';
use base 'Widgets::Forms::MyGeneralDialog';

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

	my $class  = shift;
	my $parent = shift;

	my $self = {};

	$self = $class->SUPER::new(
		$parent,                   # parent window
		-1,                        # ID -1 means any
		"Add child pcb",           # title
		&Wx::wxDefaultPosition,    # window position
		[ 370, 100 ],
		&Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	);

	$self->{"pcbId"}     = shift;
	$self->{"childId"}   = shift;
	$self->{"guideType"} = shift;

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

	my $pnlBody = $self->{"pnlBody"};

	#define sizers
	my $szTop       = Wx::BoxSizer->new(&Wx::wxVERTICAL);      #top level sizer
	my $szClmns     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    #top level sizer
	my $szRightClmn = Wx::BoxSizer->new(&Wx::wxVERTICAL);      #right column child of first row sizer
	my $szLeftClmn  = Wx::BoxSizer->new(&Wx::wxVERTICAL);      #right column child of first row sizer
	     #my $szFoot  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);      #right column child of first row sizer
	     #my $szBtns      = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    #sizer for buttons child of $szRightClmn

	#define of panels
	#my $pnlBtns = Wx::Panel->new( $self, -1, [ 1, 1 ] );

	#define controls

	my $titleTxt = Wx::StaticText->new( $pnlBody, -1, 'You are about to add child pcb to job ' . $self->{"pcbId"} . ".",
										&Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	$titleTxt->SetFont($Widgets::Style::fontLbl);
	my $masterTxt = Wx::StaticText->new( $pnlBody, -1, 'Master pcb:', &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	$masterTxt->SetFont($Widgets::Style::fontLblBold);
	my $stepnameTxt = Wx::StaticText->new( $pnlBody, -1, 'New steps:', &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	$stepnameTxt->SetFont($Widgets::Style::fontLblBold);
	my $guideTxt = Wx::StaticText->new( $pnlBody, -1, 'Guide type:', &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	$guideTxt->SetFont($Widgets::Style::fontLblBold);

	my $masterValueTxt = Wx::StaticText->new( $pnlBody, -1, $self->{"pcbId"}, &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	$masterValueTxt->SetFont($Widgets::Style::fontLbl);
	my $stepnameOTxt = Wx::StaticText->new( $pnlBody, -1, "o_pcb" . $self->{"childId"} . ", " . "o+1_pcb" . $self->{"childId"},
											&Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	$stepnameOTxt->SetFont($Widgets::Style::fontLbl);
	my $guideValTxt = Wx::StaticText->new( $pnlBody, -1, $self->{"guideType"}, &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	$guideValTxt->SetFont($Widgets::Style::fontLbl);

	#my $stepnameO1Txt = Wx::StaticText->new( $self, -1, "o+1_pcb" . $self->{"childId"}, &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	#$stepnameO1Txt->SetFont($Widgets::Style::fontLbl);

	my $loadBtn = $self->AddButton("Load files");

	#my $loadBtn = Wx::Button->new( $pnlBtns, -1, "Load files" );
	#$loadBtn->SetFont($Widgets::Style::fontBtn);

	#regiter events
	Wx::Event::EVT_BUTTON( $loadBtn, -1, sub { __OnLoadBtnClick( $self, @_ ) } );

	#set colours and fonts
	#$self->SetBackgroundColour($Widgets::Style::clrWhite);
	#$pnlBtns->SetBackgroundColour($Widgets::Style::clrDefaultFrm);

	#create layoute structure

	$szLeftClmn->Add( 10, 10, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szLeftClmn->Add( $stepnameTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szLeftClmn->Add( $masterTxt,   0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szLeftClmn->Add( $guideTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRightClmn->Add( 10, 10, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szRightClmn->Add( $stepnameOTxt,   0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRightClmn->Add( $masterValueTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRightClmn->Add( $guideValTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	#$szBtns->Add( $loadBtn, 0, &Wx::wxALIGN_RIGHT | &Wx::wxALL );

	$szClmns->Add( $szLeftClmn,  30, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szClmns->Add( $szRightClmn, 70, &Wx::wxEXPAND | &Wx::wxALL, 4 );

	#$szFoot->Add( 10, 10, 1, &Wx::wxEXPAND );
	#$szFoot->Add( $szBtns, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	#$pnlBtns->SetSizer($szFoot);

	$szTop->Add( $titleTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 5 );
	$szTop->Add( $szClmns, 0, &Wx::wxEXPAND );

	#$szTop->Add( $pnlBtns, 0, &Wx::wxEXPAND );

	$pnlBody->SetSizer($szTop);

	$self->SetMinSize( $self->GetSize() );
	$self->Fit();

	return $self;

}

sub __OnLoadBtnClick {

	my ( $self, $button, $event ) = @_;

	print "1";

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

if (1) {

	my $frm = Programs::CamGuide::Forms::LoadChildFrm->new( -1, "D3333", 2, "Guid vv" );
	$frm->ShowModal();

}

1;

