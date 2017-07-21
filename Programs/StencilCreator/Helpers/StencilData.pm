
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Helpers::StencilData;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamLayer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub SetSourceData {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $form  = shift;

	# paste layer
	my @pasteL = grep { $_->{"gROWname"} =~ /^s[ab][-]((ori)|(made))+$/ } CamJob->GetAllLayers( $inCAM, $jobId );

	my $topLayer = ( grep { $_->{"gROWname"} =~ /^sa-ori/ } @pasteL )[0];
	unless ($topLayer) {
		$topLayer = ( grep { $_->{"gROWname"} =~ /^sa-made/ } @pasteL )[0];
	}

	my $botLayer = ( grep { $_->{"gROWname"} =~ /^sb-ori/ } @pasteL )[0];
	unless ($botLayer) {
		$botLayer = ( grep { $_->{"gROWname"} =~ /^sb-made/ } @pasteL )[0];
	}

	# steps
	my @steps = map { $_->{"stepName"} } grep { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" );

	# limits
	my %stepsSize = ();

	foreach my $stepName (@steps) {

		my %size = ();

		# 1) store step profile size
		my %profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $stepName );

		$size{"w"} = abs( $profLim{"xMax"} - $profLim{"xMin"} );
		$size{"h"} = abs( $profLim{"yMax"} - $profLim{"yMin"} );

		# store layer data size for sa..., sb... layers
		if ($topLayer) {

			# limits of paste data
			my %layerLim = CamJob->GetLayerLimits2( $inCAM, $jobId, $stepName, $topLayer->{"gROWname"} );
			my %dataSize = ();
			$dataSize{"w"} = abs( $layerLim{"xMax"} - $layerLim{"xMin"} );
			$dataSize{"h"} = abs( $layerLim{"yMax"} - $layerLim{"yMin"} );

			# position of paste data within paste profile
			$dataSize{"x"} = $layerLim{"xMin"} - $profLim{"xMin"};
			$dataSize{"y"} = $layerLim{"yMin"} - $profLim{"yMin"};

			$size{"top"} = \%dataSize;
		}
		if ($botLayer) {

			# bot normal
			# limits of paste data
			my %layerLim = CamJob->GetLayerLimits2( $inCAM, $jobId, $stepName, $botLayer->{"gROWname"} );
			my %dataSize = ();
			$dataSize{"w"} = abs( $layerLim{"xMax"} - $layerLim{"xMin"} );
			$dataSize{"h"} = abs( $layerLim{"yMax"} - $layerLim{"yMin"} );

			# position of paste data within paste profile
			$dataSize{"x"} = $layerLim{"xMin"} - $profLim{"xMin"};
			$dataSize{"y"} = $layerLim{"yMin"} - $profLim{"yMin"};

			$size{"bot"} = \%dataSize;

			# bot mirrored
			my %dataSizeMirr = ();

			CamHelper->SetStep( $inCAM, $stepName );
			my $mirr = GeneralHelper->GetGUID();
			$inCAM->COM( 'flatten_layer', "source_layer" => $botLayer->{"gROWname"}, "target_layer" => $mirr );
			CamLayer->MirrorLayerByProfCenter( $inCAM, $jobId, $stepName, $mirr, "y" );
			my %layerLimMir = CamJob->GetLayerLimits2( $inCAM, $jobId, $stepName, $mirr );
			$inCAM->COM( 'delete_layer', layer => $mirr );


			# limits of paste data
			$dataSizeMirr{"w"} = abs( $layerLimMir{"xMax"} - $layerLimMir{"xMin"} );
			$dataSizeMirr{"h"} = abs( $layerLimMir{ "yMax" } -$layerLimMir{"yMin"} );

			# position of paste data within paste profile
			$dataSizeMirr{"x"} = $layerLimMir{"xMin"} - $profLim{"xMin"};
			$dataSizeMirr{"y"} = $layerLimMir{"yMin"} - $profLim{"yMin"};

			$size{"botMirror"} = \%dataSizeMirr;
		}

		$stepsSize{$stepName} = \%size;
	}

	$form->Init( \%stepsSize, \@steps, defined $topLayer ? 1 : 0, defined $botLayer ? 1 : 0 );

}

sub SetDefaultData {

}

sub CheckStencilData {

}

# ================================================================================
# FORM HANDLERS
# ================================================================================

# ================================================================================
# PRIVATE METHODS
# ================================================================================

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::StencilCreator::StencilCreator';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

	my $creator = StencilCreator->new( $inCAM, $jobId );
	$creator->Run();

}

1;

