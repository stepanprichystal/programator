
#-------------------------------------------------------------------------------------------#
# Description: check if two given line segments myersect
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Line::SegmentLineIntersection;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Return intersection point of two lines whioch go through specified points
sub GetLineIntersection {
	my $self = shift;
	my $p1   = shift;    # start poin line 1
	my $p2   = shift;    # end poin line 1
	my $q1   = shift;    # start poin line 2
	my $q2   = shift;    # end poin line 2

	my %intersect = ("x" => undef, "y" => undef);

	my $x1 = $p1->{"x"};
	my $y1 = $p1->{"y"};
	my $x2 = $p2->{"x"};
	my $y2 = $p2->{"y"};
	my $x3 = $q1->{"x"};
	my $y3 = $q1->{"y"};
	my $x4 = $q2->{"x"};
	my $y4 = $q2->{"y"};

	my $a1    = $y2 - $y1;
	my $b1    = $x1 - $x2;
	my $c1    = $a1 * $x1 + $b1 * $y1;
	my $a2    = $y4 - $y3;
	my $b2    = $x3 - $x4;
	my $c2    = $a2 * $x3 + $b2 * $y3;
	my $delta = $a1 * $b2 - $a2 * $b1;
	
	return %intersect if $delta == 0;

	# If delta is 0, i.e. lines are parallel then the below will fail
	my $ix = ( $b2 * $c1 - $b1 * $c2 ) / $delta;
	my $iy = ( $a1 * $c2 - $a2 * $c1 ) / $delta;
	
	$intersect{"x"} = $ix;
	$intersect{"y"} = $iy;
	
	return %intersect;
}

# Return value greater than 1 if there is intersection
# This is intersection of line (not segment line)
sub SegLineIntersection {
	my $self = shift;
	my $p1   = shift;
	my $q1   = shift;
	my $p2   = shift;
	my $q2   = shift;

	# Find the four __Orientations needed for general and
	# special cases
	my $o1 = $self->__Orientation( $p1, $q1, $p2 );
	my $o2 = $self->__Orientation( $p1, $q1, $q2 );
	my $o3 = $self->__Orientation( $p2, $q2, $p1 );
	my $o4 = $self->__Orientation( $p2, $q2, $q1 );

	# General case
	return 1 if ( $o1 != $o2 && $o3 != $o4 );

	# Special Cases
	# $p1, $q1 and $p2 are colinear and $p2 lies on segment $p1$q1
	return 1 if ( $o1 == 0 && $self->__OnSegment( $p1, $p2, $q1 ) );

	# $p1, $q1 and $q2 are colinear and $q2 lies on segment $p1$q1
	return 2 if ( $o2 == 0 && $self->__OnSegment( $p1, $q2, $q1 ) );

	# $p2, $q2 and $p1 are colinear and $p1 lies on segment $p2$q2
	return 3 if ( $o3 == 0 && $self->__OnSegment( $p2, $p1, $q2 ) );

	# $p2, $q2 and $q1 are colinear and $q1 lies on segment $p2$q2
	return 4 if ( $o4 == 0 && $self->__OnSegment( $p2, $q1, $q2 ) );

	return 0;    # Doesn't fall in any of the above cases
}

# Given three colinear pomys p, q, r, the function checks if
# pomy q lies on line segment 'pr'
sub __OnSegment {
	my $self = shift;
	my $p    = shift;
	my $q    = shift;
	my $r    = shift;

	return 1
	  if (    $q->{"x"} <= max( $p->{"x"}, $r->{"x"} )
		   && $q->{"x"} >= min( $p->{"x"}, $r->{"x"} )
		   && $q->{"y"} <= max( $p->{"y"}, $r->{"y"} )
		   && $q->{"y"} >= min( $p->{"y"}, $r->{"y"} ) );

	return 0;
}

# To find __Orientation of ordered triplet (p, q, r).
# The function returns following $values
# 0 --> p, q and r are colinear
# 1 --> Clockwise
# 2 --> Counterclockwise
sub __Orientation {
	my $self = shift;
	my $p    = shift;
	my $q    = shift;
	my $r    = shift;

	# See https:#www.geeksforgeeks.org/__Orientation-3-ordered-pomys/
	# for details of below formula.
	my $val = ( $q->{"y"} - $p->{"y"} ) * ( $r->{"x"} - $q->{"x"} ) - ( $q->{"x"} - $p->{"x"} ) * ( $r->{"y"} - $q->{"y"} );

	return 0 if ( $val == 0 );    # colinear

	return ( $val > 0 ) ? 1 : 2;  # clock or counterclock wise
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

