#-------------------------------------------------------------------------------------------#
# Description: Floatten score in SR steps to mpanel
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Routing::DoRoutOptimalization;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Routing::RoutCircle';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Split rout cycle in rout layers: plated and noplated rout
sub SplitRoutCircles {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);
	


	my @steps = ("o+1");

	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {
		@steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobId );
	}

	foreach my $step (@steps) {
		
		my $resStep = 0;
		my $mess = "V následujících frézovacích vrstvách ve stepu: \"".$step."\", byly rozděleny \"kruhy\" na dva \"arky\":\n";

		foreach my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_plt_nMill ] ) )
		{

			my %resData = ();
 
			if ( RoutCircle->SplitCircles2Arc( $inCAM, $jobId, $step, $l->{"gROWname"}, \%resData ) ) {
				
				$resStep = 1;
				$mess .= "- Vrstva: ".$l->{"gROWname"}.", arky s id: ".join("; ", @{$resData{"splitedArcs"}} )."\n";
			}
		}
		
		if($resStep){
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, [$mess] );
		}
	}
 
	return $result;
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Routing::DoRoutOptimalization';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d113609";

	my $notClose = 0;

	my $res = DoRoutOptimalization->SplitRoutCircles( $inCAM, $jobId );

}

1;

