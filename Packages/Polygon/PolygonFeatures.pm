
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
use aliased 'Packages::Polygon::Polygon::PolygonArc';
use aliased 'Packages::Polygon::Polygon::PolygonAttr';

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

# Return points which create surface envelop
# If there are arc in surface, do aproximation
sub GetSurfaceEnvelop {
	my $self     = shift;
	my $feature  = shift;    # surface feature
	my $accuracy = shift;

	my @envelop = ();

	for ( my $i = 0 ; $i < scalar( @{ $feature->{"points"} } ) - 1 ; $i++ ) {

		my $pInfPrev =   $i > 0   ? $feature->{"points"}->[$i - 1] : undef;
		my $pInf = ${ $feature->{"points"} }[$i];

		# if circle, do aproximation
		if ( $pInf->{"type"} eq "c" ) {

			unless ($pInfPrev) {
				die "start point of surface arc is not defined";
			}

			# arc structure
			my %arc = (
						"x1"   => $pInfPrev->{"x"},
						"y1"   => $pInfPrev->{"y"},
						"x2"   => $pInf->{"x"},
						"y2"   => $pInf->{"y"},
						"xmid" => $pInf->{"xmid"},
						"ymid" => $pInf->{"ymid"},
						"dir"  => "CW"
			);

			PolygonAttr->AddArcAtt( \%arc );

			my $segNumber = $arc{"length"} / 2;    #everz to mm one segment

			my @points = PolygonArc->GetFragmentArc( \%arc, $segNumber );

		}
		else {

			my %p = ( "x" => $pInf->{"x"}, "y" => $pInf->{"y"} );

			push( @envelop, \%p );
		}

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased "Packages::Polygon::PolygonFeatures";
	use aliased 'Packages::Polygon::Features::Features::Features';
	use aliased 'Packages::InCAM::InCAM';

	my $f = Features->new();

	my $jobId = "f52456";
	my $inCAM = InCAM->new();

	my $step  = "o+1";
	my $layer = "f";

	$f->Parse( $inCAM, $jobId, $step, $layer, 1, 1 );

	my @features = $f->GetFeatures();

	PolygonFeatures->GetSurfaceEnvelop( $features[0] );

	print "ddd";

}

1;

