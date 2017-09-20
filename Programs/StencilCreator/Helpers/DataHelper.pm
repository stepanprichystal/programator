
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Helpers::DataHelper;

#3th party library
use utf8;
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
use aliased 'Programs::StencilCreator::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub SetSourceData {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $dataMngr  = shift;

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
			$dataSizeMirr{"h"} = abs( $layerLimMir{"yMax"} - $layerLimMir{"yMin"} );

			# position of paste data within paste profile
			$dataSizeMirr{"x"} = $layerLimMir{"xMin"} - $profLim{"xMin"};
			$dataSizeMirr{"y"} = $layerLimMir{"yMin"} - $profLim{"yMin"};

			$size{"botMirror"} = \%dataSizeMirr;
		}

		$stepsSize{$stepName} = \%size;
	}

	$dataMngr->Init( \%stepsSize, \@steps, defined $topLayer ? 1 : 0, defined $botLayer ? 1 : 0 );

}

sub SetDefaultData {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $dataMngr     = shift;
	my $custNote = shift;
	my $mess     = shift;

	my $orderInfo = HegMethods->GetAllByPcbIdOffer($jobId);
	my $pcbInfo   = (HegMethods->GetAllByPcbId($jobId))[0];

	# 1) try parse type of stencil
	my $stencilType = Enums->StencilType_TOP;

	if ( $pcbInfo->{"board_name"} =~ /top/i && $pcbInfo->{"board_name"} =~ /bot/i ) {
		$stencilType = Enums->StencilType_TOPBOT;

	}
	elsif ( $pcbInfo->{"board_name"} =~ /top/i ) {

		$stencilType = Enums->StencilType_TOP;

	}
	elsif ( $pcbInfo->{"board_name"} =~ /bot/i ) {

		$stencilType = Enums->StencilType_BOT;

	}
	else {

		$$mess .= "Nebyl dohledán typ šablony (top, bot, top+bot) v IS. Bude nastaven defaultní typ: \"TOP\".\n";
	}

	$dataMngr->SetStencilType($stencilType);

	# 2) set step
	if ( grep { $_ =~ /mpanel/ } @{ $dataMngr->{"steps"} } ) {
		$dataMngr->SetStencilStep("mpanel");
	}

	# 3) stencil size
	my ( $w, $h ) = undef;
	if ( $orderInfo->{"Poznamka_deska"} =~ /(\d+)\s*x\s*(\d*)/i ) {

		if ( $1 > 0 && $2 > 0 ) {
			$w = $1;
			$h = $2;

			if ( $w > $h ) {
				( $w, $h ) = ( $h, $w );
			}
		}
	}

	if ( !defined $w || !defined $h ) {

		$$mess .= "Nebyl dohledán rozměr rozměr šablony v IS. Bude nastaven defaultní rozměr 300x480mm\n";
		$w = 300;
		$h = 480;
	}

	$dataMngr->SetStencilSizeX( $w );
	$dataMngr->SetStencilSizeY( $h );

	# 4) Schema type
	my $schemaType = Enums->Schema_STANDARD;
	if ( $orderInfo->{"Poznamka_deska"} =~ /vlepe|rám/i ) {

		$schemaType = Enums->Schema_FRAME;
	}

	$dataMngr->SetSchemaType($schemaType);

	if ( $schemaType eq Enums->Schema_STANDARD ) {

		# 5) Hole size
		$dataMngr->SetHoleSize(5.1);

		# 6) Hole distance x
		if ( $custNote->HoleDistX() ) {
			$dataMngr->SetHoleDist( $custNote->HoleDistX() );
		}
		else {
			$dataMngr->SetHoleDist(15);    # default 15 mm
		}

		# 6) Hole distance y
		if ( $custNote->HoleDistY() ) {

			$dataMngr->SetHoleDist2( $custNote->HoleDistY() );
		}
		else {

			# compute hole dist 15 mm from top/bot border
			$dataMngr->SetHoleDist2( $h - 2 * 15 );
		}

	}

	if ( $stencilType eq Enums->StencilType_TOPBOT ) {

		# 7) Spacing type
		$dataMngr->SetSpacingType( Enums->Spacing_PROF2PROF );

		# 8) Set distance between profiles
		$dataMngr->SetSpacing(0);

	}
	
	# 9) Hole distance y
	if ( $custNote->CenterByData() ) {
		
		$dataMngr->SetHCenterType(Enums->HCenter_BYDATA);
	}else{
		
		$dataMngr->SetHCenterType(Enums->HCenter_BYPROF);
	}

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

