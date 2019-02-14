#-------------------------------------------------------------------------------------------#
# Description: Helper class contain controls for rout chains
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::RoutChecks::RoutCheckTools;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::UniRTM::UniRTM';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Check if tool sizes are sorted ASC
sub OutlineToolIsLast {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;
	my $mess  = shift;

	my $result = 1;
	
 

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );
	my @chains = $unitRTM->GetChains();

	my @outlines = $unitRTM->GetOutlineChains();

	unless ( scalar(@outlines) ) {
		return $result;
	}

	my $outlineStart = 0;
	foreach my $ch (@chains) {

		foreach my $chSeq ( $ch->GetChainSequences() ) {

			if ( $chSeq->IsOutline() && !$outlineStart ) {

				$outlineStart = 1;
				next;
			}

			# if first outline was passed, all chain after has to be outline
			if ($outlineStart) {
				unless ( $chSeq->IsOutline() ) {
					$result = 0;

					$$mess .=
					    "Ve vrstvě: \""
					  . $layer
					  . "\" ve stepu: \""
					  . $step
					  . "\" jsou špatně seřazené frézy. Fréza "
					  . $chSeq->GetStrInfo()
					  . " nesmí být za obrysovými frézami.\n";
				}
			}
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

