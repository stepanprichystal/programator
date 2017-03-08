
#-------------------------------------------------------------------------------------------#
# Description: Contain helper function with polygons created from features
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::PolygonFeatures;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Polygon::Enums';
use aliased 'Math::Geometry::Planar';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub GetDimByRectangle {
	my $self     = shift;
	my @features = @{ shift(@_) };

	my %dim = ();

	if ( scalar(@features) == 4 ) {

		my $maxXlen;
		my $maxYlen;

		foreach my $f (@features) {

			my $lenX = abs( $f->{"x1"} - $f->{"x2"} );
			my $lenY = abs( $f->{"y1"} - $f->{"y2"} );

			if ( !defined $maxXlen || $lenX > $maxXlen ) {

				$maxXlen = $lenX;
			}

			if ( !defined $maxYlen || $lenY > $maxYlen ) {

				$maxYlen = $lenY;
			}
		}

		$dim{"xSize"} = $maxXlen;
		$dim{"ySize"} = $maxYlen;
	}

	return %dim;
}

# Return limits xmin, xmax, ymin, ymax
# by four lines, which create rectangle
sub GetLimByRectangle {
	my $self     = shift;
	my @features = @{ shift(@_) };

	my %dim = ();

	if ( scalar(@features) == 4 ) {

		my $minX;
		my $minY;
		my $maxX;
		my $maxY;

		foreach my $f (@features) {

			my $lenX = abs( $f->{"x1"} - $f->{"x2"} );
			my $lenY = abs( $f->{"y1"} - $f->{"y2"} );

			# find minimum
			if ( !defined $minX || $f->{"x1"} < $minX ) {

				$minX = $f->{"x1"};
			}

			if ( !defined $minY || $f->{"y1"} < $minY ) {

				$minY = $f->{"y1"};
			}

			#find maximum
			if ( !defined $maxX || $f->{"x1"} > $maxX ) {

				$maxX = $f->{"x1"};
			}

			if ( !defined $maxY || $f->{"y1"} > $maxY ) {

				$maxY = $f->{"y1"};
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

	use aliased "Packages::Polygon::PolygonFeatures";

	my @points2 = ( [0,0], [0,5], [5,5], [5,0] );
	
	my @points = ( [1,1], [1,4], [4,4], [4,1], [4,4], [2,2] );

	#print PolygonFeatures->GetPoly2PolyIntersect( \@points, \@points2);
	
	my @p = PolygonFeatures->GetConvexHull( \@points);



	print "ddd";

}

1;

