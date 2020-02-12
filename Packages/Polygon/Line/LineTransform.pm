
#-------------------------------------------------------------------------------------------#
# Description: Parallel lines and other line operation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Line::LineTransform;

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
use aliased 'Packages::Polygon::PointsTransform';
use aliased 'Packages::Polygon::Enums';
use aliased 'Packages::Polygon::Line::SegmentLineIntersection';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Create parralel segment line (in 2D) to specified line in specific distance
# Line input line can be arbitrary rotated
sub ParallelSegmentLine {
	my $self   = shift;
	my $startP = shift;
	my $endP   = shift;
	my $dist   = shift;

	# left/right. Parralel line is created on the left or right from given line according segment line direction
	my $side = shift // "left";

	my $length = sqrt( ( $startP->{"x"} - $endP->{"x"} )**2 + ( $endP->{"y"} - $startP->{"y"} )**2 );

	# 1) Compute inner angle between current line and line which go through start point and is parralel with "x" axis

	# my edge
	my $moveX = $startP->{"x"};
	my $moveY = $startP->{"y"};

	# 1st line end point. Move line to [0,0]
	my %L2EndPoint = %{$endP};
	$L2EndPoint{"x"} -= $moveX;
	$L2EndPoint{"y"} -= $moveY;

	# 2nd line end point
	my %L1EndPoint = ();
	$L1EndPoint{"x"} = $length;
	$L1EndPoint{"y"} = 0;

	my $angle1 = rad2deg( atan2( $L1EndPoint{"y"}, $L1EndPoint{"x"} ) );    #angle of point given by start point and x coordinate above line x
	my $angle2 = rad2deg( atan2( $L2EndPoint{"y"}, $L2EndPoint{"x"} ) );
	my $innerAngle;
	my $sign = 1;

	#computation length of actual arc
	#test if both points are "above/under/ above and under" line x
	$sign = $sign * -1 if ( $angle2 * $angle1 > 0 );

	if ( $angle2 > $angle1 ) {
		$innerAngle = abs( abs($angle1) + $sign * abs($angle2) );
	}
	else {
		$innerAngle = 360 - abs( abs($angle1) + $sign * abs($angle2) );
	}

	# 2) Rotate current line to origin position (origin is start point) to "x" axis
	my %rotLineP1 = ( "x" => $startP->{"x"}, "y" => $startP->{"y"} );
	my %rotLineP2 = ( "x" => $startP->{"x"} + $length, "y" => $startP->{"y"} );

	# Move by given distance in y axis
	$dist *= -1 if ( $side eq "right" );

	$rotLineP1{"y"} += $dist;
	$rotLineP2{"y"} += $dist;

	# 3) Rotate back

	%rotLineP1 = PointsTransform->RotatePoint( \%rotLineP1, $innerAngle, Enums->Dir_CCW, { "x" => $startP->{"x"}, "y" => $startP->{"y"} } );
	%rotLineP2 = PointsTransform->RotatePoint( \%rotLineP2, $innerAngle, Enums->Dir_CCW, { "x" => $startP->{"x"}, "y" => $startP->{"y"} } );

	return ( \%rotLineP1, \%rotLineP2 );

}

# Get vetical segment line which go from starting point of segment
# Length of parallel segment is given by $len
# Vertical line is created on the left of original line (in ori line direction from pStart to pEnd)
sub GetVerticalSegmentLine {
	my $self   = shift;
	my $pStart = shift;
	my $pEnd   = shift;
	my $len    = shift;
	my $side   = shift // "left";    # left/right side of original line which vericall line will be created on
 
	my $x1 = $pStart->{"x"};
	my $y1 = $pStart->{"y"};
	my $x2 = $pEnd->{"x"};
	my $y2 = $pEnd->{"y"};

	my $x2res;
	my $y2res;

	# Exceptions

	if ( $x1 == $x2 ) {
		my $dir = $y1 < $y2 ? 1 : -1;
		$dir *= -1 if ( $side eq "right" );
		$x2res = $x1 - $dir * $len;
		$y2res = $y1;

	}
	elsif ( $y1 == $y2 ) {
		my $dir = $x1 < $x2 ? 1 : -1;
		$dir *= -1 if ( $side eq "right" );
		$x2res = $x1;
		$y2res = $y1 + $dir * $len;
	}
	else {

		my $c;

		my @nVec = ( ( $x2 - $x1 ), ( $y2 - $y1 ) );

		my $c2 = -( $nVec[0] * $x1 ) - ( $nVec[1] * $y1 );

		#second point We take second x similar to x1 (e.g x1 + 1)

		$y2res = -( $nVec[0] * $x2res ) / $nVec[1] - $c2 / $nVec[1];

		# Now we have perpendicular segment line, find entersection of this line and lien parallel to source line at distance $len
		my $oriLineP1 = { "x" => $x1, "y" => $y1 };
		my $oriLineP2 = { "x" => $x2, "y" => $y2 };

		my @res = $self->ParallelSegmentLine( $oriLineP1, $oriLineP2, $len, $side );

		my $oriLineParalelP1 = $res[0];
		my $oriLineParalelP2 = $res[1];

		# perpendicular line
		my $perpendLineP1 = { "x" => $x1,    "y" => $y1 };
		my $perpendLineP2 = { "x" => $x2res, "y" => $y2res };

		my %i = SegmentLineIntersection->GetLineIntersection( $oriLineParalelP1, $oriLineParalelP2, $perpendLineP1, $perpendLineP2 );
		$x2res = $i{"x"};
		$y2res = $i{"y"};
	}

	return ( "x" => $x2res, "y" => $y2res );

}

# Extend line in line direction by given distance
# Line input line can be arbitrary rotated
# Return only computed point
sub ExtendSegmentLine {
	my $self   = shift;
	my $startP = shift;
	my $endP   = shift;
	my $dist   = shift;

	# A-----------B------------C
	#(Xa,Ya)     (Xb,Yb)      (Xc,Yc)
	#Now the distances:

	my $Xa = $startP->{"x"};
	my $Ya = $startP->{"y"};

	my $Xb = $endP->{"x"};
	my $Yb = $endP->{"y"};

	my $AB = sqrt( ( $Xb - $Xa ) * ( $Xb - $Xa ) + ( $Yb - $Ya ) * ( $Yb - $Ya ) );
	my $AC = -$dist;

	#Cross-multiply to get Xc:

	#AB -> Xb - Xa
	#AC -> Xc - Xa
 
	my $Xc = $Xa + ( $AC * ( $Xb - $Xa ) / $AB );
	my $Yc = $Ya + ( $AC * ( $Yb - $Ya ) / $AB );

	return {"x" => $Xc, "y" => $Yc };
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Polygon::Line::SegmentLineIntersection';

	my %p1 = ( "x" => 1,  "y" => 1 );
	my %q1 = ( "x" => 10, "y" => 1 );
	my %p2 = ( "x" => 8,  "y" => 1 );
	my %q2 = ( "x" => 20, "y" => 1 );

	print SegmentLineIntersection->GetVerticalSegmentLine( \%p1, \%q1, \%p2, \%q2 );

	#	$p1 = {10, 0}, $q1 = {0, 10};
	#	$p2 = {0, 0}, $q2 = {10, 10};
	#	domyersect($p1, $q1, $p2, $q2)? cout << "Yes\n": cout << "No\n";
	#
	#	$p1 = {-5, -5}, $q1 = {0, 0};
	#	$p2 = {1, 1}, $q2 = {10, 10};
	#	domyersect($p1, $q1, $p2, $q2)? cout << "Yes\n": cout << "No\n";
	#
	#	return 0;

}

1;

