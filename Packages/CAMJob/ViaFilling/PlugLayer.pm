#-------------------------------------------------------------------------------------------#
# Description: Helper for create plug layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::ViaFilling::PlugLayer;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Stackup::StackupNC::StackupNC';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Create via_plug layers based on NC via fill layers
sub CreateCopperPlugLayersAllSteps {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $annularRing = shift // 75;    # annular ring for via plug is 75um

	my $stepPnl = "panel";

	die "Step panel doesn't exist" unless ( CamHelper->StepExists( $inCAM, $jobId, $stepPnl ) );

	die "Unable to create plug layers. There are no NC via fill layers." unless ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) );

	my @plgLayers = ();

	# 1) Remove all plg layers
	my @currPlg = grep { $_->{"gROWname"} =~ /^plg[csv]\d*$/ } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	foreach my $plg (@currPlg) {

		CamMatrix->DeleteLayer( $inCAM, $jobId, $plg->{"gROWname"} );
	}

	my @childs = CamStepRepeat->GetUniqueDeepestSR( $inCAM, $jobId, $stepPnl );
	foreach my $step (@childs) {

		my @l = $self->CreateCopperPlugLayers( $inCAM, $jobId, $step->{"stepName"}, $annularRing );
		push( @plgLayers, @l ) if ( scalar(@l) );
	}

	return @plgLayers;

}

# Create via_plug layers based on NC via fill layers
sub CreateCopperPlugLayers {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $annularRing = shift // 75;    # annular ring for via plug is 75um

	die "Unable to create plug layers. There are no NC via fill layers." unless ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) );

	my @plgLayers = ();

	CamHelper->SetStep( $inCAM, $step );

	# 2) Create layer
	if ( CamJob->GetSignalLayerCnt( $inCAM, $jobId ) <= 2 ) {

		my @plg = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nFillDrill );

		if (@plg) {

			my $topL = "plgc";
			my $botL = "plgs";
			if ( !CamHelper->LayerExists( $inCAM, $jobId, $topL ) ) {
				CamMatrix->CreateLayer( $inCAM, $jobId, $topL, "via_plug", "positive", 1, "c", "before" );
				push( @plgLayers, $topL );
			}

			if ( !CamHelper->LayerExists( $inCAM, $jobId, $botL ) ) {
				CamMatrix->CreateLayer( $inCAM, $jobId, $botL, "via_plug", "positive", 1, "s", "after" );
				push( @plgLayers, $botL );
			}

			foreach my $l (@plg) {

				CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
				CamLayer->CopySelOtherLayer( $inCAM, [ $topL, $botL ], 0, 2 * $annularRing );
			}
		}
	}
	else {

		my $stackup = StackupNC->new( $inCAM, $jobId );

		my @NCPrs = grep { $_->GetIProduct->GetPlugging() } ( $stackup->GetNCPressProducts(), $stackup->GetNCInputProducts() );

		foreach my $NCpr (@NCPrs) {

			my $IProduct = $NCpr->GetIProduct();

			my $topL = "plg" . $IProduct->GetTopCopperLayer();
			my $botL = "plg" . $IProduct->GetBotCopperLayer();

			# Create plgc layers for outer Cu of product
			if ( !CamHelper->LayerExists( $inCAM, $jobId, $topL ) ) {
				CamMatrix->CreateLayer( $inCAM, $jobId, $topL, "via_plug", "positive", 1, $IProduct->GetTopCopperLayer(), "before" );
 
				push( @plgLayers, $topL );
			}

			if ( !CamHelper->LayerExists( $inCAM, $jobId, $botL ) ) {
				CamMatrix->CreateLayer( $inCAM, $jobId, $botL, "via_plug", "positive", 1, $IProduct->GetBotCopperLayer(), "after" );
 
				push( @plgLayers, $botL );
			}

			# a) Filled core drilling
			my @cFillDrill = $NCpr->GetNCLayers( StackEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_cFillDrill, 1 );
			foreach my $l (@cFillDrill) {

				CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
				CamLayer->CopySelOtherLayer( $inCAM, [ $topL, $botL ], 0, 2 * $annularRing );

			}

			# b) Filled blind drill top
			my @bFillDrillTop = $NCpr->GetNCLayers( StackEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop, 1 );
			foreach my $l (@bFillDrillTop) {

				CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
				CamLayer->CopySelOtherLayer( $inCAM, [$topL], 0, 2 * $annularRing );

			}

			# c) Filled blind drill bot
			my @bFillDrillBot = $NCpr->GetNCLayers( StackEnums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot, 1 );
			foreach my $l (@bFillDrillBot) {

				CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
				CamLayer->CopySelOtherLayer( $inCAM, [$botL], 0, 2 * $annularRing );

			}

			# d) Filled through drill
			my @nFillDrill = $NCpr->GetNCLayers( StackEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_nFillDrill, 1 );
			foreach my $l (@nFillDrill) {

				CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
				CamLayer->CopySelOtherLayer( $inCAM, [ $topL, $botL ], 0, 2 * $annularRing );
			}
		}
	}

	CamLayer->ClearLayers($inCAM);

	return @plgLayers;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::ViaFilling::PlugLayer';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d312990";

	my $mess = "";

	if ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) ) {

		my $result = PlugLayer->CreateCopperPlugLayersAllSteps( $inCAM, $jobId );

	}

}

1;
