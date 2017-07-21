
#-------------------------------------------------------------------------------------------#
# Description: Custom queue list. Keep items of type MyWxCustomQueueItem
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Forms::StencilDrawing;
use base('Widgets::Forms::SimpleDrawing::SimpleDrawing');

#3th party library
use Wx;
use strict;
use warnings;
use List::Util qw[min max];

#local library
use aliased 'Packages::Events::Event';
use aliased 'Programs::StencilCreator::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class      = shift;
	my $parent     = shift;
	my $dimension  = shift;
	my $layoutMngr = shift;

	my $self = $class->SUPER::new( $parent, $dimension );

	bless($self);

	# Items references
	$self->__SetLayout();

	$self->{"layoutMngr"} = $layoutMngr;

	#$self->{"data"}->{"topPcb"} = 0;

	#Wx::Event::EVT_PAINT($self,\&paint);

	#EVENTS
	#$self->{"onSelectItemChange"} = Event->new();

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

sub DataChanged {
	my $self = shift;
	my $autoZoom = shift;

	$self->RefreshDrawing($autoZoom);
}

#sub SetTopPcbPos {
#	my $self   = shift;
#	my $startX = shift;
#	my $startY = shift;
#	my $endX   = shift;
#	my $endY   = shift;
#
#	my %topPcb = ();
#
#	$self->{"data"}->{"topPcb"} = \%topPcb;
#
#	$self->{"data"}->{"topPcb"}->{"startX"} = $startX;
#	$self->{"data"}->{"topPcb"}->{"startY"} = $startY;
#	$self->{"data"}->{"topPcb"}->{"endX"}   = $endX;
#	$self->{"data"}->{"topPcb"}->{"endY"}   = $endY;
#
#	$self->RefreshDrawing();
#}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# Set drawing background

	$self->SetOrigin( 20, 20 );

	my $backgClr = Wx::Colour->new( 252, 252, 252 );
	my $backgBrush = Wx::Brush->new( Wx::Colour->new( 235, 235, 235 ), &Wx::wxBRUSHSTYLE_CROSS_HATCH );
	$self->SetBackgroundBrush( $backgClr, $backgBrush );

	# Create layers

	# --- Stencil dimension ---
	my $stencilDim = $self->AddLayer( sub { $self->__DrawStencilDim(@_) } );

	# --- Top pcb ---
	my $topPcb = $self->AddLayer( sub { $self->__DrawTopPcb(@_) } );

	# --- Bot pcb ---
	my $botPcb = $self->AddLayer( sub { $self->__DrawBotPcb(@_) } );

	# --- Job id ---
	$self->AddLayer( sub { $self->__DrawJobId(@_) } );

	# --- Schema ---
	$self->AddLayer( sub { $self->__DrawSchema(@_) } );

}

sub __DrawStencilDim {
	my $self = shift;
	my $dc   = shift;

	if ( !defined $self->{"layoutMngr"}->GetWidth() || !defined $self->{"layoutMngr"}->GetHeight() ) {
		return 0;
	}

	$dc->SetBrush( Wx::Brush->new( 'black', &Wx::wxBRUSHSTYLE_TRANSPARENT ) );

	$dc->DrawRectangle( 0, 0, $self->{"layoutMngr"}->GetWidth(), $self->{"layoutMngr"}->GetHeight() );

}

sub __DrawJobId {
	my $self = shift;
	my $dc   = shift;

	$dc->SetBrush( Wx::Brush->new( 'black', &Wx::wxBRUSHSTYLE_TRANSPARENT ) );

	$dc->SetFont( Wx::Font->new( 7, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL ) );

	my $text = "";
	my $st   = $self->{"layoutMngr"}->GetStencilType();

	if ( $st eq Enums->StencilType_TOP || $st eq Enums->StencilType_TOPBOT ) {

		$dc->DrawText( "X00000", 15, 12 );
	}
	elsif ( $st eq Enums->StencilType_BOT ) {

		$dc->DrawText( "00000X", $self->{"layoutMngr"}->GetWidth() - 40, 12 );
	}

}

sub __DrawTopPcb {
	my $self = shift;
	my $dc   = shift;

	my $st = $self->{"layoutMngr"}->GetStencilType();

	if ( $st ne Enums->StencilType_TOP && $st ne Enums->StencilType_TOPBOT ) {
		return 0;
	}

	# 1) Draw profile
	my $topProf    = $self->{"layoutMngr"}->GetTopProfile();
	my %topProfPos = $self->{"layoutMngr"}->GetTopProfilePos();

	$dc->SetPen( Wx::Pen->new( 'red', 1, &Wx::wxPENSTYLE_SOLID ) );
	$dc->SetBrush( Wx::Brush->new( 'red', &Wx::wxBRUSHSTYLE_BDIAGONAL_HATCH ) );
	$dc->DrawRectangle( $topProfPos{"x"}, $topProfPos{"y"}, $topProf->GetWidth(), $topProf->GetHeight() );

	# 2) Draf limits of paste data
	my $pdOri = $topProf->GetPDOrigin();

	$dc->SetPen( Wx::Pen->new( 'gray', 1, &Wx::wxPENSTYLE_LONG_DASH ) );
	$dc->SetBrush( Wx::Brush->new( 'gray', &Wx::wxBRUSHSTYLE_TRANSPARENT ) );    # &Wx::wxBRUSHSTYLE_TRANSPARENT

	$dc->DrawRectangle( $topProfPos{"x"} + $pdOri->{"x"},     $topProfPos{"y"} + $pdOri->{"y"},
						$topProf->GetPasteData()->GetWidth(), $topProf->GetPasteData()->GetHeight() );
}

sub __DrawBotPcb {
	my $self = shift;
	my $dc   = shift;

	my $st = $self->{"layoutMngr"}->GetStencilType();

	if ( $st ne Enums->StencilType_BOT && $st ne Enums->StencilType_TOPBOT ) {
		return 0;
	}

	# 1) Draw profile
	my $botProf    = $self->{"layoutMngr"}->GetBotProfile();
	my %botProfPos = $self->{"layoutMngr"}->GetBotProfilePos();

	$dc->SetPen( Wx::Pen->new( 'blue', 1, &Wx::wxPENSTYLE_SOLID ) );
	$dc->SetBrush( Wx::Brush->new( 'blue', &Wx::wxBRUSHSTYLE_FDIAGONAL_HATCH ) );
	$dc->DrawRectangle( $botProfPos{"x"}, $botProfPos{"y"}, $botProf->GetWidth(), $botProf->GetHeight() );

	# 2) Draf limits of paste data
	my $pdOri = $botProf->GetPDOrigin();

	$dc->SetPen( Wx::Pen->new( 'gray', 1, &Wx::wxPENSTYLE_LONG_DASH ) );
	$dc->SetBrush( Wx::Brush->new( 'gray', &Wx::wxBRUSHSTYLE_TRANSPARENT ) );    # &Wx::wxBRUSHSTYLE_TRANSPARENT

	$dc->DrawRectangle( $botProfPos{"x"} + $pdOri->{"x"},     $botProfPos{"y"} + $pdOri->{"y"},
						$botProf->GetPasteData()->GetWidth(), $botProf->GetPasteData()->GetHeight() );
}

sub __DrawSchema {
	my $self = shift;
	my $dc   = shift;

	my $sch = $self->{"layoutMngr"}->GetSchema();

	if ( $sch->GetSchemaType() ne Enums->Schema_STANDARD ) {
		return 0;
	}
 
	$dc->SetPen( Wx::Pen->new( 'black', 1, &Wx::wxPENSTYLE_SOLID ) );
	$dc->SetBrush( Wx::Brush->new( 'black', &Wx::wxBRUSHSTYLE_TRANSPARENT ) );    # &Wx::wxBRUSHSTYLE_TRANSPARENT
 
	my $d = $sch->GetHoleSize();

	foreach ( $sch->GetHolePositions() ) {

		$dc->DrawCircle( $_->{"x"}, $_->{"y"}, $d / 2 );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
