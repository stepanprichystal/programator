#-------------------------------------------------------------------------------------------#
# Description: Helper class for rout transformation
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
# All coordinate should be in mm
sub RotateRout {
	my $self     = shift;
	my $angle    = shift;
	my @features = @{shift(@_)};

	# 1) rotate all feature points
	foreach my $f (@features) {

		# line / arcs
		if ( $f->{"type"} =~ /[la]/i ) {

			my %p1 = ( "x" => $f->{"x1"} * 1000, "y" => $f->{"y1"}  * 1000);
			my %p2 = ( "x" => $f->{"x2"} * 1000, "y" => $f->{"y2"} * 1000 );

			%p1 = PointsTransform->RotatePoint( \%p1, $angle );
			%p2 = PointsTransform->RotatePoint( \%p2, $angle );
 
			$f->{"x1"} = $p1{"x"} /1000; 
			$f->{"y1"} = $p1{"y"} /1000;

			$f->{"x2"} = $p2{"x"}/1000;
			$f->{"y2"} = $p2{"y"}/1000;
		}

		# arc
		if ( $f->{"type"} =~ /a/i ) {

			my %p1 = ( "x" => $f->{"xmid"} * 1000, "y" => $f->{"ymid"} * 1000 );
			%p1 = PointsTransform->RotatePoint( \%p1, $angle );

			$f->{"xmid"} = $p1{"x"}/1000;
			$f->{"ymid"} = $p1{"y"}/1000;
		}

		# surf
		if ( $f->{"type"} =~ /s/i ) {

			die "surface rotation is not implemented\n";

#			my @envelopNew = ();
# 
#			for ( my $i = 0 ; $i < scalar( @{ $f->{"envelop"} } ) ; $i++ ) {
# 
#				my %p1 = ( "x" => $f->{"envelop"}->[$i]->{"x"} * 1000, "y" => $f->{"envelop"}->[$i]->{"y"}  * 1000);
#
#				my %newP = PointsTransform->RotatePoint( \%p1, $angle );
# 
# 				$p1{"x"} /= 1000;
# 				$p1{"y"} /= 1000;
# 
#				$f->{"envelop"}->[$i] = \%newP;
#			}
		}
	}
}


# Rotate rout by angle CW
sub MoveRout {
	my $self     = shift;
	my $xSize    = shift;
	my $ySize    = shift;
	my @features = @{shift(@_)};
 
	# 1) move to zero
	foreach my $f (@features) {

		# line / arcs
		if ( $f->{"type"} =~ /[la]/i ) {

			$f->{"x1"} += $xSize;
			$f->{"y1"} += $ySize;
			$f->{"x2"} += $xSize;
			$f->{"y2"} += $ySize;
		}

		# arc
		if ( $f->{"type"} =~ /a/i ) {

			$f->{"xmid"} += $xSize;
			$f->{"ymid"} += $ySize;
		}

		# surf
		if ( $f->{"type"} =~ /s/i ) {

			die "Surface move is not implemented";

#			for ( my $i = 0 ; $i < scalar( @{ $f->{"envelop"} } ) ; $i++ ) {
#
#				@{ $f->{"envelop"} }[$i]->{"x"} += $xSize;
#				@{ $f->{"envelop"} }[$i]->{"y"} += $ySize;
#			}
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

