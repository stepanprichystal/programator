
#-------------------------------------------------------------------------------------------#
# Description: Create temporarz nplt drill layer "d". Thus "f" layer data are before export
# separated. Holes are in new layer "d". After export are data returned back
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::Helpers::NpltDrillHelper;

#3th party library
use strict;
use warnings;
use File::Copy;
use Try::Tiny;

#local library
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
 

sub SeparateNpltDrill {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $movedPads = 0;

	# f layer => d

	my $step = "panel";

	$movedPads += $self->__CreateNpltDrill( $inCAM, $jobId, "f", "d" );

	# fsch layer => pom

	$movedPads += $self->__CreateNpltDrill( $inCAM, $jobId, "fsch", "fsch_nplt_ndrill", 1 );

	return $movedPads;

}

sub RestoreNpltDrill {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $movedPads = shift;

	my $restoredPads = 0;

	$restoredPads += $self->__RemoveNpltDrill( $inCAM, $jobId, "d", "f" );

	$restoredPads += $self->__RemoveNpltDrill( $inCAM, $jobId, "fsch_nplt_ndrill", "fsch", 1 );

	if ( $movedPads != $restoredPads ) {
		die "Spearete pad cnt ($movedPads) != resoted pad cnt ($restoredPads)";
	}
}

sub __CreateNpltDrill {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $from        = shift;
	my $to          = shift;
	my $nonStandard = shift;

	my $movedPads = 0;

	return 0 unless ( CamHelper->LayerExists( $inCAM, $jobId, $from ) );

	if ( CamHelper->LayerExists( $inCAM, $jobId, $to ) ) {

		die "Something is wrong, layer \"$to\" shouldn't exist, but exists";
		#CamMatrix->DeleteLayer( $inCAM, $jobId, $to );
	}

	CamMatrix->CreateLayer( $inCAM, $jobId, $to, "drill", "positive", ( $nonStandard ? 0 : 1 ) );

	# if direction is top2bot but, there is z-axis from bot, change dir b2t
	if ( scalar( CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_bMillBot ) ) ) {
		CamMatrix->SetLayerDirection( $inCAM, $jobId, $to, "bottom_to_top" );
	}

	# set t2b
	else {
		CamMatrix->SetLayerDirection( $inCAM, $jobId, $to, "top_to_bottom" );
	}

	$movedPads += $self->__MovePads( $inCAM, $jobId, $from, $to, $nonStandard );

	# remove layers, if 0 moved pads
	if ( $movedPads == 0 ) {

		CamMatrix->DeleteLayer( $inCAM, $jobId, $to );
	}

	return $movedPads;
}

sub __RemoveNpltDrill {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $from        = shift;
	my $to          = shift;
	my $nonStandard = shift;

	return 0 unless ( CamHelper->LayerExists( $inCAM, $jobId, $from ) );

	my $movedPads = 0;

	$movedPads += $self->__MovePads( $inCAM, $jobId, $from, $to, $nonStandard );

	CamMatrix->DeleteLayer( $inCAM, $jobId, $from );

	return $movedPads;
}

sub __MovePads {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $layerName   = shift;
	my $targetLayer = shift;
	my $nonStandard = shift;

	my $movedCnt = 0;

	my @steps = ();

	if ($nonStandard) {

		@steps = ("panel");
	}
	else {

		@steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" );
	}

	foreach my $s (@steps) {

		CamHelper->SetStep( $inCAM, $s );
		CamLayer->WorkLayer( $inCAM, $layerName );

		my $sel = CamFilter->ByTypes( $inCAM, ["pad"] );

		if ($sel) {

			$movedCnt += $sel;
			CamLayer->MoveSelected( $inCAM, $targetLayer );
		}
	}

	return $movedCnt;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#print $test;

}

1;

