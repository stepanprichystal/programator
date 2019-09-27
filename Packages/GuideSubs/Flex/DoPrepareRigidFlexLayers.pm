#-------------------------------------------------------------------------------------------#
# Description: Prepare special helper layers for creating coverlay
# and prepreg pins for RigidFlex
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Flex::DoPrepareRigidFlexLayers;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::GuideSubs::Flex::DoCoverlayPins';
use aliased 'Packages::GuideSubs::Flex::DoCoverlayLayers';
use aliased 'Packages::GuideSubs::Flex::DoPrepregLayers';
use aliased 'Packages::GuideSubs::Flex::DoRoutTransitionLayers';
use aliased 'Packages::GuideSubs::Flex::DoSolderTemplateLayers';
use aliased 'Packages::GuideSubs::Flex::DoFlexiMaskLayer';
use aliased 'Packages::GuideSubs::Flex::DoPrepareBendAreaOther';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Set impedance lines
sub PrepareLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $type = JobHelper->GetPcbType($jobId);
	return 0 if ( $type ne EnumsGeneral->PcbType_RIGIDFLEXI && $type ne EnumsGeneral->PcbType_RIGIDFLEXO );

	my @steps = ("o+1");

	foreach my $step (@steps) {

		CamHelper->SetStep( $inCAM, $step );

		DoCoverlayPins->CreateCoverlayPins( $inCAM, $jobId, $step );
		DoCoverlayLayers->PrepareCoverlayLayers( $inCAM, $jobId, $step );
		DoSolderTemplateLayers->PrepareTemplateLayers( $inCAM, $jobId, $step );
		DoPrepregLayers->PreparePrepregLayers( $inCAM, $jobId, $step );
		DoRoutTransitionLayers->PrepareRoutLayers( $inCAM, $jobId, $step );
		DoFlexiMaskLayer->PrepareFlexiMaskLayers( $inCAM, $jobId, $step );
		DoPrepareBendAreaOther->PrepareBendAreaOther( $inCAM, $jobId, $step );

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Flex::DoPrepareRigidFlexLayers';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d222775";

	my $notClose = 0;

	my $res = DoPrepareRigidFlexLayers->PrepareLayers( $inCAM, $jobId );

}

1;

