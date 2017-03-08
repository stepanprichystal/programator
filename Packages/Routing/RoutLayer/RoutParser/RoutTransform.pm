#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutParser::RoutTransform;

#3th party library
use strict;
use warnings;
use Math::Trig;
use Math::Polygon::Calc;       #Math-Polygon
use Math::Geometry::Planar;    #Math-Geometry-Planar-GPC

#local library
use aliased 'Packages::Polygon::PolygonFeatures';
use aliased 'Packages::Polygon::PointsTransform';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
# Rotate rout by angle CW
sub RotateRout {
	my $self     = shift;
	my $angle    = shift;
	my @features = shift(@_);

	# 1) rotate all feature points
	foreach my $f (@features) {

		# line / arcs
		if ( $f->{"type"} =~ /[la]/i ) {

			my %p1 = ( "x" => $f->{"x1"}, "y" => $f->{"y1"} );
			my %p2 = ( "x" => $f->{"x2"}, "y" => $f->{"y2"} );

			%p1 = PolygonPoints->RotatePoint( $p1, $angle );
			%p2 = PolygonPoints->RotatePoint( $p2, $angle );

			$f->{"x1"} = $p1{"x"};
			$f->{"y1"} = $p1{"y"};

			$f->{"x2"} = $p2{"x"};
			$f->{"y2"} = $p2{"y"};
		}

		# arc
		if ( $f->{"type"} =~ /a/i ) {

			my %p1 = ( "x" => $f->{"xmid"}, "y" => $f->{"ymid"} );
			%p1 = PointsTransform->RotatePoint( $p1, $angle );

			$f->{"xmid"} = $p1{"x"};
			$f->{"ymid"} = $p1{"y"};
		}

		# surf
		if ( $f->{"type"} =~ /s/i ) {

			for ( my $i = 0 ; $i < scalar( @{ $f->{"envelop"} } ) ; $i++ ) {

				@{ $f->{"envelop"} }[$i]

				  my %newP = PointsTransform->RotatePoint( @{ $f->{"envelop"} }[$i], $angle );
				@{ $f->{"envelop"} }[$i] = \%newP;
			}
		}

	}
}


# Rotate rout by angle CW
sub MoveRoutToZero {
	my $self     = shift;
	my $angle    = shift;
	my @features = shift(@_);
	
	my %lim = PolygonFeatures->GetLimByRectangle(\@features);
 

	# 1) move to zero
	foreach my $f (@features) {

		# line / arcs
		if ( $f->{"type"} =~ /[la]/i ) {

			$f->{"x1"} -= $lim{"xMin"};
			$f->{"y1"} -= $lim{"yMin"};
			$f->{"x2"} -= $lim{"xMin"};
			$f->{"y2"} -= $lim{"yMin"};
		}

		# arc
		if ( $f->{"type"} =~ /a/i ) {
 
			$f->{"xmid"}  -= $lim{"xMin"};
			$f->{"ymid"}  -= $lim{"yMin"};
		}

		# surf
		if ( $f->{"type"} =~ /s/i ) {

			for ( my $i = 0 ; $i < scalar( @{ $f->{"envelop"} } ) ; $i++ ) {

				@{ $f->{"envelop"} }[$i]->{"x"} -= $lim{"xMin"};
				@{ $f->{"envelop"} }[$i]->{"x"} -= $lim{"yMin"};
			}
		}

	}
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13608";

	my $f = FeatureFilter->new( $inCAM, "m" );

	$f->SetPolarity("positive");

	my @types = ( "surface", "pad" );
	$f->SetTypes( \@types );

	my @syms = ( "r500", "r1" );
	$f->AddIncludeSymbols( \[ "r500", "r1" ] );

	print $f->Select();

	print "fff";

}

1;

