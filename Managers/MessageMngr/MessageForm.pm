use utf8;

#use Wx qw(:dialog);

#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::MessageMngr::MessageForm;

#use Wx ':everything';
use base 'Widgets::Forms::MyWxDialog';

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);
use Wx qw(:richtextctrl :textctrl :font);
use Wx qw(:icon wxTheApp wxNullBitmap);

BEGIN {
	eval { require Wx::RichText; };
}

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Widgets::Forms::MyWxFrame';
use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class  = shift;
	my $parent = shift;

	my $self = {};

	if ( defined $parent && $parent == -1 ) {
		$parent = undef;
	}

	$self = $class->SUPER::new(
		$parent,                   # parent window
		-1,                        # ID -1 means any
		"",                        # title
		&Wx::wxDefaultPosition,    # window position
		[ 800, 150 ],
		&Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX    #| &Wx::wxCLOSE_BOX
	);

	bless($self);

	$self->{"pcbId"}    = shift;
	$self->{"type"}     = shift;
	$self->{"messages"} = shift;
	$self->{"buttons"}  = shift;

	#$self->{"resultMngr"} = shift;
	$self->{"caller"} = shift;
	$self->{"onExit"} = shift;
	$self->{"result"} = -1;

	$self->__SetLayout();

	#$self->SetTopWindow($self);

	#$self->MakeModal(1); # (Explicit call to MakeModal)
	#$self->ShowModal();

	# now to stop execution start a event loop
	#$self->{"eventLoop"} = Wx::EventLoopBase->new();
	# $self->{"eventLoop"}->Run();

	return $self;

}

sub OnInit {
	my $self = shift;

	return 1;
}

sub __SetLayout {

	my $self   = shift;
	my $parent = shift;

	my @messages = @{ $self->{messages} };

	#main formDefain forms
	#my $self = MyWxFrame->new(
	#	$parent,                     # parent window
	#	-1,                        # ID -1 means any
	#	$type,                     # title
	#	&Wx::wxDefaultPosition,    # window position
	#	[ 800, 150 ],              # size
	#	&Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	#);

	$self->SetLabel( $self->{"type"} );

	#define sizers
	my $szTop     = Wx::BoxSizer->new(&Wx::wxVERTICAL);      #top level sizer
	my $szFrstRow = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    #first row child of top top level sizer
	my $szSecRow  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    #second row child of top top level sizer

	#my $szLeftClmn =Wx::BoxSizer->new(&Wx::wxVERTICAL);  #left column child of first row sizer
	my $szRightClmn = Wx::BoxSizer->new(&Wx::wxVERTICAL);    #right column child of first row sizer

	my $szRightTop  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);  #first row child of $szRightClmn
	my $szIco       = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);  #right column child of $szRightTop
	my $szBtns      = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);  #sizer for buttons child of $szRightClmn
	my $szBtnsChild = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);  #sizer for buttons child of $szBtns

	#define of panels

	my $pnlBtns = Wx::Panel->new( $self, -1, [ 1, 1 ] );
	my $pnlIco  = Wx::Panel->new( $self, -2, [ 1, 1 ] );

	#define controls

	my $scriptTxt = Wx::StaticText->new( $self, -1, 'Script:', &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	$scriptTxt->SetFont($Widgets::Style::fontLblBold);

	my $pcbTxt = Wx::StaticText->new( $self, -1, 'Id:' );
	$pcbTxt->SetFont($Widgets::Style::fontLblBold);

	my $pcbValueTxt = Wx::StaticText->new( $self, -1, $self->{"pcbId"} );
	$pcbValueTxt->SetFont($Widgets::Style::fontLbl);

	my $scriptNameTxt = Wx::StaticText->new( $self, -1, $self->{"caller"} );
	$scriptNameTxt->SetFont($Widgets::Style::fontLbl);

	my $richTxt = Wx::RichTextCtrl->new( $self, -1, '', [ -1, -1 ], [ 800, $self->__GetHeightOfText() ] );
	$richTxt->SetEditable(0);

	#$richTxt->SetSize( [ 800, 200 ] );
	$richTxt->SetBackgroundColour($Widgets::Style::clrWhite);
	$self->__WriteMessages($richTxt);
	$richTxt->Layout();

	my $btm = Wx::Bitmap->new( GeneralHelper->Root() . "/Resources/Images/" . $self->__GetIcoName() . ".bmp", &Wx::wxBITMAP_TYPE_BMP );
	my $staticbitmap = Wx::StaticBitmap->new( $pnlIco, -1, $btm );
	my $typeTxt = Wx::StaticText->new( $pnlIco, -1, $self->{"type"} );
	$typeTxt->SetFont($Widgets::Style::fontLbl);

	if ( $self->{type} eq EnumsGeneral->MessageType_SYSTEMERROR ) {

		$typeTxt->SetForegroundColour($Widgets::Style::clrWhite);
	}

	#regiter events
	Wx::Event::EVT_CLOSE( $self, sub { $self->__OnClose(@_) } );

	#set colours and fonts
	$self->SetBackgroundColour($Widgets::Style::clrDefaultFrm);
	$pnlBtns->SetBackgroundColour($Widgets::Style::clrDefaultFrm);
	$pnlIco->SetBackgroundColour( $self->__GetIcoColor() );

	#create layoute structure
	$szTop->Add( $szFrstRow, 1, &Wx::wxGROW );
	$szTop->Add( $szSecRow,  0, &Wx::wxEXPAND );

	#$szFrstRow->Add( $szLeftClmn,  0, &Wx::wxALIGN_LEFT );
	$szFrstRow->Add( $szRightClmn, 1, &Wx::wxALIGN_LEFT );
	$szSecRow->Add( $pnlBtns, 1, &Wx::wxEXPAND );

	#$szLeftClmn->Add( $scriptTxt, 0, &Wx::wxALL, 5, &Wx::wxALIGN_CENTER );
	#$szLeftClmn->Add( $messageTxt, 0, &Wx::wxALL, 5 );

	$szRightClmn->Add( $szRightTop, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRightClmn->Add( $richTxt, 1, &Wx::wxEXPAND );

	$szRightTop->Add( $scriptTxt,     0, &Wx::wxLEFT | &Wx::wxTOP, 4 );
	$szRightTop->Add( $scriptNameTxt, 0, &Wx::wxLEFT | &Wx::wxTOP, 4 );

	if ( defined $self->{"pcbId"} ) {
		$szRightTop->Add( 5, 5, 0, &Wx::wxLEFT | &Wx::wxTOP, 4 );
		$szRightTop->Add( $pcbTxt,      0, &Wx::wxLEFT | &Wx::wxTOP, 4 );
		$szRightTop->Add( $pcbValueTxt, 0, &Wx::wxLEFT | &Wx::wxTOP, 4 );
	}

	$szRightTop->Add( 5,       5, 1,          &Wx::wxGROW );
	$szRightTop->Add( $pnlIco, 0, &Wx::wxALL, 1 );

	$szIco->Add( $staticbitmap, 0, &Wx::wxALL, );
	$szIco->Add( $typeTxt, 0, &Wx::wxLEFT | &Wx::wxRIGHT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER_HORIZONTAL, 10 );
	$pnlIco->SetSizer($szIco);

	$szBtns->Add( 10, 10, 1, &Wx::wxGROW );
	$szBtns->Add( $szBtnsChild, 0, &Wx::wxALIGN_RIGHT | &Wx::wxALL );

	$pnlBtns->SetSizer($szBtns);

	$self->__AddButtons( $pnlBtns, $szBtnsChild );

	$self->SetSizer($szTop);

	$self->SetMinSize( $self->GetSize() );

	$szRightClmn->Layout();
	$self->Fit();

	#my $btmIco =Wx::Bitmap->new( GeneralHelper->Root() . "/Resources/Images/Icon.bmp",&Wx::wxBITMAP_TYPE_BMP );
	#my $icon = Wx::Icon->new();
	#$icon->CopyFromBitmap($btmIco);
	#$self->SetIcon($icon);

	return $self;
}

sub __OnClose {
	my $self  = shift;
	my $event = shift;

	print STDERR "\n Zaviram okno \n";

	#$self->Destroy();
	my $onExit = $self->{"onExit"};

	if ( defined $onExit ) {
		$onExit->( $self, 0 );
	}

}

sub __WriteMessages() {

	my $self    = shift;
	my $richTxt = shift;
	my $mess;

	$richTxt->BeginFontSize(11);

	my @messages = @{ $self->{messages} };

	for ( my $i = 0 ; $i < scalar(@messages) ; $i++ ) {

		$richTxt->BeginItalic;
		$richTxt->EndBold;

		$mess = $messages[$i];

		$mess =~ s/@/###/;
 
		#my @messSplit = split /@/, $mess;

		my $bold = 0;

		#foreach my $l (split //,$mess) {
		my $block   = "";
		my $messPom = "";    # here is stored char bz char message and tested on <r> atd
		my $messRealLen = 0;
		foreach my $ch ( split //, $mess ) {

			$messPom .= $ch;
			$messRealLen++;
			my $openTag  = substr $messPom, -3;
			my $closeTag = substr $messPom, -4;

			if ( $openTag =~ /<(\w)>/ ) {

				if ( $1 eq "r" ) {
					$richTxt->BeginTextColour( Wx::Colour->new( 255, 0, 0 ) );
				}
				elsif ( $1 eq "b" ) {
					$richTxt->BeginBold();
				}
				
				$richTxt->Remove($messRealLen -3, $messRealLen);
				$messRealLen -=3;

			}elsif ( $closeTag =~ /<\/(\w)>/ ) {
				
				if ( $1 eq "b" ) {
					$richTxt->EndBold();
				}
				else {
					$richTxt->EndTextColour();
				}
				
				$richTxt->Remove($messRealLen -4, $messRealLen);
				$messRealLen -=4;

			}else{
				
				$richTxt->WriteText($ch);
			}
			
 
		}

		if ( $block ne "" ) {
			$block =~ s/###/@/;
			$richTxt->WriteText($block);
		}

		#$richTxt->WriteText( $messages[$i] );

		if ( $i + 1 != scalar(@messages) ) {
			$richTxt->BeginFontSize(1);
			$richTxt->Newline;
			$richTxt->Newline;
			$richTxt->BeginFontSize(11);
		}

		#}
	}

}

sub __GetHeightOfText {
	my $self     = shift;
	my @messages = @{ $self->{messages} };

	my $rowCount = 0;

	for ( my $i = 0 ; $i < scalar(@messages) ; $i++ ) {

		my $linenum = $messages[$i] =~ tr/\n//;

		my @lines = split( "\n", $messages[$i] );

		foreach my $l (@lines) {

			my $cntPerLine = int( length($l) / 100 );
			$cntPerLine = $cntPerLine < 1 ? 1 : $cntPerLine;

			$rowCount += $cntPerLine;

		}
		$rowCount += 1;

		#		foreach
		#
		#		print "\n\n".length( $messages[$i] )."\n line num : $linenum\n";
		#		$rowCount += ( int( length( $messages[$i] ) / 100 ) + 1 );
	}

	$rowCount += scalar(@messages);

	#22 is size for one line. If line is only one add some free space 15px
	my $space = ( scalar(@messages) == 1 ) ? 15 : 0;
	my $heiht = $rowCount * 18 + $space;

	# restrict max height
	if ( $heiht > 800 ) {
		$heiht = 800;
	}

	return $heiht;
}

sub __AddButtons {
	my $self        = shift;
	my $pnlBtns     = shift;
	my $szBtnsChild = shift;
	my @buttons     = undef;

	unless ( defined $self->{buttons} ) {
		push( @{ $self->{buttons} }, "Ok" );
	}

	@buttons = @{ $self->{buttons} };

	for ( my $i = 0 ; $i < scalar(@buttons) ; $i++ ) {

		my $btn = $buttons[$i];

		my $button = Wx::Button->new( $pnlBtns, -1, $btn );
		$button->SetFont($Widgets::Style::fontBtn);
		$button->{"order"} = $i;

		$szBtnsChild->Add( $button, 0, &Wx::wxALL, 1 );

		Wx::Event::EVT_BUTTON( $button, -1, sub { __OnClick( $self, $button ) } );

	}
}

sub __OnClick {

	my ( $self, $button ) = @_;

	#$parent->{"result"} = $button->{"order"};
	#$self->Destroy();

	print STDERR "\nClick\n";

	my $onExit = $self->{"onExit"};

	if ( defined $onExit ) {
		$onExit->( $self, $button->{"order"} );
	}

	#${$self->{"resultMngr"}} = $button->{"order"};

	#$self->Destroy();
}

sub __GetIcoName {
	my $self = shift;

	my $imgName = "";

	if ( $self->{type} eq EnumsGeneral->MessageType_ERROR ) {
		$imgName = "Error";
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_SYSTEMERROR ) {
		$imgName = "Error";
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_WARNING ) {
		$imgName = "Warning";
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_QUESTION ) {
		$imgName = "Question";
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_INFORMATION ) {
		$imgName = "Info";
	}
	else {
		$imgName = "Info";
	}

	return $imgName;
}

sub __GetIcoColor {
	my $self = shift;

	my $iconColor = "";

	if ( $self->{type} eq EnumsGeneral->MessageType_ERROR ) {
		$iconColor = $Widgets::Style::clrError;

	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_SYSTEMERROR ) {
		$iconColor = $Widgets::Style::clrSystemError;
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_WARNING ) {
		$iconColor = $Widgets::Style::clrWarning;
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_QUESTION ) {
		$iconColor = $Widgets::Style::clrInfoQuestion;
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_INFORMATION ) {
		$iconColor = $Widgets::Style::clrInfoQuestion;
	}
	else {
		$iconColor = $Widgets::Style::clrInfoQuestion;
	}

	return $iconColor;
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

if (0) {

	#	my @btns = ( "Nechcu", "Chcu" );                              # "Nechcu" = tl. cislo 1, "Chcu" = tl.cislo 2
	#	my @mess1 = ("Chtel bys jit dom?t dom?Chtel bys jit dom?");
	#	my $app = Managers::MessageMngr::MessageForm->new( EnumsGeneral->MessageType_WARNING, \@mess1, \@btns, \&test );
	#
	#	$app->MainLoop;
	#
	#	print "Finish";
	#
	#	sub test {
	#		print "Test";
	#		print $app->{"result"};
	#		my $self = $app->{"mainFrm"};
	#		$self->Close();
	#
	#		print "Finish";
	#	}

}

1;
