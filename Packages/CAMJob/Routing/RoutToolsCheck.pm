#-------------------------------------------------------------------------------------------#
# Description: Helper class contain controls for rout chains
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Routing::RoutToolsCheck;

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

	my @outlines = $unitRTM->GetOutlineChainSeqs();

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


	use aliased 'Packages::CAMJob::Routing::RoutToolsCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d304124";
	my $step  = "o+1";

	my $mess = "";
	my $res = RoutToolsCheck->OutlineToolIsLast( $inCAM, $jobId, "panel", "fsch", \$mess );

	print "$res - $mess";


}

1;

