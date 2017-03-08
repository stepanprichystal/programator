#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutParser::RoutCyclic;

#3th party library
use strict;
use warnings;
use Math::Trig;
use Math::Polygon::Calc;       #Math-Polygon
use Math::Geometry::Planar;    #Math-Geometry-Planar-GPC

#local library
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamDTMSurf';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutArc';
use aliased 'Packages::CAM::UniDTM::Enums';
use aliased 'Enums::EnumsRout';
use List::MoreUtils qw(uniq);
use aliased 'Packages::Polygon::PolygonPoints';
#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#


# neni odzkousena
sub IsCyclic {
	my $self        = shift;
	my @sortedFeats = shift;

	my $cyclic = 1;

	for ( my $i = 0 ; $i < scalar(@sortedFeats) ; $i++ ) {

		my $next = undef;

		if ( $i + 1 == scalar(@sortedFeats) ) {
			$next = $sortedFeats[0];
		}
		else {
			$next = $sortedFeats[ $i + 1 ];
		}

		if ( !( $sortedFeats[$i]->{"x2"} == $next->{"x1"} && $sortedFeats[$i]->{"y2"} == $next->{"y1"} ) ) {
			$cyclic = 0;
			last;

		}

	}

	return $cyclic;
}

#return polygon direction CW/CCW
sub GetRoutDirection {
	my $self        = shift;
	my @sortedFeats = @{ shift(@_) };
	
	my @points =  map { [ $_->{"x1"}, $_->{"y1"} ] } @sortedFeats;    # rest of points "x2,y2"

	return PolygonPoints->GetPolygonDirection( \@points );
}

sub SetRoutDirection {
	my $self        = shift;
	my $newDir      = shift;
	my @sortedFeats = @{ shift(@_) };

	my @poly = map { [ $_->{"x1"}, $_->{"y1"} ] } @sortedFeats;

	my $oriDir = $self->GetPolygonDirection(@poly);

	if ( $oriDir eq $newDir ) {
		return 0;
	}

	# zmen smser vsech features

}

# One chain can have more features
# Some features can have same start/end point (are connected)
# Thiese featurec join to "sequences"
# Return list of sequences, where sequence is list of features
sub GetRoutSequences {
	my $self  = shift;
	my @edges = @{ shift(@_) };

	my @sequences = ();

	unless ( scalar(@edges) ) {
		return 0;
	}

	my $seqDone = 0;
	my %actEdge;

	my @seq = ();

	while ( !$seqDone ) {

		if ( scalar(@seq) == 0 ) {
			push( @seq, $edges[0] );
			splice @edges, 0, 1;    # remove from edges
		}

		#take arbitrary edge
		 
		#find next part of chain
		my $isFind = 0;    # if some edges from @edge array was find

		for ( my $i = 0 ; $i < scalar(@seq) ; $i++ ) {

			my $x = sprintf( "%.3f", $seq[$i]->{"x2"} );
			my $y = sprintf( "%.3f", $seq[$i]->{"y2"} );

			for ( my $j = 0 ; $j < scalar(@edges) ; $j++ ) {

				my %e = %{ $edges[$j] };

				if (    ( $x == sprintf( "%.3f", $e{"x1"} ) && $y == sprintf( "%.3f", $e{"y1"} ) )
					 || ( $x == sprintf( "%.3f", $e{"x2"} ) && $y == sprintf( "%.3f", $e{"y2"} ) ) )
				{

					$isFind = 1;
					push( @seq, $edges[$j] );
					splice @edges, $j, 1;    # remove from edges
					last;

				}

			}

			if ($isFind) {
				last;
			}
		}

		if (!$isFind || scalar(@edges) == 0) {

			my @seqTmp = @seq;
			push( @sequences, \@seqTmp );
			@seq = ();
		}

		if ( scalar(@edges) == 0 ) {

			$seqDone = 1;
		}
	}
	
	return @sequences;
}

# Return sorted rout  CW
# Works out only for close polygon
sub GetSortedRout {
	my $self  = shift;
	my @edges = @{ shift(@_) };

	my @sorteEdges = ();
	my $sorted     = 0;
	my %actEdge;
	my $isOpen = 0;

	my $x;
	my $y;

	#sorting, "create chain"
	#sorting, "create chain"
	if ( scalar(@edges) > 1 ) {

		while ( !$sorted ) {

			#take arbitrary edge
			if ( scalar(@sorteEdges) == 0 ) {
				%actEdge = %{ $edges[0] };
			}

			$x = sprintf( "%.3f", $actEdge{"x2"} );
			$y = sprintf( "%.3f", $actEdge{"y2"} );

			my $isFind = 0;

			#find next part of chain
			for ( my $i = 0 ; $i < scalar(@edges) ; $i++ ) {

				#avoid to first item
				if ( scalar(@sorteEdges) == 0 && $i == 0 ) {
					next;
				}

				$isFind = 0;
				my %e = %{ $edges[$i] };

				if (    ( $x == sprintf( "%.3f", $e{"x1"} ) && $y == sprintf( "%.3f", $e{"y1"} ) )
					 || ( $x == sprintf( "%.3f", $e{"x2"} ) && $y == sprintf( "%.3f", $e{"y2"} ) ) )
				{
					$isFind = 1;

					#switch edge points for achieve same-oriented polygon
					if ( ( $x == sprintf( "%.3f", $e{"x2"} ) && $y == sprintf( "%.3f", $e{"y2"} ) ) ) {

						my $pX = $e{"x2"};
						my $pY = $e{"y2"};
						$e{"x2"} = $e{"x1"};
						$e{"y2"} = $e{"y1"};
						$e{"x1"} = $pX;
						$e{"y1"} = $pY;

						$e{"switchPoints"} = 1;
					}
					else {

						$e{"switchPoints"} = 0;
					}

					push( @sorteEdges, \%e );
					splice @edges, $i, 1;
					%actEdge = %e;

					 
					last;
				}
			}

			#something is wrong, probably sortedEdges contain line/arc, which are not part of route

			if ( $isFind == 0 ) {
				$sorted = 1;
				$isOpen = 1;
				last;
			}

			if ( scalar(@edges) == 0 ) {
				$sorted = 1;
			}
		}
		
		
	}
	#if circle case = one arc
	elsif(scalar(@edges) == 1 && $edges[0]->{"type"} =~ /a/i) {
		
		$edges[0]{"switchPoints"} = 0;
		push( @sorteEdges, $edges[0] );
	
	}elsif(scalar(@edges) == 1){
		@sorteEdges = ();
		return @sorteEdges;
	}
	
	# if polygon is not close, return 0
	if($isOpen){
		@sorteEdges = ();
		return @sorteEdges;
	}

	#Set polygon as Clockwise
	my @coord = map { [ $_->{"x1"}, $_->{"y1"} ] } @sorteEdges;

	#test if polzgon is circle (one arc)
	if (    ( scalar(@sorteEdges) == 1 && $sorteEdges[0]->{"oriDir"} eq EnumsRout->Dir_CCW )
		 || ( scalar(@sorteEdges) > 1 && $self->GetRoutDirection(\@sorteEdges) eq EnumsRout->Dir_CCW ) )
	{

		@sorteEdges = reverse @sorteEdges;

		#switch start and end point of edges
		for ( my $i = 0 ; $i < scalar(@sorteEdges) ; $i++ ) {

			my $pX = $sorteEdges[$i]->{"x2"};
			my $pY = $sorteEdges[$i]->{"y2"};

			$sorteEdges[$i]->{"x2"} = $sorteEdges[$i]->{"x1"};
			$sorteEdges[$i]->{"y2"} = $sorteEdges[$i]->{"y1"};
			$sorteEdges[$i]->{"x1"} = $pX;
			$sorteEdges[$i]->{"y1"} = $pY;

			$sorteEdges[$i]->{"switchPoints"} = ( $sorteEdges[$i]->{"switchPoints"} == 1 ) ? 0 : 1;

		}
	}

	#compute new arc direction depending on original direction and switchin start/end point
	for ( my $i = 0 ; $i < scalar(@sorteEdges) ; $i++ ) {

		if ( $sorteEdges[$i]->{"type"} eq "A" ) {
			if ( $sorteEdges[$i]->{"switchPoints"} == 0 ) {

				$sorteEdges[$i]->{"newDir"} = $sorteEdges[$i]->{"oriDir"};
			}
			elsif ( $sorteEdges[$i]->{"switchPoints"} == 1 ) {

				$sorteEdges[$i]->{"newDir"} =
				  ( $sorteEdges[$i]->{"oriDir"} eq EnumsRout->Dir_CW ) ? EnumsRout->Dir_CCW : EnumsRout->Dir_CW;
			}
		}
	}

	#pokud obrys obsahuje obloukz, je potreba je potreba je dostatecne aproximovat,
	#aby jsme spolehlive spocitali zda je obrys CW nebo CCW

	@sorteEdges = RoutArc->FragmentArcReplace( \@sorteEdges, -1 );

	return @sorteEdges;
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

