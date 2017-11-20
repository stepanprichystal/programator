
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
sub GetSurfaceEnvelops {
	my $self     = shift;
	my $feature  = shift;    # surface feature
	my $accuracy = shift;    # Accuracz in mm. Default arc to line accuracz is 0.5mm

	unless ( defined $accuracy ) {

		$accuracy = 0.5;
	}

	if ( $feature->{"type"} !~ /s/i ) {
		die "Unable to create surface envelop, becauseit feature is not a type surface.";
	}

	my @envelops = ();

	# go through all surfaces
	for ( my $i = 0 ; $i < scalar( @{ $feature->{"surfaces"} } ) ; $i++ ) {

		my $surface = $feature->{"surfaces"}->[$i];

		my @envelop = ();

		# parse surface island
		for ( my $j = 0 ; $j < scalar( @{ $surface->{"island"} } ) ; $j++ ) {

			my $pInfPrev = $j > 0 ? $surface->{"island"}->[ $j - 1 ] : undef;
			my $pInf = ${ $surface->{"island"} }[$j];

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

				#my $segLength = PolygonArc->GetSegmentLength( $arc{"radius"}, $accuracy );    #accurate 1mm
				#my $segNumber = int( $arc{"length"} / $segLength );

				my $result = undef;
				my @points = PolygonArc->GetFragmentArc( \%arc, $accuracy, \$result );

				if ($result) {

					my @testP = ();
					foreach my $p ( @points[ ( $surface->{"circle"} ? 0 : 1 ) .. $#points ] ) {

						push( @envelop, { "x" => $p->[0], "y" => $p->[1] } );
					}

				}
				else {

					push( @envelop, { "x" => $pInf->{"x"}, "y" => $pInf->{"y"} } );

				}

			}
			else {
				unless ( $surface->{"circle"} ) {
					my %p = ( "x" => $pInf->{"x"}, "y" => $pInf->{"y"} );

					push( @envelop, \%p );
				}
			}

		}
		push( @envelops, \@envelop );

	}

	return @envelops;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased "Packages::Polygon::PolygonFeatures";
	use aliased 'Packages::Polygon::Features::Features::Features';
	use aliased 'Packages::InCAM::InCAM';
	use aliased "CamHelpers::CamSymbol";
	use aliased "CamHelpers::CamLayer";

	my $f = Features->new();

	my $jobId = "f52456";
	my $inCAM = InCAM->new();

	my $step  = "o+1";
	my $layer = "f";

	$f->Parse( $inCAM, $jobId, $step, $layer, 1, 1 );

	my @features = $f->GetFeatures();

	CamLayer->WorkLayer( $inCAM, "test" );
	$inCAM->COM('sel_delete');

	foreach my $feat (@features) {

		my @surfaces = PolygonFeatures->GetSurfaceEnvelops( $feat, 0.1 );

		foreach my $surf (@surfaces) {

			CamSymbol->AddPolyline( $inCAM, $surf, "r300", "positive" );

		}
	}

}

1;

