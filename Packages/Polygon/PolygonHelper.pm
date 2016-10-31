
#-------------------------------------------------------------------------------------------#
# Description: Contain helper function
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::PolygonHelper;

#3th party library
use strict;
use warnings;

#local library

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

	use aliased "Packages::Polygon::PolygonHelper";

	my %point = ( "x" => 20, "y" => 10 );

	#PolygonHelper->RotatePointByOrigin( \%point, 180, 20, 10 );

	#print 1;

}

1;

