#-------------------------------------------------------------------------------------------#
# Description: Widget can show task item result.
# Three ways how to set behaviour, when click on widget:
# 1) Set handler OnClick
# 2) Create menu Errro|IndicatorMenu
# 3) Set ResultManager - then widget shows items from manager
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Widgets::Forms::ErrorIndicator::ErrorIndicator;
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
use aliased 'Widgets::Forms::ErrorIndicator::ErrorIndicatorMenu';
use aliased 'Managers::MessageMngr::MessageMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ 30, 20 ] );

	bless($self);

	$self->{"mode"}    = shift;
	$self->{"size"}    = shift;
	$self->{"showCnt"} = shift;

	$self->{"jobId"}      = shift;
	$self->{"resultMngr"} = shift;
	$self->{"errCnt"}     = 0;

	unless ( $self->{"showCnt"} ) {
		$self->{"showCnt"} = 1;
	}

	$self->{"menu"} = undef;

	$self->{"messageMngr"} = MessageMngr->new( $self->{"jobId"} );

	# EVENTS

	$self->{"onClick"} = Event->new();

	$self->__SetLayout();

	return $self;
}

sub AddMenu {
	my $self = shift;

	my $menu = ErrorIndicatorMenu->new( -1, $self->{"mode"}, $self->{"messageMngr"} );
	$self->{"menu"} = $menu;

}

sub AddMenuItem {
	my $self       = shift;
	my $title      = shift;
	my $resultMngr = shift;

	if ( $self->{"menu"} ) {

		$self->{"menu"}->AddItem( $title, $resultMngr, );
	}
}

sub SetErrorCnt {
	my $self = shift;
	my $cnt  = shift;

	$self->{"errCnt"} = $cnt;
	$self->{"cntValTxt"}->SetLabel( $self->{"errCnt"} );

	if ( $self->{"errCnt"} > 0 ) {

		my $err = Wx::Bitmap->new( $self->{"pathEnable"}, &Wx::wxBITMAP_TYPE_PNG );
		$self->{"statBtmError"}->SetBitmap($err);

	}

	$self->{"szMain"}->Layout();
}

sub __SetLayout {
	my $self = shift;

	# size in px
	Wx::InitAllImageHandlers();
	my $size = $self->{"size"} . "x" . $self->{"size"};

	# Decide which picture show
	if ( $self->{"mode"} eq EnumsGeneral->MessageType_ERROR ) {

		$self->{"pathDisable"} = GeneralHelper->Root() . "/Resources/Images/ErrorDisable" . $size . ".png";
		$self->{"pathEnable"}  = GeneralHelper->Root() . "/Resources/Images/Error" . $size . ".png";

	}
	elsif ( $self->{"mode"} eq EnumsGeneral->MessageType_WARNING ) {
		$self->{"pathDisable"} = GeneralHelper->Root() . "/Resources/Images/WarningDisable" . $size . ".png";
		$self->{"pathEnable"}  = GeneralHelper->Root() . "/Resources/Images/Warning" . $size . ".png";

	}

	#define panels

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $cntValTxt = Wx::StaticText->new( $self, -1, "0" );
	$cntValTxt->SetFont($Widgets::Style::fontLbl);
	my $btmError = Wx::Bitmap->new( $self->{"pathDisable"}, &Wx::wxBITMAP_TYPE_PNG );
	my $statBtmError = Wx::StaticBitmap->new( $self, -1, $btmError );

	# SET EVENTS
	Wx::Event::EVT_LEFT_DOWN( $self,         sub { $self->__Click(@_) } );
	Wx::Event::EVT_LEFT_DOWN( $cntValTxt,    sub { $self->__Click(@_) } );
	Wx::Event::EVT_LEFT_DOWN( $statBtmError, sub { $self->__Click(@_) } );

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( 1, 20, 1, &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALL, 0 );
	$szMain->Add( $cntValTxt, 0, &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALL, 0 );
	$szMain->Add( $statBtmError, 0, &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxEXPAND | &Wx::wxLEFT, 1 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"szMain"}       = $szMain;
	$self->{"cntValTxt"}    = $cntValTxt;
	$self->{"statBtmError"} = $statBtmError;

}

# Three different behaviour can happen
sub __Click {
	my $self = shift;

	# if handler is defined, raise event
	if ( $self->{"onClick"}->Handlers() ) {
		$self->{"onClick"}->Do();

	}

	# if menu was created, show menu
	elsif ( $self->{"menu"} ) {

		$self->{"menu"}->ShowMenu();

	}

	#if result manager was passed, show medssage
	elsif ( $self->{"resultMngr"} ) {

		my $str = "";
		my $cnt = 0;
		if ( $self->{"mode"} eq EnumsGeneral->MessageType_ERROR ) {

			$str = $self->{"resultMngr"}->GetErrorsStr();
			$cnt = $self->{"resultMngr"}->GetErrorsCnt();
		}
		elsif ( $self->{"mode"} eq EnumsGeneral->MessageType_WARNING ) {

			$str = $self->{"resultMngr"}->GetWarningsStr();
			$cnt = $self->{"resultMngr"}->GetWarningsCnt();

		}

		if ( $cnt > 0 ) {
			my @mess = ();
			push( @mess, $str );

			$self->{"messageMngr"}->ShowModal( -1, $self->{"mode"}, \@mess );

		}

	}

}

1;
