#-------------------------------------------------------------------------------------------#
# Description: Class can rotate rout chain, than do some modification and rotate it back
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutStart::RoutRotation;

#3th party library
use strict;
use warnings;
use XML::Simple;
use Math::Trig ':pi';

#local library
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutTransform';
use aliased 'Packages::Polygon::PolygonFeatures';
use aliased 'Packages::Polygon::PointsTransform';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"features"} = shift;

	$self->{"routMoved"}  = undef;
	$self->{"routMovedX"} = undef;
	$self->{"routMovedY"} = undef;

	$self->{"rotateAngle"} = undef;

	#get limits of rout chain by points
	my @points = ();
	foreach my $f ( @{ $self->{"features"} } ) {
		my %p1 = ( "x" => $f->{"x1"}, "y" => $f->{"y1"} );
		my %p2 = ( "x" => $f->{"x2"}, "y" => $f->{"y2"} );
		push( @points, ( \%p1, \%p2 ) );
	}

	my %lim = PointsTransform->GetLimByPoints( \@points );

	$self->{"lim"} = \%lim;

	$self->__Init();

	return $self;
}

sub Rotate {
	my $self  = shift;
	my $angle = shift;    # rotate counter clockwise
	my $draw  = shift;

	if ( $angle % 90 > 1 ) {
		die "Angle value is wrong. Only increments of 90deg are possible.\n";
	}

	$self->__Init();

	#my $clockWise = shift;

	$self->{"rotateAngle"} = $angle;

	# 1) test if features are in zero

	if ( $self->{"lim"}->{"xMin"} != 0 || $self->{"lim"}->{"yMin"} != 0 ) {

		$self->{"routMoved"}  = 1;
		$self->{"routMovedX"} = $self->{"lim"}->{"xMin"};
		$self->{"routMovedY"} = $self->{"lim"}->{"yMin"};

		RoutTransform->MoveRout( -$self->{"routMovedX"}, -$self->{"routMovedY"}, $self->{"features"} );
	}

	# 2) rotate
	my $angle90 = 90;
	my $num     = $angle / $angle90;

	# Pcb widtt /height
	my $width  = abs( $self->{"lim"}->{"xMax"} - $self->{"lim"}->{"xMin"} );
	my $height = abs( $self->{"lim"}->{"yMax"} - $self->{"lim"}->{"yMin"} );

	# only if angel is not 360
	if ( $num < 4 ) {
		for ( my $i = 0 ; $i < $num ; $i++ ) {

			RoutTransform->RotateRout( $angle90, $self->{"features"} );

			#$draw->DrawRoute($self->{"features"});

			if ( $i % 2 == 0 ) {

				RoutTransform->MoveRout( $height, 0, $self->{"features"} );
			}
			else {

				RoutTransform->MoveRout( $width, 0, $self->{"features"} );
			}

			#$draw->DrawRoute($self->{"features"});

		}
	}
}

sub RotateBack {
	my $self = shift;

	# 2) rotate

	my $angle = 360 - $self->{"rotateAngle"};    # rotate  clockwise

	my $angle90 = 90;
	my $num     = $angle / $angle90;

	# Pcb widtt /height
	my $width  = abs( $self->{"lim"}->{"xMax"} - $self->{"lim"}->{"xMin"} );
	my $height = abs( $self->{"lim"}->{"yMax"} - $self->{"lim"}->{"yMin"} );

	# switch height and width
	if ( $num % 2 != 0 ) {
		my $tmp = $width;
		$width  = $height;
		$height = $tmp;
	}

	# only if angel is not 360
	if ( $num < 4 ) {
		for ( my $i = 0 ; $i < $num ; $i++ ) {

			RoutTransform->RotateRout( $angle90, $self->{"features"} );

			if ( $i % 2 == 0 ) {

				RoutTransform->MoveRout( $height, 0, $self->{"features"} );
			}
			else {

				RoutTransform->MoveRout( $width, 0, $self->{"features"} );
			}
		}
	}

	# 1) test if features was moved to zero

	if ( $self->{"routMoved"} ) {

		RoutTransform->MoveRout( $self->{"routMovedX"}, $self->{"routMovedY"}, $self->{"features"} );
	}

}

sub __Init {
	my $self = shift;

	$self->{"routMoved"}  = 0;
	$self->{"routMovedX"} = 0;
	$self->{"routMovedY"} = 0;

	$self->{"rotateAngle"} = 0

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

