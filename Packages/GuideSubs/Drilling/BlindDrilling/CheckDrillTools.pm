#-------------------------------------------------------------------------------------------#
# Description: Checking rout layer during processing pcb
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Drilling::BlindDrilling::CheckDrillTools;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrillInfo';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrill';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';


#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub BlindDrillCheckAllSteps {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $messMngr = shift;

	my $result = 0;

	my $stepName = 'panel';

	return 0 unless ( CamHelper->StepExists( $inCAM, $jobId, $stepName ) );

	while ( !$result ) {

		$result = 1;

		my $errStr = "";

		foreach my $s ( CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $stepName ) ) {

			foreach my $l (
				 CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_plt_bDrillTop, EnumsGeneral->LAYERTYPE_plt_bDrillBot ] ) )
			{
				my $errStrStep = "";
				unless ( BlindDrillInfo->BlindDrillChecks( $inCAM, $jobId, $s->{"stepName"}, $l, \$errStrStep ) ) {

					$errStr .= "Chybné slepé otvory (step: \"" . $s->{"stepName"} . "\", layer: \"" . $l->{"gROWname"} . "\"):\n $errStrStep\n\n";
					$result = 0;
				}
			}
		}

		unless ($result) {
			
			$errStr =~ s/(Otvor:\s*\d+µm)/<b>$1<\/b>/g; # bold otvor + diameter
			

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["$errStr"], [ "Opravím", "Neopravím, pokračovat" ] );

			if ( $messMngr->Result() == 0 ) {

				$inCAM->PAUSE("Oprav slepe otvory...");
			}
			else {

				last;
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

	use aliased 'Packages::GuideSubs::Drilling::BlindDrilling::CheckDrillTools';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	#	use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';
	#
	my $messMngr = MessageMngr->new("D3333");

	my $inCAM = InCAM->new();

	my $jobId = "d152457";
	my $step  = "";

	CheckDrillTools->BlindDrillCheckAllSteps( $inCAM, $jobId, $messMngr );
}

1;

