
#-------------------------------------------------------------------------------------------#
# Description: Contain helper function for polzgon created from list of points
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::PointsTransform;

#3th party library
use strict;
use warnings;
use Math::ConvexHull qw/convex_hull/;
use Math::Polygon::Calc;       #Math-Polygon
use Math::Geometry::Planar;    #Math-Geometry-Planar-GPC
use Math::Trig;
use Math::Trig ':pi';

#local library
use aliased 'Packages::Polygon::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Ruction rotate point by specific angle
# Point is rotated around zero (0,0)
sub RotatePoint {
	my $self   = shift;
	my %p      = %{ shift(@_) };                     # for accurate calculation give in µm
	my $angle  = shift;
	my $dir    = shift // Enums->Dir_CCW;
	my $origin = shift // { "x" => 0, "y" => 0 };    # for accurate calculation give in µm

	die "Angle ($angle) is less than 0" if ( $angle < 0 );

	if ( $dir eq Enums->Dir_CW ) {
		$angle = 360 - $angle;
	}

	my $s = sin( deg2rad($angle) );
	my $c = cos( deg2rad($angle) );

	# translate point back to origin:
	$p{"x"} -= $origin->{"x"};
	$p{"y"} -= $origin->{"y"};

	# rotate point
	my $xnew = $p{"x"} * $c - $p{"y"} * $s;
	my $ynew = $p{"x"} * $s + $p{"y"} * $c;

	# translate point back:
	$p{"x"} = $xnew + $origin->{"x"};
	$p{"y"} = $ynew + $origin->{"y"};

	return %p;
}

# Return limits of all features
# Consider only lines, arc start + end points
sub GetLimByPoints {
	my $self   = shift;
	my @points = @{ shift(@_) };

	my %dim = ();

	if ( scalar(@points) > 0 ) {

		my $minX;
		my $minY;
		my $maxX;
		my $maxY;

		foreach my $f (@points) {

			# find minimum
			if ( !defined $minX || $f->{"x"} < $minX ) {

				$minX = $f->{"x"};
			}

			if ( !defined $minY || $f->{"y"} < $minY ) {

				$minY = $f->{"y"};
			}

			#find maximum
			if ( !defined $maxX || $f->{"x"} > $maxX ) {

				$maxX = $f->{"x"};
			}

			if ( !defined $maxY || $f->{"y"} > $maxY ) {

				$maxY = $f->{"y"};
			}
		}

		$dim{"xMin"} = $minX;
		$dim{"xMax"} = $maxX;
		$dim{"yMin"} = $minY;
		$dim{"yMax"} = $maxY;
	}

	return %dim;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased "Packages::Polygon::Polygon::PolygonPoints";

	my @points2 = ( [ 0, 0 ], [ 0, 5 ], [ 5, 5 ], [ 5, 0 ] );

	my @points = ( [ 4.50644, 69.2869675 ], [ 5.08195, 69.4691725 ], [ 5.08195, 68.4691725 ], [ 3.7708175, 68.3225475 ], [ 2.7708175, 71.3225475 ] );

	#print PolygonHelper->GetPoly2PolyIntersect( \@points, \@points2);

	#     #OB 4.50644 69.2869675 I
	#     #OC 5.08195 69.4691725 5.08195 68.4691725 Y
	#     #OS 11.42517 69.4691725
	#     #OC 12.42517 68.4691725 11.42517 68.4691725 Y
	#     #OS 12.42517 62.4371725
	#     #OC 11.42517 61.4371725 11.42517 62.4371725 Y
	#     #OS 4.7708175 61.4371725
	#     #OC 3.7708175 62.4371725 4.7708175 62.4371725 Y
	#     #OS 3.7708175 68.3225475
	#     #OC 4.50644 69.2869675 4.7708175 68.3225475 Y
	#     #OE
	#     #OB 5.7708175 63.4371725 H
	#     #OS 10.42517 63.4371725
	#     #OS 10.42517 67.4691725
	#     #OS 5.7708175 67.4691725
	#     #OS 5.7708175 63.4371725

}

1;

