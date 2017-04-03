#-------------------------------------------------------------------------------------------#
# Description: Helper class, whic work with lines, vectors, position of point/lines
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutMath::RoutMath;

#3th party library
use strict;
use warnings;
use Math::Trig;
use Math::Polygon::Calc;       #Math-Polygon
use Math::Geometry::Planar;    #Math-Geometry-Planar-GPC
use Math::Vec qw(NewVec);

#local library

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

#return position of point with line left/right
sub PosOfPoint {
	my $self   = shift;
	my $pointX = shift;
	my $pointY = shift;
	my $x1     = shift;
	my $y1     = shift;
	my $x2     = shift;
	my $y2     = shift;

	return ( ( $x2 - $x1 ) * ( $pointY - $y1 ) - ( $y2 - $y1 ) * ( $pointX - $x1 ) ) > 0
	  ? "left"
	  : "right";
}

#return position of point with line left/right
sub VectorInnerEdge {
	my $self = shift;

	#before lvector
	my $x1 = shift;
	my $y1 = shift;

	#next vector
	my $x2 = shift;
	my $y2 = shift;

	my $origin = NewVec( 0, 0, 0 );
	my ( $vBef, $vNext ) = ( 0, 0 );
	my $angel      = 0;
	my $posOfPoint = 0;

	$vBef  = NewVec( $x1, $y1, 0 );
	$vNext = NewVec( $x2, $y2, 0 );

	$posOfPoint =
	  $self->PosOfPoint( 0, 0, @{$vBef}[0], @{$vBef}[1], @{$vNext}[0], @{$vNext}[1] );
	$angel = rad2deg( $origin->InnerAnglePoints( $vBef, $vNext ) );

	if ( $posOfPoint eq "right" ) {
		return $angel;
	}
	else {
		return 360 - $angel;
	}
}

#test id two lines are parallel
sub LinesAreParallel {
	my $self       = shift;
	my %lineBefore = %{ shift(@_) };
	my %lineNext   = %{ shift(@_) };

	#Are paralel
	my $paralel = 0;

	if ( sprintf( "%.1f", abs( $lineBefore{"x2"} - $lineBefore{"x1"} ) ) == 0 ) {
		if ( sprintf( "%.1f", abs( $lineNext{"x2"} - $lineNext{"x1"} ) ) == 0 ) {
			$paralel = 1;
		}
	}

	if ( sprintf( "%.1f", abs( $lineBefore{"y2"} - $lineBefore{"y1"} ) ) == 0 ) {
		if ( sprintf( "%.1f", abs( $lineNext{"y2"} - $lineNext{"y1"} ) ) == 0 ) {
			$paralel = 1;
		}
	}

	if ( sprintf( "%.1f", abs( $lineBefore{"x2"} - $lineBefore{"x1"} ) ) > 0 ) {
		if ( sprintf( "%.1f", abs( $lineNext{"x2"} - $lineNext{"x1"} ) ) > 0 ) {

			#directive of line 1
			my $sl1 = ( $lineBefore{"y2"} - $lineBefore{"y1"} ) / ( $lineBefore{"x2"} - $lineBefore{"x1"} );

			#directive of line 2
			my $sl2 = ( $lineNext{"y2"} - $lineNext{"y1"} ) / ( $lineNext{"x2"} - $lineNext{"x1"} );

			#test on equals +- 20% tolerance

			if ( $sl1 < 0 && $sl2 < 0 ) {
				$sl1 = abs($sl1);
				$sl2 = abs($sl2);
			}

			if ( $sl1 * 1.2 >= $sl2 && $sl1 * 0.8 <= $sl2 ) {
				$paralel = 1;
			}
		}
	}

	return $paralel;

}

1;

