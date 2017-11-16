
#-------------------------------------------------------------------------------------------#
# Description: Contain helper function for polzgon created from list of points
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Polygon::PolygonAttr;

#3th party library
use strict;
use warnings;
use Math::ConvexHull qw/convex_hull/;
use Math::Polygon::Calc;       #Math-Polygon
use Math::Geometry::Planar;    #Math-Geometry-Planar-GPC
use Math::Trig;
use Math::Trig ':pi';
use Math::Polygon;

#local library
use aliased 'Packages::Polygon::Enums';
use aliased 'Packages::Polygon::Polygon::PolygonArc';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
# Add geometric attributes to line
# param $edge is hash ref:
# x1 => start point x
# y1 => start point y
# x2 => end point x
# y2 => end point y
sub AddLineAtt {
	my $self = shift;
	my $edge = shift;
 

	#distance between points at line

	$edge->{"length"} =
	  sqrt( ( $edge->{"x1"} - $edge->{"x2"} )**2 + ( $edge->{"y2"} - $edge->{"y1"} )**2 );

}

# Add geometric attributes to arc
# param $edge is hash ref:
# x1 => start point x
# y1 => start point y
# x2 => end point x
# y2 => end point y
# xmid => center point x of arc
# ymid => center point x of arc
# dir => CW/CCW
sub AddArcAtt {
	my $self = shift;
	my $edge = shift;

	#distance of start/end point
	$edge->{"distance"} =
	  sqrt( ( $edge->{"x1"} - $edge->{"x2"} )**2 + ( $edge->{"y2"} - $edge->{"y1"} )**2 );

	#size of diameter
	$edge->{"diameter"} = 2 * sqrt( ( $edge->{"xmid"} - $edge->{"x2"} )**2 + ( $edge->{"y2"} - $edge->{"ymid"} )**2 );

	$edge->{"radius"}    = $edge->{"diameter"} / 2;
	$edge->{"perimeter"} = 2 * pi * $edge->{"radius"};

	#test if center point of arc lay on right or left from line (position = sign( (Bx-Ax)*(Y-Ay) - (By-Ay)*(X-Ax) ))
	# when positive = lay on left, when negative = lay on right

	#compute length of arc
	$edge->{"innerangle"} = PolygonArc->GetArcInnerAngle($edge);
	$edge->{"length"} =
	  deg2rad( $edge->{"innerangle"} ) * $edge->{"radius"};    #compute length of arc
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

