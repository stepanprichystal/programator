#-------------------------------------------------------------------------------------------#
# Description: Menu widget, which can appear in ErrorIndicator widget
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::ErrorIndicator::ErrorIndicatorMenu;
use base ('Wx::Dialog');

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library

use aliased 'Widgets::Forms::MyWxFrame';
use Widgets::Style;
use aliased 'Programs::Exporter::ExportChecker::Enums';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class       = shift;
	my $parent      = shift;
	my $mode        = shift;
	my $messageMngr = shift;

	if ( defined $parent && $parent == -1 ) {
		$parent = undef;
	}

	my $self = $class->SUPER::new( $parent, -1, "", [ -1, -1 ], [ -1, -1 ], &Wx::wxSTAY_ON_TOP );

	bless($self);

	$self->{"mode"} = $mode;
	$self->__SetLayout();

	# Properties
	my %items = ();
	$self->{"items"} = \%items;

	$self->{"messageMngr"} = $messageMngr;

	return $self;
}

sub ShowMenu {
	my $self  = shift;
	my $point = Wx::GetMousePosition();


	$self->Move($point);

	$self->__RefreshMenu();
	$self->ShowModal();

}


sub AddItem {
	my $self = shift;

	my $title      = shift;
	my $resultMngr = shift;    # ref on function, which return itemresults

	my $parent = $self->{"itemPnl"};

	my $cnt = 0;

 

	# DEFINE SIZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $btnError = Wx::Button->new( $parent, -1, $title, &Wx::wxDefaultPosition, [ 140, 25 ] );

	#my $errorCntTxt = Wx::StaticText->new( $parent, -1, $cnt, &Wx::wxDefaultPosition, [ 25, 20 ] );

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $btnError, 1, &Wx::wxALL, 0 );

	 

	# REGISTER EVENTS

	Wx::Event::EVT_BUTTON( $btnError, -1, sub { $self->__OnClick($resultMngr) } );

	$self->{"szRow2"}->Add( $szMain, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$self->{"szMain"}->Layout();

	$self->SetSize( $self->GetBestSize() );

	# save item
	my %itemInfo = ();

	#$itemInfo{"text"}          = $errorCntTxt;
	$itemInfo{"title"}         = $title;
	$itemInfo{"resultMngr"}    = $resultMngr;
	$itemInfo{"button"}        = $btnError;
	$self->{"items"}->{$title} = \%itemInfo;

	return $szMain;
}

sub __SetLayout {
	my $self = shift;

	Wx::InitAllImageHandlers();

	my $itemPnl = Wx::Panel->new( $self, -1 );
	$itemPnl->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );
	$self->SetBackgroundColour( Wx::Colour->new( 240, 240, 240 ) );

	my $title = "";
	if ( $self->{"mode"} eq EnumsGeneral->MessageType_ERROR ) {

		$self->{"path"} = GeneralHelper->Root() . "/Resources/Images/Error15x15.png";
		$title = "Errors";
	}
	elsif ( $self->{"mode"} eq EnumsGeneral->MessageType_WARNING ) {
		$self->{"path"} = GeneralHelper->Root() . "/Resources/Images/Warning15x15.png";
		$title = "Warnings";

	}

	# DEFINE SIZERS

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#$pnlBtns->SetBackgroundColour($Widgets::Style::clrDefaultFrm);

	# DEFINE CONTROLS

	my $btmError = Wx::Bitmap->new( $self->{"path"}, &Wx::wxBITMAP_TYPE_PNG );
	my $statBtmError = Wx::StaticBitmap->new( $self, -1, $btmError );

	my $titleTxt = Wx::StaticText->new( $self, -1, $title );

	# BUILD STRUCTURE OF LAYOUT

	$itemPnl->SetSizer($szRow2);

	$szRow1->Add( $statBtmError, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szRow1->Add( $titleTxt,     0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$szMain->Add( $szRow1,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $itemPnl, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	# REGISTER EVENTS

	$self->SetSizer($szMain);

	$self->{"itemPnl"} = $itemPnl;

	# SAVE NECESSARY CONTROLS
	$self->{"szRow2"} = $szRow2;
	$self->{"szMain"} = $szMain;

}



sub __RefreshMenu {
	my $self = shift;

	my %items = %{ $self->{"items"} };

	foreach my $k ( keys %items ) {

		my %itemInfo = %{ $items{$k} };

		my $cnt = 0;

		if ( $self->{"mode"} eq EnumsGeneral->MessageType_ERROR ) {

			$cnt = $itemInfo{"resultMngr"}->GetErrorsCnt();
		}
		elsif ( $self->{"mode"} eq EnumsGeneral->MessageType_WARNING ) {

			$cnt = $itemInfo{"resultMngr"}->GetWarningsCnt();

		}

		#$itemInfo{"text"}->SetLabel($cnt);

		my $text = $itemInfo{"title"};
		$text .= "  (" . $cnt . ")";
		$itemInfo{"button"}->SetLabel($text);

	}

}

sub __OnClick {
	my $self       = shift;
	my $resultMngr = shift;
 
	my $cnt = 0;

		my $str = "";
		 
		if ( $self->{"mode"} eq EnumsGeneral->MessageType_ERROR ) {


			$str = $resultMngr->GetErrorsStr(1);
			$cnt = $resultMngr->GetErrorsCnt();
		}
		elsif ( $self->{"mode"} eq EnumsGeneral->MessageType_WARNING ) {

			$str = $resultMngr->GetWarningsStr(1);
			$cnt = $resultMngr->GetWarningsCnt();

		}

	$self->Hide();

	if ( $cnt > 0 ) {
		my @mess = ();
		push( @mess, $str );

		

		$self->{"messageMngr"}->ShowModal( -1, $self->{"mode"}, \@mess );
		print "Count is $cnt\n";
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = Programs::Exporter::ExportUtility::ExportUtility::Forms::ErrorIndicatorMenu->new( undef, "f13608", EnumsGeneral->MessageType_WARNING );
	#use aliased 'Packages::ItemResult::ItemResultMngr';

	#my $mngr  = ItemResultMngr->new();
	#my $mngr1 = ItemResultMngr->new();

	#$test->AddItem( "test",  $mngr );
	#$test->AddItem( "test2", $mngr1 );

	#$test->MainLoop();
}

 

1;

