#-------------------------------------------------------------------------------------------#
# Description: Wrapper for InCAM electrical set function
# Author: SPR
#-------------------------------------------------------------------------------------------#

package Packages::AOTesting::BasicHelper::AOSet;

#3th party library
use strict;
use warnings;

#loading of locale modules
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Enums';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
# delete et set
sub SetStage {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;
	my $stackup   = shift;

	# variables to fill
	my @drillLayer = ();
	my $cuThick    = 0;
	my $pcbThick   = 0;

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	# get plated drill layers, which goes from <$layerName>
	@drillLayer = CamDrilling->GetPltNCLayers( $inCAM, $jobId );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@drillLayer );
	@drillLayer = grep { $_->{"gROWdrl_start_name"} eq $layerName } @drillLayer;
	
	@drillLayer = map { $_->{"gROWname"} } @drillLayer;

	if ( $layerCnt <= 2 ) {

		$cuThick = HegMethods->GetOuterCuThick( $jobId, $layerName );
		$pcbThick = HegMethods->GetPcbMaterialThick($jobId);

	}
	else {

		my $cuLayer = $stackup->GetCuLayer($layerName);
		$cuThick  = $cuLayer->GetThick();
		$pcbThick = $stackup->GetThickByLayerName($layerName);

	}

	my $drill = join( "\;", @drillLayer );
	$inCAM->COM(
		"cdr_set_stage",
		"stage"         => "BARE_COPPER",
		"drill"         => $drill,
		"layer"         => $layerName,
		"copper_weight" => $cuThick,
		"panel_thick"   => $pcbThick*1000 #in µm
	);

}

sub OutputOpfx {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $layerName = shift;

	my $exportPath = JobHelper->GetJobArchive($jobId) . "zdroje\\ot";

	unless ( -e $exportPath ) {
		mkdir($exportPath) or die "Can't create dir: " . $exportPath . $_;
	}

	my $result = $inCAM->COM(
				 "cdr_opfx_output",
				 "units"              => "inch",
				 "anchor_mode"        => "zero",
				 "target_machine"     => "v300",
				 "output_layers"      => "affected",
				 "break_surf"         => "no",
				 "break_arc"          => "no",
				 "break_sr"           => "yes",
				 "break_fsyms"        => "no",
				 "upkit"              => "yes",
				 "contourize"         => "no",
				 "units_factor"       => "0.001",
				 "scale_x"            => "1",
				 "scale_y"            => "1",
				 "accuracy"           => "0.2",
				 "anchor_x"           => "0",
				 "anchor_y"           => "0",
				 "min_brush"          => "25.4",
				 "path"               => $exportPath,
				 "multi_trg_machines" => "discovery"
	);
	
	
	#if ok, InCAm return 0
	if ( $result == 0 ) {
		return 1;
	}
	else {
		return 0;
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::ETesting::BasicHelper::OptSet';
	use aliased 'Packages::ETesting::BasicHelper::ETSet';
	my $inCAM = InCAM->new();

	my $jobName      = "f13610";
	my $stepName     = "panel";
	my $setupOptName = "atg_flying";
	my @steps        = ( "o+1", "mpanel" );

	my $optName = OptSet->OptSetCreate( $inCAM, $jobName, $stepName, $setupOptName, \@steps );

	my $etsetName = ETSet->ETSetCreate( $inCAM, $jobName, $stepName, $optName );

	ETSet->ETSetOutput( $inCAM, $jobName, $stepName, $optName, $etsetName );

	if ( ETSet->ETSetExist( $inCAM, $jobName, $stepName, $optName, $etsetName ) ) {

		ETSet->ETSetDelete( $inCAM, $jobName, $stepName, $optName, $etsetName );
	}

	if ( OptSet->OptSetExist( $inCAM, $jobName, $stepName, $optName ) ) {

		OptSet->OptSetDelete( $inCAM, $jobName, $stepName, $optName );
	}

}

1;
