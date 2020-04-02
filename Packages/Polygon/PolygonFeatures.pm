
#-------------------------------------------------------------------------------------------#
# Description: Contain helper function with polygons created from features
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::PolygonFeatures;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];

#local library
use aliased 'Packages::Polygon::Enums';
use aliased 'Math::Geometry::Planar';
use aliased 'Packages::Polygon::Polygon::PolygonArc';
use aliased 'Packages::Polygon::Polygon::PolygonAttr';
use aliased 'Packages::Polygon::PointsTransform';



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

# works only for pad, lines arc
# Return 2D hash, where each cell contain array of features, which are placed on cell coordination
# Each feture contain key with hash ref:
# - cellS - contain cell position of feature start point
# - cellE - contain cell position of feature start point if exist
sub GetFeatureMatrix {
	my $self     = shift;
	my @features = @{ shift(@_) };
	my $cellCnt  = shift;            # square cnt in one axis (x and y has same number of square)
	my $report   = shift;

	my $maxIdx = $cellCnt - 1;

	# 1) get limits of feature points
	my @points = ();
	foreach my $e (@features) {

		my %p1 = ( "x" => $e->{"x1"}, "y" => $e->{"y1"} );
		my %p2 = ( "x" => $e->{"x2"}, "y" => $e->{"y2"} );
		push( @points, ( \%p1, \%p2 ) );
	}

	my %lim = PointsTransform->GetLimByPoints( \@points );

	$$report .= "=================== MATRIX  ===================\n";
	$$report .= "- size [" . abs( $lim{"xMax"} - $lim{"xMin"} ) . "," . abs( $lim{"yMax"} - $lim{"yMin"} ) . "]";

	my $xCellSize = max(1, int( abs( $lim{"xMax"} - $lim{"xMin"} ) / $cellCnt )); #min size of cell is 1mm
	my $yCellSize = max(1, int( abs( $lim{"yMax"} - $lim{"yMin"} ) / $cellCnt )); #min size of cell is 1mm

	$$report .= "- step sizes- X: $xCellSize, Y: $yCellSize\n\n";

	# 2) init matrix
	my %lt = ();
	for ( my $i = 0 ; $i < scalar($cellCnt) ; $i++ ) {
		for ( my $j = 0 ; $j < scalar($cellCnt) ; $j++ ) {
			$lt{$i}{$j} = [];
		}
	}

	# id min limits are negative, add to all feats
	my $xComp = ( $lim{"xMin"} < 0 ) ? abs( $lim{"xMin"} ) : 0;
	my $yComp = ( $lim{"yMin"} < 0 ) ? abs( $lim{"yMin"} ) : 0;

	# 3) put features to matrix
	foreach my $f (@features) {

		# start point
		#$$report .= "Features id: " . $f->{"id"} . ", start P [" . $f->{"x1"} . "," . $f->{"y1"} . "]\n";

		my $xId = int( int( $f->{"x1"} + $xComp ) / $xCellSize );
		my $yId = int( int( $f->{"y1"} + $yComp ) / $yCellSize );

		#$$report .= "- X Cell: " . $xId . ", after min: " . min( $maxIdx, $xId ) . "\n";
		#$$report .= "- Y Cell: " . $yId . ", after min: " . min( $maxIdx, $yId ) . "\n\n";

		# start point
		$f->{"cellS"} = {
						  "x" => min( $maxIdx, int( int( $f->{"x1"} + $xComp ) / $xCellSize ) ),
						  "y" => min( $maxIdx, int( int( $f->{"y1"} + $yComp ) / $yCellSize ) )
		};

		push( @{ $lt{ $f->{"cellS"}->{"x"} }{ $f->{"cellS"}->{"y"} } }, $f );

		# end point
		if ( defined $f->{"x2"} && defined $f->{"y2"} ) {

			$f->{"cellE"} = {
							  "x" => min( $maxIdx, int( int( $f->{"x2"} + $xComp ) / $xCellSize ) ),
							  "y" => min( $maxIdx, int( int( $f->{"y2"} + $yComp ) / $yCellSize ) )
			};

			push( @{ $lt{ $f->{"cellE"}->{"x"} }{ $f->{"cellE"}->{"y"} } }, $f );
		}

	}

	$$report .= "\n================= Quantity per cell =================\n\n ";
	my $total = 0;

	for ( my $i = $cellCnt - 1 ; $i >= 0 ; $i-- ) {

		for ( my $j = 0 ; $j < $cellCnt ; $j++ ) {

			my $cnt = scalar( @{ $lt{$j}{$i} } );
			$total += $cnt;

			$$report .= sprintf( "%04d", $cnt ) . " ";

		}
		$$report .= "\n ";
	}

	$$report .= "\nTotal = $total\n\n";

	$$report .= "Final check - Not processed points = " . ( $total / 2 - scalar(@features) ) . "\n";
	$$report .= "Number of processed features: = " . scalar(@features) . "\n";

	return %lt;

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

	my $jobId = "d250516";
	my $inCAM = InCAM->new();

	my $step  = "o+1";
	my $layer = "mfill1";

	$f->Parse( $inCAM, $jobId, $step, $layer );

	my @features = $f->GetFeatures();

	#	CamLayer->WorkLayer( $inCAM, "test" );
	#	$inCAM->COM('sel_delete');
	#
	#	foreach my $feat (@features) {
	#
	#		my @surfaces = PolygonFeatures->GetSurfaceEnvelops( $feat, 0.1 );
	#
	#		foreach my $surf (@surfaces) {
	#
	#			CamSymbol->AddPolyline( $inCAM, $surf, "r300", "positive" );
	#
	#		}
	#	}

	@features = grep { $_->{"type"} =~ /[p]/i } $f->GetFeatures();

	my $report = "";
	my %lt = PolygonFeatures->GetFeatureMatrix( \@features, 5, \$report );

	print $report;

}

1;

