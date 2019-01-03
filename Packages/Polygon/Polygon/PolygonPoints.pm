
#-------------------------------------------------------------------------------------------#
# Description: Contain helper function for polzgon created from list of points
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Polygon::PolygonPoints;

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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Return polygon direction CW/CCW
# Features must be sorted
sub GetPolygonDirection {
	my $self = shift;

	my @poly = @{ shift(@_) };

	push( @poly, $poly[0] );

	if ( polygon_is_clockwise(@poly) ) {
		return Enums->Dir_CW;
	}
	else {
		return Enums->Dir_CCW;
	}
}

# Test intersection between poly1 and poly2
# Return  Pos_INSIDE/Pos_OUTSIDE/Pos_INTERSECT
# - Pos_INSIDE: poly1 is whole inside poly2
# - Pos_OUTSIDE: poly1 is whole outside poly2
# - Pos_INTERSECT: poly1 intersect with poly2
# if point of poly2 lay on polygon border, it is considered as INSIDE point
# IMPORTANT NOTE: This works only if polygons are convex!!
sub GetPoly2PolyIntersect {
	my $self  = shift;
	my @poly1 = @{ shift(@_) };    # array of array refs, where first cell is "x" val, sexond is "y" val
	my @poly2 = @{ shift(@_) };    # array of array refs, where first cell is "x" val, sexond is "y" val

	my $inPoint  = 0;
	my $outPoint = 0;

	my $polygon = Math::Geometry::Planar->new();
	$polygon->points( \@poly2 );

	for ( my $i = 0 ; $i < scalar(@poly1) ; $i++ ) {

		my $p = $poly1[$i];

		if ( $polygon->isinside($p) ) {
			$inPoint++;
		}
		else {
			$outPoint++;
		}
	}

	my $pos = undef;

	if ( $inPoint && !$outPoint ) {
		$pos = Enums->Pos_INSIDE;
	}
	elsif ( !$inPoint && $outPoint ) {
		$pos = Enums->Pos_OUTSIDE;
	}
	else {
		$pos = Enums->Pos_INTERSECT;
	}

	return $pos;
}

# Test intersection between polygon and segment line
# Return  Pos_INSIDE/Pos_OUTSIDE/Pos_INTERSECT
# - Pos_INSIDE: line is whole inside polygon
# - Pos_OUTSIDE: line is whole outside of polygon
# - Pos_INTERSECT: line intersect polygon
# if point of line lay on polygon border, it is considered as INSIDE point
# IMPORTANT NOTE: This works only if polygons are convex!!
sub GetPoly2SegmentLineIntersect {
	my $self   = shift;
	my @poly   = @{ shift(@_) };    # array of array refs, where first cell is "x" val, sexond is "y" val
	my $startP = shift;             # start point, array refs where first cell is "x" val, sexond is "y" val
	my $endP   = shift;             # end point, array refs where first cell is "x" val, sexond is "y" val

	my $inPoint  = 0;
	my $outPoint = 0;

	my $polygon = Math::Geometry::Planar->new();
	$polygon->points( \@poly );

	 foreach my $p  (($startP, $endP)){
  
		if ( $polygon->isinside($p) ) {
			$inPoint++;
		}
		else {
			$outPoint++;
		}
	}

	my $pos = undef;

	if ( $inPoint && !$outPoint ) {
		$pos = Enums->Pos_INSIDE;
	}
	elsif ( !$inPoint && $outPoint ) {
		$pos = Enums->Pos_OUTSIDE;
	}
	else {
		$pos = Enums->Pos_INTERSECT;
	}

	return $pos;
}

# Return if points are inside polz
sub GetPoints2PolygonPosition {
	my $self   = shift;
	my @points = @{ shift(@_) };
	my @poly   = @{ shift(@_) };

	my $inside  = 0;
	my $outside = 0;

	my $polygon = Math::Geometry::Planar->new();
	$polygon->points( \@poly );

	for ( my $i = 0 ; $i < scalar(@points) ; $i++ ) {

		my $p = $points[$i];

		if ( $polygon->isinside($p) ) {
			$inside = 1;

		}
		else {
			$outside = 1;
		}
	}

	my $pos = undef;

	if ( $inside && !$outside ) {
		$pos = Enums->Pos_INSIDE;
	}
	elsif ( !$inside && $outside ) {
		$pos = Enums->Pos_OUTSIDE;
	}
	else {
		$pos = Enums->Pos_INSIDEOUTSIDE;
	}

	return $pos;
}

# Return envelop "convex hull" for points
sub GetConvexHull {
	my $self   = shift;
	my @points = @{ shift(@_) };

	my $hull_array_ref = convex_hull( \@points );

	return @{$hull_array_ref};
}

# Return center of polygon
sub GetCentroid {
	my $self   = shift;
	my @points = @{ shift(@_) };

	my $point = undef;
	if ( scalar(@points) > 2 ) {

		my $polygon = Math::Geometry::Planar->new();
		$polygon->points( \@points );
		$point = $polygon->centroid();

	}
	else {
		$point = $points[0];
	}

	return $point;
}

# Get polygon area
sub GetPolygonArea {
	my $self    = shift;
	my @points1 = @{ shift(@_) };

	push( @points1, $points1[0] );

	my $poly1 = Math::Polygon->new(@points1);

	return $poly1->area();
}

# Get limits by points
sub GetPolygonLim {
	my $self    = shift;
	my @points1 = @{ shift(@_) };

	my $poly1 = Math::Polygon->new(@points1);

	my @box = $poly1->bbox();

	return @box;
}

sub GetPolygonDim {
	my $self    = shift;
	my @points1 = @{ shift(@_) };

	my @box = $self->GetPolygonLim( \@points1 );

	my %inf = ();

	$inf{"w"} = abs( $box[0] - $box[2] );
	$inf{"h"} = abs( $box[1] - $box[3] );

	return %inf;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased "Packages::Polygon::Polygon::PolygonPoints";

	my @points1 = ( [ 0, 0 ], [ 0, 5 ], [ 5, 5 ], [ 5, 0 ] );

	my @points2 = ( [ 0, 0 ], [ 0.2, 2 ], [ 0, 5 ], [ 5, 5 ], [ 5, 0 ] );

	#print PolygonHelper->GetPoly2PolyIntersect( \@points, \@points2);

	my $p = PolygonPoints->PolygonAreEqual( \@points1, \@points2 );

	print "ddd";

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

