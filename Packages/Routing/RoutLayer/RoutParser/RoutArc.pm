#-------------------------------------------------------------------------------------------#
# Description: Helper class working with arcs in rout layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutParser::RoutArc;

#3th party library
use strict;
use warnings;
use Math::Trig;
use Math::Polygon::Calc;       #Math-Polygon
use Math::Geometry::Planar;    #Math-Geometry-Planar-GPC
use POSIX 'floor';

#local library
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutParser';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

#Method which replace arc by more arcs
sub FragmentArcReplace {

	my $self             = shift;
	my @sorteEdges       = @{ shift(@_) };
	my $defaultSegNumber = shift;
	my $fragmented       = shift;
	my $idStartFrom      = shift;            # index which new arc id start from
	my $uidStartFrom     = shift;            # index which new arc unique id start from

	die "Start feature id number is not defined"  unless ( defined $idStartFrom );
	die "Start feature uid number is not defined" unless ( defined $uidStartFrom );

	#pokud obrys obsahuje obloukz, je potreba je potreba je dostatecne aproximovat,
	#aby jsme spolehlive spocitali zda je obrys CW nebo CCW
	for ( my $i = scalar(@sorteEdges) - 1 ; $i >= 0 ; $i-- ) {

		if ( $sorteEdges[$i]{"type"} eq "A" ) {

			my $segNumber = 12;    #default segment count of whole circle
			if ( $sorteEdges[$i]{"diameter"} < 50 ) {
				$segNumber = 4;
			}

			if ( $defaultSegNumber > 0 ) {
				$segNumber = $defaultSegNumber;
			}

			my @arcPoints = $self->__FragmentArc( $sorteEdges[$i], $segNumber );

			if ( scalar(@arcPoints) > 2 ) {

				$$fragmented = 1;

				#insert new arc
				for ( my $j = 0 ; $j < scalar(@arcPoints) - 1 ; $j++ ) {

					my %featInfo;

					%featInfo = %{ $sorteEdges[$i] };

					$featInfo{"id"}  = $idStartFrom;     # !! set max id from all layer features, not random!
					$featInfo{"uid"} = $uidStartFrom;    # !! set max uid from all layerfeatures, not random!
					$idStartFrom++;
					$uidStartFrom++;

					#$featInfo{"x1"} = sprintf( "%.3f", $arcPoints[$j][0] );
					#$featInfo{"y1"} = sprintf( "%.3f", $arcPoints[$j][1] );

					$featInfo{"x1"} = $arcPoints[$j][0];
					$featInfo{"y1"} = $arcPoints[$j][1];

					#$featInfo{"x2"} = sprintf( "%.3f", $arcPoints[ $j + 1 ][0] );
					#$featInfo{"y2"} =sprintf( "%.3f", $arcPoints[ $j + 1 ][1] );

					$featInfo{"x2"} = $arcPoints[ $j + 1 ][0];
					$featInfo{"y2"} = $arcPoints[ $j + 1 ][1];

					RoutParser->AddGeometricAtt( \%featInfo );

					splice @sorteEdges, $i + $j + 1, 0, \%featInfo;
				}

				splice @sorteEdges, $i, 1;    #remove old arc

			}
		}
	}

	return @sorteEdges;

}

#Fragment arc on "n" arcs, depending on diameter, lenght etc.
#Whole circle
sub __FragmentArc {

	my $self      = shift;
	my $arc       = shift(@_);
	my $segNumber = shift;
	my $points;

	#oblouk ma mensi polomer jak 10

	if ( $arc->{"diameter"} < 10 ) {
		return 0;
	}

	my @arrStart  = ( $arc->{"x1"},   $arc->{"y1"} );
	my @arrEnd    = ( $arc->{"x2"},   $arc->{"y2"} );
	my @arrCenter = ( $arc->{"xmid"}, $arc->{"ymid"} );
	my $direction = $arc->{"newDir"};

	if ( $arc->{"x1"} == $arc->{"x2"} && $arc->{"y1"} == $arc->{"y2"} ) {

		$points = CircleToPoly( $segNumber, \@arrCenter, \@arrStart );

		my @arr = @{ $points->{"points"} };
		push( @arr, $arr[0] );

		#CircleToPoly return points as CWW, so we've to consider original direction from genesis
		if ( $arc->{"newDir"} eq "CW" ) {
			@arr = reverse @arr;
		}

		return @arr;
	}

	my $segCnt =
	  floor( ( $arc->{"length"} / $arc->{"perimeter"} ) * $segNumber );    #number of segment for arc

	#oblouk se nebude delit
	if ( $segCnt < 2 ) {
		return 0;
	}

	$points = ArcToPoly( $segCnt, \@arrCenter, \@arrStart, \@arrEnd, ( $direction eq "CW" ) ? 1 : 0 );

	return @{$points};
}

sub GetArcInnerAngle {

	my $self = shift;
	my $arc  = shift(@_);

	my @arrStart  = ( $arc->{"x1"},   $arc->{"y1"} );
	my @arrEnd    = ( $arc->{"x2"},   $arc->{"y2"} );
	my @arrCenter = ( $arc->{"xmid"}, $arc->{"ymid"} );
	my $direction = !defined $arc->{"newDir"} ? $arc->{"oriDir"} : $arc->{"newDir"};

	my $r = $arc->{"diameter"} / 2;
	my $o = 2 * pi * $r;              #perimeter of  whole circle
	                                  #lines returned after segmentation

	my $angle1 =
	  rad2deg( atan2( $arc->{"y1"} - $arc->{"ymid"}, $arc->{"x1"} - $arc->{"xmid"} ) )
	  ;                               #angle of point given by start point and x coordinate above line x
	my $angle2 =
	  rad2deg( atan2( $arc->{"y2"} - $arc->{"ymid"}, $arc->{"x2"} - $arc->{"xmid"} ) )
	  ;                               #angle of point given by end point and x coordinate under line x

	my $alfa;
	my $sign = 1;

	#computation length of actual arc
	#test if both points are "above/under/ above and under" line x
	if ( $angle2 * $angle1 > 0 ) {
		$sign = $sign * -1;

		#print "Stejna znamenka\n";
	}
	else {

		#print "Ruzna znamenka\n";
	}

	if ( $direction eq "CW" ) {
		if ( $angle1 > $angle2 ) {
			$alfa = abs( abs($angle1) + $sign * abs($angle2) );
		}
		else {
			$alfa = 360 - abs( abs($angle1) + $sign * abs($angle2) );
		}
	}
	else {

		if ( $angle2 > $angle1 ) {
			$alfa = abs( abs($angle1) + $sign * abs($angle2) );
		}
		else {
			$alfa = 360 - abs( abs($angle1) + $sign * abs($angle2) );
		}
	}

	return $alfa;
}

## Convert arc to lines with specific segment line
## v nekterych pripadech fce ArcToPoly dava spatne vysledkyu
#sub FragmentArcToSegments {
#	my $self   = shift;
#	my $arc    = shift;
#	my $segLen = shift;    # line of line segment in mm
#
#	#die "Spatne naimplementovana - nefunguje";
#
#	my @segments = ();
#
#	my @arrStart  = ( $arc->{"x1"},   $arc->{"y1"} );
#	my @arrEnd    = ( $arc->{"x2"},   $arc->{"y2"} );
#	my @arrCenter = ( $arc->{"xmid"}, $arc->{"ymid"} );
#	my $direction = $arc->{"newDir"} || $arc->{"oriDir"};
#
#	if ( $arc->{"x1"} == $arc->{"x2"} && $arc->{"y1"} == $arc->{"y2"} ) {
#		die "Not arc but circle\n";
#	}
#
#	my $segCnt = int( $arc->{"length"} / $segLen );
#
#	if ( $segCnt == 0 ) {
#
#		my %featInfo;
#
#		$featInfo{"type"} = "L";
#		$featInfo{"id"}   = GeneralHelper->GetNumUID();
#		$featInfo{"x1"}   = $arc->{"x1"};
#		$featInfo{"y1"}   = $arc->{"y1"};
#		$featInfo{"x2"}   = $arc->{"x2"};
#		$featInfo{"y2"}   = $arc->{"y2"};
#
#		RoutParser->AddGeometricAtt( \%featInfo );
#
#		push( @segments, \%featInfo );
#
#	}
#	else {
#
#		my $arcPoints = ArcToPoly( $segCnt, \@arrCenter,  \@arrStart, \@arrEnd,  ( $direction eq "CW" ) ? 1 : 0 );
#
#		#my $arcPoints = ArcToPoly( $segCnt, \@arrCenter, \@arrStart, \@arrEnd,  0 );
#
#		for ( my $j = 0 ; $j < scalar( @{$arcPoints} ) - 1 ; $j++ ) {
#
#			my %featInfo;
#
#			$featInfo{"type"} = "L";
#			$featInfo{"id"}   = GeneralHelper->GetNumUID();
#
#			$featInfo{"x1"} = $arcPoints->[$j][0];
#			$featInfo{"y1"} = $arcPoints->[$j][1];
#
#			$featInfo{"x2"} = $arcPoints->[ $j + 1 ][0];
#			$featInfo{"y2"} = $arcPoints->[ $j + 1 ][1];
#
#			RoutParser->AddGeometricAtt( \%featInfo );
#
#			push( @segments, \%featInfo );
#		}
#	}
#
##	foreach $_ (@segments) {
##
##		print STDERR "line  = ["
##		  . sprintf( "%.1f", $_->{"x1"} ) . ", "
##		  . sprintf( "%.1f", $_->{"y1"} ) . "],  ["
##
##		  . sprintf( "%.1f", $_->{"x2"} ) . ", "
##		  . sprintf( "%.1f", $_->{"y2"} )
##		  . "]\n";
##
##	}
##
##	print STDERR "\n";
#
#	return @segments;
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#	my $jobId = "f13608";
	#
	#	my $f = FeatureFilter->new( $inCAM, "m" );
	#
	#	$f->SetPolarity("positive");
	#
	#
	#
	#	my @syms = ( "r500", "r1" );
	#	$f->AddIncludeSymbols( \[ "r500", "r1" ] );
	#
	#	print $f->Select();
	#
	#	print "fff";

}

1;

