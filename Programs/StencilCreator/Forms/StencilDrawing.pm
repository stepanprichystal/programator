
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
use aliased 'Widgets::Forms::SimpleDrawing::Enums';

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
	$self->{"data"} = \%drawData;
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
	my $self   = shift;
	my $newData  = shift;
	 
	$self->{"data"} = $newData;
 
	$self->RefreshDrawing();
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
	
	$self->SetOrigin(20, 20);

	my $backgClr = Wx::Colour->new( 252, 252, 252 );
	my $backgBrush = Wx::Brush->new( Wx::Colour->new( 235, 235, 235 ), &Wx::wxBRUSHSTYLE_CROSS_HATCH );
	$self->SetBackgroundBrush( $backgClr, $backgBrush );

	# Create layers

	# --- Stencil dimension ---
	my $stencilDim = $self->AddLayer( "stencilDim", sub { $self->__DrawStencilDim(@_) } );
	$stencilDim->SetBrush( Wx::Brush->new( 'green', &Wx::wxBRUSHSTYLE_TRANSPARENT ) );

	# --- Top pcb ---
	my $topPcb = $self->AddLayer( "topPcb", sub { $self->__DrawTopPcb(@_) } );
	$topPcb->SetBrush( Wx::Brush->new( 'red', &Wx::wxBRUSHSTYLE_BDIAGONAL_HATCH ) );
	
	

}

sub __DrawStencilDim {
	my $self = shift;
	my $dc   = shift;

	my $l = $self->GetLayer("stencilDim");

	#$l->{"DC"}->Clear();
 
	$l->DrawRectangle( $dc, 0, 0, $self->{"data"}->{"width"}, $self->{"data"}->{"height"} );

}

sub __DrawTopPcb {
	my $self = shift;
	my $dc   = shift;

	my $d = $self->{"data"}->{"topPcb"};

	unless ( $d->{"exists"}) {
		return 0;
	}

	my $l = $self->GetLayer("topPcb");
 
	$l->DrawRectangle( $dc,
					   $d->{"posX"},
					   $d->{"posY"},
					   $d->{"posX"} + $d->{"width"},
					   $d->{"posY"} + $d->{"height"});

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
