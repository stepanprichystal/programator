
#-------------------------------------------------------------------------------------------#
# Description: Contain helper function working with arc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Polygon::PolygonArc;

#3th party library
use strict;
use warnings;
use Math::ConvexHull qw/convex_hull/;
use Math::Polygon::Calc;       #Math-Polygon
use Math::Geometry::Planar;    #Math-Geometry-Planar-GPC
use Math::Trig;
use Math::Trig ':pi';
use Math::Polygon;
use POSIX 'floor';

#local library
use aliased 'Packages::Polygon::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
# Return array of points created by aproximation of arc
# param $arc is hash ref:
# x1 => start point x
# y1 => start point y
# x2 => end point x
# y2 => end point y
# xmid => center point x of arc
# ymid => center point x of arc
# dir => CW/CCW
# suppose arc have all attributes get by function PolygonAtr::AddArcAtt
sub GetFragmentArc {
	my $self     = shift;
	my $arc      = shift(@_);
	my $accuracy = shift;       # number of segments
	my $result   = shift;

	die "x1 key is not defined in arc hash"   unless ( defined $arc->{"x1"} );
	die "x2 key is not defined in arc hash"   unless ( defined $arc->{"x2"} );
	die "y1 key is not defined in arc hash"   unless ( defined $arc->{"y1"} );
	die "y2 key is not defined in arc hash"   unless ( defined $arc->{"y2"} );
	die "xmid key is not defined in arc hash" unless ( defined $arc->{"xmid"} );
	die "ymid key is not defined in arc hash" unless ( defined $arc->{"ymid"} );
	die "dir key is not defined in arc hash"  unless ( defined $arc->{"dir"} );

	$$result = 1;
	my $points;

	# compute sehment count by accuracy
	my $segLength = $self->GetSegmentLength( $arc->{"radius"}, $accuracy );

	my $segCntCircle = floor( $arc->{"perimeter"} / $segLength );
	my $segCntArc    = floor( $arc->{"length"} / $arc->{"perimeter"} * $segCntCircle );

	my @arrStart  = ( $arc->{"x1"},   $arc->{"y1"} );
	my @arrEnd    = ( $arc->{"x2"},   $arc->{"y2"} );
	my @arrCenter = ( $arc->{"xmid"}, $arc->{"ymid"} );
	my $direction = $arc->{"dir"};

	if ( $arc->{"x1"} == $arc->{"x2"} && $arc->{"y1"} == $arc->{"y2"} ) {

		$points = CircleToPoly( $segCntCircle, \@arrCenter, \@arrStart );

		my @arr = @{ $points->{"points"} };
		push( @arr, $arr[0] );

		#CircleToPoly return points as CWW, so we've to consider original direction from genesis
		if ( $arc->{"dir"} eq "CW" ) {
			@arr = reverse @arr;
		}

		return @arr;
	}

	#	my $segCnt =
	#	  floor( ( $arc->{"length"} / $arc->{"perimeter"} ) * $segNumber );    #number of segment for arc

	#oblouk se nebude delit
	if ( $segCntArc < 2 ) {
		$$result = 0;
		return 0;
	}

	$points = ArcToPoly( $segCntArc, \@arrCenter, \@arrStart, \@arrEnd, ( $direction eq "CW" ) ? 1 : 0 );

	return @{$points};
}

# Compute inner agle of arc
# param $arc is hash ref:
# x1 => start point x
# y1 => start point y
# x2 => end point x
# y2 => end point y
# xmid => center point x of arc
# ymid => center point x of arc
# dir => CW/CCW
# suppose arc have all attributes get by function PolygonAtr::AddArcAtt
sub GetArcInnerAngle {
	my $self = shift;
	my $arc  = shift(@_);
	
	die "x1 key is not defined in arc hash"   unless ( defined $arc->{"x1"} );
	die "x2 key is not defined in arc hash"   unless ( defined $arc->{"x2"} );
	die "y1 key is not defined in arc hash"   unless ( defined $arc->{"y1"} );
	die "y2 key is not defined in arc hash"   unless ( defined $arc->{"y2"} );
	die "xmid key is not defined in arc hash" unless ( defined $arc->{"xmid"} );
	die "ymid key is not defined in arc hash" unless ( defined $arc->{"ymid"} );
	die "dir key is not defined in arc hash"  unless ( defined $arc->{"dir"} );

	my @arrStart  = ( $arc->{"x1"},   $arc->{"y1"} );
	my @arrEnd    = ( $arc->{"x2"},   $arc->{"y2"} );
	my @arrCenter = ( $arc->{"xmid"}, $arc->{"ymid"} );
	my $direction = $arc->{"dir"};

	my $r = $arc->{"diameter"} / 2;
	my $o = 2 * pi * $r;              #perimeter of  whole circle
	                                  #lines returned after segmentation

	my $angle1 =
	  rad2deg( atan2( $arc->{"y1"} - $arc->{"ymid"}, $arc->{"x1"} - $arc->{"xmid"} ) )
	  ;                               #angle of point given by start point and x coordinate above line x
	my $angle2 =
	  rad2deg( atan2( $arc->{"y2"} - $arc->{"ymid"}, $arc->{"x2"} - $arc->{"xmid"} ) )
	  ;                               #angle of point given by end point and x coordinate under line x

	my $alfa;
	my $sign = 1;

	#computation length of actual arc
	#test if both points are "above/under/ above and under" line x
	if ( $angle2 * $angle1 > 0 ) {
		$sign = $sign * -1;

		#print "Stejna znamenka\n";
	}
	else {

		#print "Ruzna znamenka\n";
	}

	if ( $direction eq "CW" ) {
		if ( $angle1 > $angle2 ) {
			$alfa = abs( abs($angle1) + $sign * abs($angle2) );
		}
		else {
			$alfa = 360 - abs( abs($angle1) + $sign * abs($angle2) );
		}
	}
	else {

		if ( $angle2 > $angle1 ) {
			$alfa = abs( abs($angle1) + $sign * abs($angle2) );
		}
		else {
			$alfa = 360 - abs( abs($angle1) + $sign * abs($angle2) );
		}
	}

	return $alfa;
}

# If circle/arc aproximation is needed, function return length of segment
# depand on given "accurate"
# Eg.: if accurate is 1mm, line approximation distance won't be more than 1mm from arc/circle
sub GetSegmentLength {
	my $self     = shift;
	my $r = shift;
	my $accurate = shift;
	
	if($r<$accurate ){
		return $r;
	}

	my $x1 = -$r;
	my $y1 = $r - $accurate;

	my $x2 = +$r;
	my $y2 = $r - $accurate;

	my $dx = $x2 - $x1;
	my $dy = $y2 - $y1;

	my $dr = sqrt( $dx * $dx + $dy * $dy );

	my $D = $x1 * $y1 - $x2 * $y2;

	my $xRes1 = ( $D * $dy - ( $dy < 0 ? -1 : 1 ) * $dx * sqrt( $r * $r * $dr * $dr - $D * $D ) ) / ( $dr * $dr );
	my $xRes2 = ( $D * $dy + ( $dy < 0 ? -1 : 1 ) * $dx * sqrt( $r * $r * $dr * $dr - $D * $D ) ) / ( $dr * $dr );

	my $segLen = abs( $xRes2 - $xRes1 );

	return $segLen;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased "Packages::Polygon::Polygon::PolygonPoints";
	#
	#	my @points1 = ( [0,0], [0,5], [5,5], [5,0] );
	#
	#	my @points2 = ( [0,0], [0.2,2], [0,5], [5,5], [5,0] );
	#
	#	#print PolygonHelper->GetPoly2PolyIntersect( \@points, \@points2);
	#
	#	my $p = PolygonPoints->PolygonAreEqual( \@points1, \@points2);
	#
	#	print "ddd";
	#
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

