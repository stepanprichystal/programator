
#-------------------------------------------------------------------------------------------#
# Description: Custom queue list. Keep items of type MyWxCustomQueueItem
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Stencil::StencilDrawing;
use base('Widgets::Forms::SimpleDrawing::SimpleDrawing');

#3th party library
use Wx;
use strict;
use warnings;
use List::Util qw[min max];

#local library
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class     = shift;
	my $parent    = shift;
	my $dimension = shift;

	my $self = $class->SUPER::new( $parent, $dimension );

	bless($self);

	# Items references
	$self->__SetLayout();

	my %drawData = ();
	$self->{"drawData"} = \%drawData;
	
	$self->{"drawData"}->{"topPcb"} = 0;

	#Wx::Event::EVT_PAINT($self,\&paint);

	#EVENTS
	#$self->{"onSelectItemChange"} = Event->new();

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

sub SetStencilSize {
	my $self   = shift;
	my $width  = shift;
	my $height = shift;

	$self->{"drawData"}->{"width"}  = $width;
	$self->{"drawData"}->{"height"} = $height;

	$self->Refresh();
}

sub SetTopPcbPos {
	my $self   = shift;
	my $startX = shift;
	my $startY = shift;
	my $endX   = shift;
	my $endY   = shift;

	my %topPcb = ();

	$self->{"drawData"}->{"topPcb"} = \%topPcb;

	$self->{"drawData"}->{"topPcb"}->{"startX"} = $startX;
	$self->{"drawData"}->{"topPcb"}->{"startY"} = $startY;
	$self->{"drawData"}->{"topPcb"}->{"endX"}   = $endX;
	$self->{"drawData"}->{"topPcb"}->{"endY"}   = $endY;

	$self->Refresh();
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	# Set drawing background

	my $backgClr = Wx::Colour->new( 250, 250, 250 );
	my $backgBrush = Wx::Brush->new( Wx::Colour->new( 200, 200, 200 ), &Wx::wxBRUSHSTYLE_CROSS_HATCH  );
	$self->SetBackgroundBrush( $backgClr, $backgBrush );

	# Create layers

	# --- Stencil dimension ---
	my $stencilDim = $self->AddLayer( "stencilDim", sub { $self->__DrawStencilDim(@_) } );
	$stencilDim->SetBrush( Wx::Brush->new( 'green', &Wx::wxBRUSHSTYLE_TRANSPARENT  ) );

	# --- Top pcb ---
	my $topPcb = $self->AddLayer( "topPcb", sub { $self->__DrawTopPcb(@_) } );
	$topPcb->SetBrush( Wx::Brush->new( 'red', &Wx::wxBRUSHSTYLE_BDIAGONAL_HATCH ) );

}

sub __DrawStencilDim {
	my $self = shift;
	my $dc = shift;

	my $l = $self->GetLayer("stencilDim");

	#$l->{"DC"}->Clear();
	$l->DrawRectangle( $dc, 10, 10, $self->{"drawData"}->{"width"}, $self->{"drawData"}->{"height"} );

}

sub __DrawTopPcb {
	my $self = shift;
	my $dc = shift;

	unless($self->{"drawData"}->{"topPcb"}){
		return 0;
	}

	my $l = $self->GetLayer("topPcb");

	#$l->{"DC"}->Clear();
	$l->DrawRectangle($dc,  $self->{"drawData"}->{"topPcb"}->{"startX"}, $self->{"drawData"}->{"topPcb"}->{"startY"},
					   $self->{"drawData"}->{"topPcb"}->{"endX"},   $self->{"drawData"}->{"topPcb"}->{"endY"} );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
