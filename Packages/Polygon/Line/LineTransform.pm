
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
	 
  
	my $angle1 =
	  rad2deg( atan2( $L1EndPoint{"y"} , $L1EndPoint{"x"}  ) )
	  ;                               #angle of point given by start point and x coordinate above line x
	my $angle2 =
	  rad2deg( atan2( $L2EndPoint{"y"} , $L2EndPoint{"x"}  ) )
	  ;  
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
	my %rotLineP1 = ("x" => $startP->{"x"}, "y" => $startP->{"y"} );
	my %rotLineP2 = ("x" => $startP->{"x"} + $length, "y" => $startP->{"y"} );
	
	# Move by given distance in y axis
	$dist *=-1 if($side eq "right");
	
	$rotLineP1{"y"} += $dist;
	$rotLineP2{"y"} += $dist;
	
	# 3) Rotate back
	
	%rotLineP1 = PointsTransform->RotatePoint( \%rotLineP1, $innerAngle, Enums->Dir_CCW, {"x" => $startP->{"x"}, "y" => $startP->{"y"} } );
	%rotLineP2 = PointsTransform->RotatePoint( \%rotLineP2, $innerAngle, Enums->Dir_CCW, {"x" => $startP->{"x"}, "y" => $startP->{"y"} } );
 
	return (\%rotLineP1, \%rotLineP2);

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

	print SegmentLineIntersection->doIntersect( \%p1, \%q1, \%p2, \%q2 );

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

