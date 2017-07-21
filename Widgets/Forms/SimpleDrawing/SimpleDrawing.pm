
use Wx;

#-------------------------------------------------------------------------------------------#
# Description: Custom queue list. Keep items of type MyWxCustomQueueItem
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::SimpleDrawing::SimpleDrawing;
use base qw(Wx::Panel);

#3th party library
use Wx;
use strict;
use warnings;
use List::Util qw[min max];

#local library
use aliased 'Widgets::Forms::MyWxScrollPanel';
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::SimpleDrawing::DrawLayer';
use aliased 'Widgets::Forms::SimpleDrawing::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class     = shift;
	my $parent    = shift;
	my $dimension = shift;

	my $self = $class->SUPER::new( $parent, -1, &Wx::wxDefaultPosition, $dimension );

	bless($self);

	# Items references
	$self->__SetLayout();

	my @layers = ();
	$self->{"layers"}    = \@layers;
	$self->{"realScale"} = 1;

	#$self->{"backgroundDC"} = Wx::ClientDC->new($self);
	$self->{"width"}  = ( @{$dimension} )[0];
	$self->{"height"} = ( @{$dimension} )[1];

	$self->{"axisOrient"} = Enums->Axis_LEFTBOT;
	my %origin = ( "x" => 0, "y" => 0 );
	$self->{"origin"} = \%origin;

	Wx::Event::EVT_PAINT( $self, sub { $self->__Paint(@_) } );

	#EVENTS
	#$self->{"onSelectItemChange"} = Event->new();

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

sub SetOrigin {
	my $self = shift;
	my $x    = shift;
	my $y    = shift;

	$self->{"origin"}->{"x"} = $x;
	$self->{"origin"}->{"y"} = $y;
}

# Example, scale "2" means, all values are multiply by 2. Line 10px long will by drawed like 100px long
sub SetScale {
	my $self  = shift;
	my $scale = shift;

	$self->{"scale"} = shift;
}

# Real scale is value, which all coordinate are multiply,
# when whole image is supposed to by visible in drawing panel
sub __CompAutoZoomScale {
	my $self = shift;
	my $dc   = shift;

	my $canvH = $self->GetSize()->GetHeight();
	my $canvW = $self->GetSize()->GetWidth();
	
	print STDERR "Canvas wxh: $canvW x $canvH\n";

	my $minX = $dc->MinX();
	my $maxX = $dc->MaxX();

	my $minY = $dc->MinY();
	my $maxY = $dc->MaxY();

	# compute real scale
	my $wDraw = abs( min( 0, $minX ) ) + $maxX;
	my $hDraw = abs( min( 0, $minY ) ) + $maxY;

	my $newScale = 1;

	# need compute new scale in order drawin will be whole visible in frame
	if ( $wDraw > 0 && $hDraw > 0 ) {

		# Zoom out
		if ( $wDraw > $canvW || $hDraw > $canvH ) {

			# choose axis, which need more shrink
			if ( $canvW / $wDraw < $canvH / $hDraw ) {

				$newScale = $canvW / $wDraw;
			}
			else {
				$newScale = $canvH / $hDraw;
			}

		}

		# Zoom in
		elsif ( $wDraw < $canvW && $hDraw < $canvH ) {

			# choose axis, can zoom out less
			if ( $wDraw / $canvW > $wDraw / $canvH ) {

				$newScale =  $canvW / ($wDraw*1.2) ; # 1.2 because we don't want zoom close to canvas border
			}
			else {
				$newScale =  $canvH / ($hDraw*1.2) ;
			}
		}
	}

	# reser real scale
	$self->{"realScale"} = 1;

	# compute new real scale
	if ( $newScale != 1 ) {
		$self->{"realScale"} *= $newScale;
		print STDERR "Auto ZOOM new scale: $newScale\n";
	}

}

sub AddLayer {
	my $self = shift;

	my $drawSub = shift;

	#	if ( defined $self->{"layers"}->{"$name"} ) {
	#		die "Layer with name: $name, aleready exists.\n";
	#	}

	push( @{ $self->{"layers"} }, DrawLayer->new( $self, $drawSub ) );

}
#
#sub GetLayer {
#	my $self = shift;
#	my $name = shift;
#
#	my $l = $self->{"layers"}->{"$name"};
#
#	unless ( defined $l ) {
#		die "Layer with name: $l, doesn't exists.\n";
#	}
#
#	return $l;
#}

sub SetBackgroundBrush {
	my $self  = shift;
	my $color = shift;
	my $brush = shift;

	$self->{"backgClr"}   = $color;
	$self->{"backgBrush"} = $brush;

	#$self->SetBackgroundColour($color);    #green
	#$self->Refresh();

	#my $dcb = Wx::WindowDC->new($self);
	#$dcb->SetBackground(Wx::Brush->new(Wx::Colour->new( 20, 235, 235 ), &Wx::wxBRUSHSTYLE_CROSSDIAG_HATCH  ));

}

sub RefreshDrawing {
	my $self = shift;

	$self->{"autoZoom"} = 1;
	$self->Refresh();    # By  calling refresh on panel, "Paint event is raised"

}

sub __Paint {
	my $self = shift;

	my $dc = Wx::PaintDC->new($self);

	my $dcH = $self->GetSize()->GetHeight();

	if ( $self->{"axisOrient"} eq Enums->Axis_LEFTBOT ) {

		$dc->SetAxisOrientation( 1, 1 );
		$dc->SetDeviceOrigin( 0, $dcH );

		if ( $self->{"origin"} ) {

			$dc->SetDeviceOrigin( $self->{"origin"}->{"x"}, $dcH - $self->{"origin"}->{"y"} );
		}
	}
	elsif ( $self->{"axisOrient"} eq Enums->Axis_LEFTTOP ) {

		$dc->SetAxisOrientation( 1, 0 );

		if ( $self->{"origin"} ) {

			$dc->SetDeviceOrigin( $self->{"origin"}->{"x"}, $self->{"origin"}->{"y"} );
		}
	}
 


	if ( !$self->{"autoZoom"} ) {

		$dc->SetUserScale( $self->{"realScale"}, $self->{"realScale"} );

		$dc->SetBrush( $self->{"backgBrush"} );
		$dc->DrawRectangle( -1000, -1000, 10000, 10000 );
	}

	# $dc->SetBrush( Wx::Brush->new( 'red', &Wx::wxBRUSHSTYLE_BDIAGONAL_HATCH ));
	# $dc->DrawRectangle( 0, 0, 300, 500 );

	#$dc->SetBrush(Wx::Brush->new('red', &Wx::wxBRUSHSTYLE_CROSSDIAG_HATCH  ));
	#my $dcb = Wx::ClientDC->new($self->{"drawingPnl"});
	#$dc->SetBackground(Wx::Brush->new('red', 115  ));
	#$dc->Clear();

	foreach ( @{ $self->{"layers"} } ) {

		$_->{"drawSub"}->($dc);
	}

	if ( $self->{"autoZoom"} ) {

		$self->__CompAutoZoomScale($dc);
		$self->{"autoZoom"} = 0;
		$self->Refresh();

	}

	#	if ( $self->{"autoZoom"} ) {
	#
	#		$self->{"autoZoom"} = 0;
	#
	#		if ( $self->__NeedReDraw($dc) ) {
	#			print "REdraw\n";
	#		}
	#		else {
	#			print "NO-REdraw\n";
	#		}
	#
	#	}
	#	else {
	#
	#	}

}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	#$self->SetBackgroundStyle( $brush );    #green

	# EVENTS

	Wx::Event::EVT_MOUSEWHEEL( $self, sub { $self->__OnMouseWheel(@_) } );

}

sub __OnMouseWheel {
	my $self = shift;
	my $w    = shift;
	my $evt  = shift;

	print "Rotation:" . $evt->GetWheelRotation() . "\n";
	print "Delta:" . $evt->GetWheelDelta() . "\n";

	if ( $evt->GetWheelRotation() > 0 ) {
		$self->{"realScale"} *= 1.1;
	}
	else {
		$self->{"realScale"} /= 1.1;
	}

	print STDERR "real scale:" . $self->{"realScale"} . "\n";

	$self->Refresh();

}

sub __NeedReDraw {
	my $self = shift;
	my $dc   = shift;

	# Get teal scale
	$self->__CompRealScale($dc);

	if ( $self->{"scale"} != $self->{"realScale"} ) {

		print STDERR "New scale: " . $self->{"realScale"} . "\n";

		$self->Refresh();

		#$self->__ZoomDrawing( $real, $dc );
		return 1;

	}
	else {
		return 0;
	}

}

sub __ZoomDrawing {
	my $self  = shift;
	my $scale = shift;
	my $dc    = shift;

	$dc->SetUserScale( $scale, $scale );
	$self->Refresh();

	#$self->Layout();

	#
	#	foreach ( keys %{ $self->{"layers"} } ) {
	#
	#		my $dc = $self->{"layers"}->{$_}->{"DC"};
	#
	#		$dc->SetUserScale($scale, $scale);
	#		$self->Refresh();
	#		$self->Layout();
	#	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

