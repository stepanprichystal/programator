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
use aliased 'Managers::MessageMngr::Enums';
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
	$self->{"images"}   = shift;

	#$self->{"resultMngr"} = shift;
	$self->{"caller"}     = shift;
	$self->{"parameters"} = shift;
	$self->{"onExit"}     = shift;
	$self->{"result"}     = -1;

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

	# DEFINE SIZERS

	my $szTop     = Wx::BoxSizer->new(&Wx::wxVERTICAL);      #top level sizer
	my $szFrstRow = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    #first row child of top top level sizer
	my $szSecRow  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    #second row child of top top level sizer

	#my $szLeftClmn =Wx::BoxSizer->new(&Wx::wxVERTICAL);  #left column child of first row sizer
	my $szRightClmn = Wx::BoxSizer->new(&Wx::wxVERTICAL);    #right column child of first row sizer

	my $szRightTop  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);  #first row child of $szRightClmn
	my $szIco       = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);  #right column child of $szRightTop
	my $szBtns      = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);  #sizer for buttons child of $szRightClmn
	my $szBtnsChild = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);  #sizer for buttons child of $szBtns

	# DEFINE PANELS

	my $pnlBtns = Wx::Panel->new( $self, -1, [ 1, 1 ] );
	my $pnlIco  = Wx::Panel->new( $self, -2, [ 1, 1 ] );

	# DEFINE COTROLS

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

	my $szPar = $self->__SetLayoutParameters($self);

	# REGISTER EVENTS

	Wx::Event::EVT_CLOSE( $self, sub { $self->__OnClose(@_) } );

	# SET FONTS AND COLORS

	$self->SetBackgroundColour($Widgets::Style::clrDefaultFrm);
	$pnlBtns->SetBackgroundColour($Widgets::Style::clrDefaultFrm);
	$pnlIco->SetBackgroundColour( $self->__GetIcoColor() );

	# BUILD LAYOUT STRUCTURE

	$szTop->Add( $szFrstRow, 1, &Wx::wxGROW );
	$szTop->Add( $szSecRow,  0, &Wx::wxEXPAND );

	$szFrstRow->Add( $szRightClmn, 1, &Wx::wxALIGN_LEFT );
	$szSecRow->Add( $pnlBtns, 1, &Wx::wxEXPAND );

	$szRightClmn->Add( $szRightTop, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szRightClmn->Add( $richTxt,    1, &Wx::wxEXPAND );
	$szRightClmn->Add( $szPar,      0, &Wx::wxEXPAND );

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

sub __SetLayoutParameters {
	my $self   = shift;
	my $parent = shift;

	my $szPar     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szClTitle = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szClVal   = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szClDef   = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	foreach my $messPar ( @{ $self->{"parameters"} } ) {

		my $parTitleTxt = Wx::StaticText->new( $parent, -1, $messPar->GetTitle() . ":", &Wx::wxDefaultPosition );
		my $btnReset = Wx::Button->new( $parent, -1, "Default", &Wx::wxDefaultPosition );
		my $parVal;

		if ( $messPar->GetParameterType() eq Enums->ParameterType_TEXT ) {

			$parVal = Wx::TextCtrl->new( $parent, -1, "", &Wx::wxDefaultPosition );
			$parVal->SetValue( $messPar->GetOrigValue() );

			Wx::Event::EVT_TEXT( $parVal, -1, sub { $self->__OnParameterChanged( $parVal->GetValue(), $messPar ) } );
			Wx::Event::EVT_BUTTON( $btnReset, -1, sub { $parVal->SetValue( $messPar->GetOrigValue() ) } );

		}
		elsif ( $messPar->GetParameterType() eq Enums->ParameterType_NUMBER ) {

			$parVal = Wx::SpinCtrl->new( $parent, -1, $messPar->GetOrigValue(), &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxSP_ARROW_KEYS, -99999, 99999 );
			$parVal->SetValue( $messPar->GetOrigValue() );

			Wx::Event::EVT_TEXT( $parVal, -1, sub { $self->__OnParameterChanged( $parVal->GetValue(), $messPar ) } );
			Wx::Event::EVT_BUTTON( $btnReset, -1, sub { $parVal->SetValue( $messPar->GetOrigValue() ) } );

		}
		elsif ( $messPar->GetParameterType() eq Enums->ParameterType_OPTION ) {

			my @opt = $messPar->GetOptions();
			$parVal = Wx::ComboBox->new( $parent, -1, $messPar->GetOrigValue(), &Wx::wxDefaultPosition,   &Wx::wxDefaultSize, \@opt, &Wx::wxCB_READONLY );
			$parVal->SetValue( $messPar->GetOrigValue() );

			Wx::Event::EVT_TEXT( $parVal, -1, sub { $self->__OnParameterChanged( $parVal->GetValue(), $messPar ) } );
			Wx::Event::EVT_BUTTON( $btnReset, -1, sub { $parVal->SetValue( $messPar->GetOrigValue() ) } );
		
		}elsif ( $messPar->GetParameterType() eq Enums->ParameterType_CHECK ) {
 
			$parVal = Wx::CheckBox->new( $parent, -1, "",  &Wx::wxDefaultPosition, &Wx::wxDefaultSize  );
			$parVal->SetValue( $messPar->GetOrigValue() );
			Wx::Event::EVT_CHECKBOX( $parVal, -1, sub { $self->__OnParameterChanged( $parVal->GetValue(), $messPar ) } );
			Wx::Event::EVT_BUTTON( $btnReset, -1, sub { $parVal->SetValue( $messPar->GetOrigValue() ) } );
		}

		$szClTitle->Add( $parTitleTxt, 0, &Wx::wxALL, 3 );
		$szClVal->Add( $parVal,   0, &Wx::wxALL | &Wx::wxEXPAND , 0 );
		$szClDef->Add( $btnReset, 0, &Wx::wxALL, 0 );

		#$szRow->Add( 10, 10, 75, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	}

	$szPar->Add( $szClTitle, 0, &Wx::wxALL, 1 );
	$szPar->Add( $szClVal,   0, &Wx::wxALL, 1 );
	$szPar->Add( $szClDef, &Wx::wxALL, 1 );

	#$szPar->Add( 10, 10, 1, &Wx::wxALL, 1 );

	return $szPar;
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

sub __OnParameterChanged {
	my $self      = shift;
	my $curValue  = shift;
	my $parameter = shift;

	# Place for value check

	$parameter->SetResultValue($curValue);
}

sub __WriteMessages() {

	my $self    = shift;
	my $richTxt = shift;
	my $mess;

	# WriteImage (const wxString &filename, wxBitmapType bitmapType, const wxRichTextAttr &textAttr=wxRichTextAttr())
	#Loads an image from a file and writes it at the current insertion point. More...

	$richTxt->Freeze();

	$richTxt->BeginFontSize(10.5);

	my @messages = @{ $self->{messages} };
	my $index    = -1;

	for ( my $i = 0 ; $i < scalar(@messages) ; $i++ ) {

		$richTxt->BeginItalic;
		$richTxt->EndBold;

		$mess = $messages[$i];

		#$mess =~ s/@/###/;

		#my @messSplit = split /@/, $mess;

		my $bold = 0;

		#foreach my $l (split //,$mess) {

		my $messPom = "";    # here is stored char bz char message and tested on <r> atd

		my $openTag  = "";
		my $closeTag = "";
		my $imgTag   = "";

		foreach my $ch ( split //, $mess ) {

			$messPom .= $ch;

			$richTxt->WriteText($ch);
			$index++;

			$openTag  = substr $messPom, -3;
			$closeTag = substr $messPom, -4;
			$imgTag   = substr $messPom, -10;

			if ( $openTag =~ /<(\w)>/ ) {

				if ( $1 eq "r" ) {
					$richTxt->BeginTextColour( Wx::Colour->new( 230, 0, 0 ) );
				}
				elsif ( $1 eq "g" ) {
					$richTxt->BeginTextColour( Wx::Colour->new( 4, 136, 53 ) );
				}
				elsif ( $1 eq "b" ) {
					$richTxt->BeginBold();
				}
				elsif ( $1 eq "i" ) {
					$richTxt->BeginBold();
				}
				$richTxt->Remove( $richTxt->GetLastPosition() - 1, $richTxt->GetLastPosition() )
				  ;    # tohle tady musi byt jinak nejde odmazat posleddni znak
				$richTxt->Remove( $richTxt->GetLastPosition() - 3, $richTxt->GetLastPosition() );
				$messPom = substr $messPom, 0, length($messPom) - 4;

			}
			elsif ( $closeTag =~ /<\/(\w)>/ ) {

				if ( $1 eq "b" ) {
					$richTxt->EndBold();
				}
				else {
					$richTxt->EndTextColour();
				}
				$richTxt->Remove( $richTxt->GetLastPosition() - 1, $richTxt->GetLastPosition() )
				  ;    # tohle tady musi byt jinak nejde odmazat posleddni znak
				$richTxt->Remove( $richTxt->GetLastPosition() - 4, $richTxt->GetLastPosition() );
				$index -= 4;
				$messPom = substr $messPom, 0, length($messPom) - 4;

			}
			elsif ( $imgTag =~ m/<img(\d+)>/ ) {

				my $imgNumber = $1;

				my $tagLen = length( ( $imgTag =~ m/(<img\d+>)/ )[0] );

				$richTxt->Remove( $richTxt->GetLastPosition() - 1, $richTxt->GetLastPosition() )
				  ;    # tohle tady musi byt jinak nejde odmazat posleddni znak
				$richTxt->Remove( $richTxt->GetLastPosition() - $tagLen, $richTxt->GetLastPosition() );
				$index -= $tagLen;
				$messPom = substr $messPom, 0, length($messPom) - $tagLen;

				my $img = ( grep { $_->[0] eq $imgNumber } @{ $self->{"images"} } )[0];
				die "Image number: $imgNumber was not found in imamge collection" unless ( defined $img );

				$richTxt->WriteImage( $img->[1], $img->[2] );
			}

		}

		#$richTxt->WriteText( $messages[$i] );

		if ( $i + 1 != scalar(@messages) ) {
			$richTxt->BeginFontSize(1);

			$richTxt->WriteText("\n");

			#			$richTxt->WriteText('\n');
			$index++;

			#			$index++;
			$richTxt->BeginFontSize(10.5);
		}

		#}
	}

	$richTxt->Thaw();

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

		$button->SetFocus() if ( $i == scalar(@buttons) - 1 );    # focus on right button

		$szBtnsChild->Add( $button, 0, &Wx::wxALL, 1 );

		Wx::Event::EVT_BUTTON( $button, -1, sub { __OnClick( $self, $button ) } );

	}

}

sub __OnClick {

	my ( $self, $button ) = @_;

	#$parent->{"result"} = $button->{"order"};
	#$self->Destroy();

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
