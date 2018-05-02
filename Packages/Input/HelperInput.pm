#-------------------------------------------------------------------------------------------#
# Description: 
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::Input::HelperInput;

use strict;
use warnings;

use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';

use aliased 'Packages::CAMJob::SolderMask::ClearenceCheck';


use aliased 'Packages::InCAM::InCAM';

use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';


my $route = RouteFeatures->new();

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------# 
#Return 1 when some Line or Surface are without attr .rout_chain
sub GetUnChainFeatures {
	my $self = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layer = shift;
	my $step  = "o+1";
	my $res = 0;

	$route->Parse( $inCAM, $jobId, $step, $layer );

	my @features = $route->GetFeatures();
	
 			foreach my $f (@features){
 				if ($f->{'type'} eq 'L' | $f->{'type'} eq 'S') {
 						unless ($f->{'att'}->{'.rout_chain'}) {
 							$res = 1;
 						} 	
 				}	
 			}
	return $res;
}


sub CopyRoutToSolderMask {
	my $self = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my @layers     = qw (f r rs score);
	my @maskLayers = ();

		CamLayer->ClearLayers($inCAM);
		
		#$inCAM->COM ('set_step',name=>$stepId);
		my @res    = ();
	 
		my $result = ClearenceCheck->RoutClearenceCheck( $inCAM, $jobId, 'o+1', \@layers, \@res );
	
			unless ($result) {
		
					foreach my $s (@res) {
							
							my $lnew = CamLayer->RoutCompensation( $inCAM, $s->{"layer"}, 'document' );
									
									CamLayer->WorkLayer( $inCAM, $lnew );
									CamLayer->CopySelected( $inCAM, [$s->{"mask"}], 0, 200 );
									
									CamLayer->ClearLayers($inCAM);
									
									$inCAM->COM( "delete_layer", "layer" => $lnew);
					}
			}
}

1;
