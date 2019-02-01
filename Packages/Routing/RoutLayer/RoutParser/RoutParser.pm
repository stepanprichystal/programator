#-------------------------------------------------------------------------------------------#
# Description: Helper class, which parse rout layers, add special attributes to edges etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutParser::RoutParser;

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Packages::Routing::RoutLayer::RoutMath::RoutMath';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutArc';
use aliased 'Packages::Polygon::Polygon::PolygonPoints';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Check if tools parameters are ok
# When some errors occure here, proper NC export is not possible
sub GetFeatures {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $breakSR = shift;

	my $parser = RouteFeatures->new();

	$parser->Parse($inCAM, $jobId, $step, $layer, $breakSR);
 
	return $parser->GetFeatures();

}

# Check if all chains (lines, arc, surf) contain attribute .rout_chain
sub CheckRoutAttributes {
	my $self     = shift;
	my @features = shift(@_);
	my $mess     = shift;

	my $result = 1;

	my @chains = ();

	foreach my $f (@features) {

		# if no attributes
		unless ( $f->{"att"} ) {
			$mess .= "No rout atributes in feature id: " . $f->{"id"} . ".\n";
			$result = 0;
			next;
		}

		my %attr = %{ $f->{"att"} };

		# if features contain attribute rout chain
		if ( !( $attr{".rout_chain"} && $attr{".rout_chain"} > 0 ) ) {

			$mess .= "No rout atributes \".rout_chain\" in feature id: " . $f->{"id"} . ".\n";
			$result = 0;

		}
	}

	return $result;
}

#helpner computation of length, position of center point in arc etc
sub AddGeometricAtt {
	my $self = shift;
	my $edge = shift;

	#print ${$edge}->{"x1"};

	my ( $l, $d ) = ( 0, 0 );

	#distance between points at line
	if ( $edge->{"type"} eq "L" ) {
		$edge->{"length"} =
		  sqrt( ( $edge->{"x1"} - $edge->{"x2"} )**2 + ( $edge->{"y2"} - $edge->{"y1"} )**2 );
	}

	if ( $edge->{"type"} eq "A" ) {

		#distance of start/end point
		$edge->{"distance"} =
		  sqrt( ( $edge->{"x1"} - $edge->{"x2"} )**2 + ( $edge->{"y2"} - $edge->{"y1"} )**2 );

		#size of diameter
		$edge->{"diameter"} = 2 * sqrt( ( $edge->{"xmid"} - $edge->{"x2"} )**2 + ( $edge->{"y2"} - $edge->{"ymid"} )**2 );

		$edge->{"radius"}    = $edge->{"diameter"} / 2;
		$edge->{"perimeter"} = 2 * pi * $edge->{"radius"};

		#test if center point of arc lay on right or left from line (position = sign( (Bx-Ax)*(Y-Ay) - (By-Ay)*(X-Ax) ))
		# when positive = lay on left, when negative = lay on right

		#compute length of arc
		$edge->{"innerangle"} = RoutArc->GetArcInnerAngle($edge);
		$edge->{"length"} =
		  deg2rad( $edge->{"innerangle"}, 1 ) * $edge->{"radius"};               #compute length of arc, 1 means - when 360 circle it returns 2Pi
	}
}

# Compeare areas of two cyclic rout, with tolerance 0,01mm2
sub RoutAreasEquals {
	my $self  = shift;
	my @features1 = @{ shift(@_) };
 	my @features2 = @{ shift(@_) };
 	
 	my @points1 = map { [ $_->{"x2"}, $_->{"y2"} ] } @features1;
 	my @points2= map { [ $_->{"x2"}, $_->{"y2"} ] } @features2;
 
 	my $area1 = PolygonPoints->GetPolygonArea(\@points1);
 	my $area2 = PolygonPoints->GetPolygonArea(\@points2);
 
 	# tolerance 0.01 mm2
 	if(abs ($area1 - $area2) < 0.01){
 		return 1;
 	}else{
 		return 0;
 	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

