#-------------------------------------------------------------------------------------------#
# Description:
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::CAMJob::SolderMask::PreparationLayout;

use strict;
use warnings;

use aliased 'Packages::CAMJob::SolderMask::ClearenceCheck';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
#
# If uncover solder mask on the rout path missing, then will be copy.
sub CopyRoutToSolderMask {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $stepId     = shift;
	my @layers     = qw (f r rs score);
	my @maskLayers = ();

	CamLayer->ClearLayers($inCAM);

	$inCAM->COM( 'set_step', name => $stepId );

	my @res = ();

	my $result = ClearenceCheck->RoutClearenceCheck( $inCAM, $jobId, $stepId, \@layers, \@res );

	unless ($result) {

		foreach my $s (@res) {

			my $lnew = CamLayer->RoutCompensation( $inCAM, $s->{"layer"}, 'document' );

			my $resize = 200;
			if ( $s->{"layer"} eq 'score' ) {
				$resize = -200;
			}

			CamLayer->WorkLayer( $inCAM, $lnew );
			CamLayer->CopySelOtherLayer( $inCAM, [ $s->{"mask"} ], 0, $resize );

			CamLayer->ClearLayers($inCAM);

			$inCAM->COM( "delete_layer", "layer" => $lnew );
		}
	}
}

# Copy through drill hole to solder mask layer as negative pad
sub UnmaskThroughHole {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $step   = shift;
	my $resize = shift // -50;       # -50µm resize drill holes copied to solder mask
	my $side   = shift // 'both';    # top/bot/both

	my $result = 1;

	my @NC = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@NC );

	@NC = map { $_->{"gROWname"} } grep { $_->{"NCSigStartOrder"} == 1 } @NC;

	my @sm = map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "solder_mask" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	if ( scalar(@NC) && scalar(@sm) ) {

		CamHelper->SetStep( $inCAM, $step );

		foreach my $nc (@NC) {

			CamLayer->WorkLayer( $inCAM, $nc );

			CamLayer->CopySelOtherLayer( $inCAM, \@sm, 0, $resize );
		}

		CamLayer->ClearLayers($inCAM);

	}
	else {
		$result = 0;
	}

	return $result;

}

1;
