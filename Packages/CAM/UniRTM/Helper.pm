#-------------------------------------------------------------------------------------------#
# Description: Helper function for UniRTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Polygon::Polygon::PolygonPoints';
use aliased "Packages::Polygon::PolygonFeatures";
use aliased 'Packages::Polygon::Polygon::PolygonArc';
use aliased 'Packages::Polygon::Polygon::PolygonAttr';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return list of all feature start end points
# (Arcs are fragmented to lines)
sub GetLineArcShapePoints {
	my $self     = shift;
	my @features = @{ shift(@_) };
	my $accuracy = shift // 0.2;     # radius tolerance, when convert arc to points

	my @points = ();
 
	my @pointsPom = ();

	for ( my $i = 0 ; $i < scalar(@features) ; $i++ ) {

		my $f         = $features[$i];
		my $lastPoint = undef;

		if ( $f->{"type"} =~ /A/i ) {

			my $result = undef;

			$f->{"dir"} = $f->{"newDir"} ? $f->{"newDir"} : $f->{"oriDir"};    # GetFragmentArc assume propertt "dir"
			my @p = PolygonArc->GetFragmentArc( $f, $accuracy, \$result );

			if ($result) {

				push( @pointsPom, @p );

			}
			else {
				# takke start + end point of arc/circle
				push( @pointsPom, [ $f->{"x1"}, $f->{"y1"} ] );

			}

		}
		elsif ( $f->{"type"} =~ /l/i ) {

			push( @pointsPom, [ $f->{"x1"}, $f->{"y1"} ] );

		}

		$lastPoint = [ $f->{"x2"}, $f->{"y2"} ];

		if ( $i == scalar(@features) - 1 ) {
			push( @points, $lastPoint );
		}
	}

	push( @points, @pointsPom );

	return @points;
}


# Return envelop of surface
# Envelop is created by convexhull
sub GetSurfShapePoints {
	my $self     = shift;
	my @features = @{ shift(@_) };
	my $accuracy = shift // 0.2;     # radius tolerance, when convert arc to points

	my @points = ();

	# Chain sequnce created form surface contain only one surface feature
	my $singleIsland    = 1;
	my @surfaceEnvelops = ();

	# if more surfaces ore more islands in one surface, do convex hull for all surfaces
	if ( scalar(@features) > 1 ) {
		$singleIsland = 0;
	}

	foreach my $surfFeat (@features) {

		my @envelops = PolygonFeatures->GetSurfaceEnvelops( $surfFeat, $accuracy );

		if ( scalar(@envelops) > 1 ) {
			$singleIsland = 0;
		}

		foreach my $e (@envelops) {
			push( @surfaceEnvelops, @{$e} );
		}
	}

	@surfaceEnvelops = map { [ $_->{"x"}, $_->{"y"} ] } @surfaceEnvelops;

	# Do convex hull from all surface envelop points
	if ($singleIsland) {

		#@surfaceEnvelops = map { [ $_->{"x"}, $_->{"y"} ] } @surfaceEnvelops;
	}
	else {

		@surfaceEnvelops = PolygonPoints->GetConvexHull( \@surfaceEnvelops );
	}

	@points = @surfaceEnvelops;

	return @points;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

