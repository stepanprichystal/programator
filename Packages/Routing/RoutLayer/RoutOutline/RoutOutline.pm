#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutOutline::RoutOutline;

#3th party library
use strict;
use warnings;
 

#local library
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
 
 sub CheckNarrowPlaces {
	my $self       = shift;
	my @sorteEdges = @{ shift(@_) };
	
	my %result     = ();
	$result{"result"} = 1;

	use Clone qw(clone);
	my @sorteEdgesCopy = @{ clone( \@sorteEdges ) };

	my @lines = ();
	my %lineCoord;
	my @middle = ( 0, 0 );

	@sorteEdgesCopy = RouteChainHelper->__FragmentArcReplace( \@sorteEdgesCopy, 20 );
	my @poly = map { [ $_->{"x1"}, $_->{"y1"} ] } @sorteEdgesCopy;

	#push( @poly, $poly[0] ); #make polygon cyclic

	for ( my $i = 0 ; $i < scalar(@poly) ; $i++ ) {

		for ( my $j = $i ; $j < scalar(@poly) ; $j++ ) {

			if ( abs( $i - $j ) <= 1 ) {
				next;
			}
			if (    ( $i == 0 && $j == scalar(@poly) - 1 )
				 || ( $j == 0 && $i == scalar(@poly) - 1 ) )
			{
				next;
			}

			if ( $i == 0 && $j == scalar(@poly) - 1 ) {
				next;
			}

			my @l = ( $poly[$i], $poly[$j] );
			my $lineLength = SegmentLength( \@l );

			# finale tool has 2mm size, but wee need some tolerance
			if ( $lineLength > 0 && $lineLength < 1.97 ) {

				$middle[0] = ( @{ $poly[$i] }[0] + @{ $poly[$j] }[0] ) / 2;
				$middle[1] = ( @{ $poly[$i] }[1] + @{ $poly[$j] }[1] ) / 2;

				unless ( polygon_contains_point( \@middle, ( @poly, $poly[0] ) ) ) {

					#test if count length of lines/arc between points is > 2
					my ($idxStart) = grep {
						     $sorteEdgesCopy[$_]{"x1"} eq $poly[$i][0]
						  && $sorteEdgesCopy[$_]{"y1"} eq $poly[$i][1]
					} 0 .. $#sorteEdgesCopy;
					my ($idxEnd) = grep {
						     $sorteEdgesCopy[$_]{"x1"} eq $poly[$j][0]
						  && $sorteEdgesCopy[$_]{"y1"} eq $poly[$j][1]
					} 0 .. $#sorteEdgesCopy;

					if ( $idxStart >= 0 ) {

						my ( $lenStart2End, $lenEnd2Start ) = ( 0, 0 );

						for ( my $k = 0 ; $k < abs( $idxStart - $idxEnd ) ; $k++ ) {
							$lenStart2End += $sorteEdgesCopy[ $idxStart + $k ]{'length'};
						}

						my $pom = 0;

						my $kMax = scalar(@sorteEdgesCopy) - $idxEnd + $idxStart;
						for ( my $k = 0 ; $k < $kMax ; $k++ ) {

							$pom = $idxEnd + $k;

							if ( $pom >= scalar(@sorteEdgesCopy) ) {
								$pom -= scalar(@sorteEdgesCopy);
							}

							$lenEnd2Start += $sorteEdgesCopy[$pom]{'length'};
						}

						if ( min( $lenStart2End, $lenEnd2Start ) > 4 ) {

							push( @lines, \@l );
						}

					}
				}

			}

		}
	}

	if ( scalar(@lines) > 0 ) {
		
		$result{"result"} = 0;
		$result{"places"} = \@lines;
	}
	
	return \%result;

}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13608";

 

}

1;

