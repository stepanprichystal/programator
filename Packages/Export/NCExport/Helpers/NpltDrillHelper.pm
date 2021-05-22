
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
use List::Util qw(first);
use Storable qw(dclone);

#local library
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => 'EnumsDTM';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub SeparateNpltDrill {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $NCLayersSett = shift;

	my $movedPads = 0;

	my $bot2top = scalar( CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_bMillBot ) ) ? 1 : 0;

	# f layer => d

	my $step = "panel";

	$movedPads += $self->__SplitNpltDrill( $inCAM, $jobId, "f", "d" . ( $bot2top ? "s" : "" ), $bot2top, undef, $NCLayersSett );

	# fsch layer => pom

	$movedPads += $self->__SplitNpltDrill( $inCAM, $jobId, "fsch", "fsch_d" . ( $bot2top ? "s" : "" ), $bot2top, 1, $NCLayersSett );

	return $movedPads;

}

sub RestoreNpltDrill {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $movedPads = shift;

	my $restoredPads = 0;

	my $bot2top = scalar( CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_bMillBot ) ) ? 1 : 0;

	$restoredPads += $self->__MergeNpltDrill( $inCAM, $jobId, "d" . ( $bot2top ? "s" : "" ), "f" );

	$restoredPads += $self->__MergeNpltDrill( $inCAM, $jobId, "fsch_d" . ( $bot2top ? "s" : "" ), "fsch", 1 );

	if ( $movedPads != $restoredPads ) {
		die "Separated pad cnt ($movedPads) != restored pad cnt ($restoredPads)";
	}
}

sub __SplitNpltDrill {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $from         = shift;
	my $to           = shift;
	my $bot2top      = shift;
	my $nonStandard  = shift;
	my $NCLayersSett = shift;

	my $movedPads = 0;

	return 0 unless ( CamHelper->LayerExists( $inCAM, $jobId, $from ) );

	if ( CamHelper->LayerExists( $inCAM, $jobId, $to ) ) {

		die "Something is wrong, layer \"$to\" shouldn't exist, but exists";

		#CamMatrix->DeleteLayer( $inCAM, $jobId, $to );
	}

	#CamMatrix->CreateLayer( $inCAM, $jobId, $to, "drill", "positive", ( $nonStandard ? 0 : 1 ) );
	CamMatrix->CreateLayer( $inCAM, $jobId, $to, "drill", "positive", 1 );

	# if direction is top2bot but, there is z-axis from bot, change dir b2t
	if ($bot2top) {
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
	else {

		# Add NC layer settings for new layer (inherit from source layer)
		my $lSet = dclone( first { $_->{"name"} eq $from } @{$NCLayersSett} );
		$lSet->{"name"} = $to;
		push( @{$NCLayersSett}, $lSet );

	}

	return $movedPads;
}

sub __MergeNpltDrill {
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

		my $unitDTM = UniDTM->new( $inCAM, $jobId, $s, $layerName, 1 );
		my $mess = "";
		unless ( $unitDTM->GetChecks()->CheckTools( \$mess ) ) {

			die "Tools definition in layer: " . $self->{"layer"} . " is wrong.\n $mess";
		}
		my @uniDTMTools = grep { $_->GetSource() eq EnumsDTM->Source_DTM } $unitDTM->GetTools();

		my $sel = CamFilter->ByTypes( $inCAM, ["pad"] );

		if ($sel) {

			$movedCnt += $sel;
			CamLayer->MoveSelOtherLayer( $inCAM, $targetLayer );

			# if some holes have tolerances, set DTM
			my @holeTol =
			  grep { ( $_->GetTolPlus() > 0 || $_->GetTolMinus() > 0 ) && $_->GetTypeProcess() eq EnumsDrill->TypeProc_HOLE } @uniDTMTools;

			if (@holeTol) {

				my @toolsTarget = CamDTM->GetDTMTools( $inCAM, $jobId, $s, $targetLayer, 0 );

				foreach my $uniDTMTool (@holeTol) {

					foreach my $t ( grep { $_->{"gTOOLdrill_size"} eq $uniDTMTool->GetDrillSize() && $_->{"gTOOLshape"} eq "hole" } @toolsTarget ) {

						$t->{"gTOOLmin_tol"}     = $uniDTMTool->GetTolMinus();
						$t->{"gTOOLmax_tol"}     = $uniDTMTool->GetTolPlus();
						$t->{"gTOOLfinish_size"} = $uniDTMTool->GetFinishSize();

					}
				}

				CamDTM->SetDTMTools( $inCAM, $jobId, $s, $targetLayer, \@toolsTarget );

			}

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

