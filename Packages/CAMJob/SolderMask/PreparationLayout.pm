#-------------------------------------------------------------------------------------------#
# Description: 
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::CAMJob::SolderMask::PreparationLayout;

use strict;
use warnings;

use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Packages::CAMJob::SolderMask::ClearenceCheck';
use aliased 'Packages::InCAM::InCAM';

use aliased 'CamHelpers::CamLayer';



my $route = RouteFeatures->new();

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------# 
#
# If uncover solder mask on the rout path missing, then will be copy.
sub CopyRoutToSolderMask {
	my $self = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $stepId = shift;
	my @layers     = qw (f r rs score);
	my @maskLayers = ();
	
		CamLayer->ClearLayers($inCAM);
		
		$inCAM->COM ('set_step',name=> $stepId);
		
		my @res    = ();
	 
		my $result = ClearenceCheck->RoutClearenceCheck( $inCAM, $jobId, $stepId, \@layers, \@res );
	
			unless ($result) {
		
					foreach my $s (@res) {
							
							my $lnew = CamLayer->RoutCompensation( $inCAM, $s->{"layer"}, 'document' );
									
									my $resize = 200;
									if ($s->{"layer"} eq 'score'){
										$resize = -200;
									}
									
									CamLayer->WorkLayer( $inCAM, $lnew );
									CamLayer->CopySelected( $inCAM, [$s->{"mask"}], 0, $resize );
									
									CamLayer->ClearLayers($inCAM);
									
									$inCAM->COM( "delete_layer", "layer" => $lnew);
					}
			}
}

1;
