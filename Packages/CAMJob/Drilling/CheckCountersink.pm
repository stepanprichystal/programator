#-------------------------------------------------------------------------------------------#
# Description: Function for checking countersink
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::CheckCountersink;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Packages::CAM::UniRTM::Enums' => "RTMEnums";
use aliased 'Packages::CAM::UniDTM::Enums' => 'DTMEnums';
use aliased 'CamHelpers::CamStepRepeat';

#use aliased 'Helpers::FileHelper';
#use aliased 'Helpers::JobHelper';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Packages::Stackup::Stackup::Stackup';
#use aliased 'Packages::CAM::UniDTM::UniDTM';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Check if exist countersink in some layers in job (check all steps)
sub ExistCountersink {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $exist = 0;

	my @steps = ("o+1");

	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {

		@steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" );
	}

	my @types = (
				  EnumsGeneral->LAYERTYPE_nplt_bMillTop, EnumsGeneral->LAYERTYPE_nplt_bMillBot,
				  EnumsGeneral->LAYERTYPE_plt_bMillTop,  EnumsGeneral->LAYERTYPE_plt_bMillBot
	);

	foreach my $step (@steps) {

		foreach my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, \@types ) ) {

			if ( $self->ExistCountersinkByLayer( $inCAM, $jobId, $step, $l ) ) {

				$exist = 1;
				last;
			}
		}

		last if ($exist);
	}

	return $exist;
}

# check if exist countersink in given layer, step
sub ExistCountersinkByLayer {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	my $csExist = 0;

	CamDrilling->AddNCLayerType( [$layer] );

	# load UniDTM for layer
	my $dtm = UniDTM->new( $inCAM, $jobId, $step, $layer->{"gROWname"}, 0 );
	my $rtm = UniRTM->new( $inCAM, $jobId, $step, $layer->{"gROWname"}, 0, $dtm );

	# test if exist countersink as pad
	$csExist = ( grep { $_->GetDepth() > 0 && $_->GetAngle() && $_->GetTypeProcess() eq DTMEnums->TypeProc_HOLE } $dtm->GetUniqueTools() ) ? 1 : 0;

	unless ($csExist) {

		# test if exist countersink as surface or arc
		my @chainSeqArc = grep {
			defined $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle() && $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle() > 0
		} $rtm->GetCircleChainSeq( RTMEnums->FeatType_LINEARC );
		
		my @chainSeqSurf = grep {
			defined $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle() && $_->GetChain()->GetChainTool()->GetUniDTMTool()->GetAngle() > 0
		} $rtm->GetCircleChainSeq( RTMEnums->FeatType_SURF );

		if ( scalar(@chainSeqArc) || scalar(@chainSeqSurf) ) {
			$csExist = 1;
		}

	}

	return $csExist;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Drilling::CheckCountersink';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";

	my %res = ();
	my $r = CheckCountersink->ExistCountersink( $inCAM, $jobId );

	print $r;

}

1;
