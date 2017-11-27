
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

	die "x1 key is not defined in line hash" unless ( defined $edge->{"x1"} );
	die "x2 key is not defined in line hash" unless ( defined $edge->{"x2"} );
	die "y1 key is not defined in line hash" unless ( defined $edge->{"y1"} );
	die "y2 key is not defined in line hash" unless ( defined $edge->{"y2"} );

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
	my $arc  = shift;

	die "x1 key is not defined in arc hash"   unless ( defined $arc->{"x1"} );
	die "x2 key is not defined in arc hash"   unless ( defined $arc->{"x2"} );
	die "y1 key is not defined in arc hash"   unless ( defined $arc->{"y1"} );
	die "y2 key is not defined in arc hash"   unless ( defined $arc->{"y2"} );
	die "xmid key is not defined in arc hash" unless ( defined $arc->{"xmid"} );
	die "ymid key is not defined in arc hash" unless ( defined $arc->{"ymid"} );
	die "dir key is not defined in arc hash"  unless ( defined $arc->{"dir"} );

	#distance of start/end point
	$arc->{"distance"} =
	  sqrt( ( $arc->{"x1"} - $arc->{"x2"} )**2 + ( $arc->{"y2"} - $arc->{"y1"} )**2 );

	#size of diameter
	$arc->{"diameter"} = 2 * sqrt( ( $arc->{"xmid"} - $arc->{"x2"} )**2 + ( $arc->{"y2"} - $arc->{"ymid"} )**2 );

	$arc->{"radius"}    = $arc->{"diameter"} / 2;
	$arc->{"perimeter"} = 2 * pi * $arc->{"radius"};

	#test if center point of arc lay on right or left from line (position = sign( (Bx-Ax)*(Y-Ay) - (By-Ay)*(X-Ax) ))
	# when positive = lay on left, when negative = lay on right

	#compute length of arc
	$arc->{"innerangle"} = PolygonArc->GetArcInnerAngle($arc);
	$arc->{"length"} =
	  deg2rad( $arc->{"innerangle"}, 1 ) * $arc->{"radius"};    #compute length of arc, 1 means - when 360 circle it returns 2Pi
}

# Add geometric attributes to line
# param $edge is hash ref:
# surfaces => array of surfaces (same structure like when Features.pm class is used)
# circle => 1/0
sub AddSurfAtt {
	my $self = shift;
	my $surf = shift;

	die "surfaces key is not defined in hash" unless ( defined $surf->{"surfaces"} );

	foreach my $surfIsland ( @{ $surf->{"surfaces"} } ) {

		if ( $surfIsland->{"circle"} ) {

			my $sP1 = $surfIsland->{"island"}->[0];
			my $sP2 = $surfIsland->{"island"}->[1];

			$surfIsland->{"xmid"} = $sP2->{"xmid"};
			$surfIsland->{"ymid"} = $sP2->{"ymid"};

			# create arc structure to get surface radius
			my %arc = (
						"x1"   => $sP1->{"x"},
						"y1"   => $sP1->{"y"},
						"x2"   => $sP1->{"x"},
						"y2"   => $sP1->{"y"},
						"xmid" => $sP2->{"xmid"},
						"ymid" => $sP2->{"ymid"},
						"dir"  => "CW"
			);

			$self->AddArcAtt( \%arc );
			$surfIsland->{"radius"} = $arc{"radius"};

		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

