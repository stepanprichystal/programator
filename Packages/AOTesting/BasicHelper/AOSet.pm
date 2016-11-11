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
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';

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
	my @routLayer  = ();
	my $cuThick    = 0;
	my $pcbThick   = 0;

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	my @pltLayer = CamDrilling->GetPltNCLayers( $inCAM, $jobId );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@pltLayer );

	# get plated drill layers, which goes from <$layerName>
	@drillLayer = grep { $_->{"gROWlayer_type"} eq "drill" } @pltLayer;

	@drillLayer = grep {
		$_->{"gROWdrl_start_name"} eq $layerName
		  || (
			   $_->{"gROWdrl_end_name"} eq $layerName
			&& $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bDrillTop
			&& $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bDrillBot
		  )
	} @drillLayer;

	@drillLayer = map { $_->{"gROWname"} } @drillLayer;

	# get plated rout, which goes from <$layerName>

	@routLayer = grep { $_->{"gROWlayer_type"} eq "rout" } @pltLayer;
	@routLayer = grep { $_->{"gROWdrl_start_name"} eq $layerName || $_->{"gROWdrl_end_name"} eq $layerName } @routLayer;

	if ( scalar(@routLayer) ) {

		my $lTmpName = "aoi_rout_tmp";

		if ( CamHelper->LayerExists( $inCAM, $jobId, $lTmpName ) ) {

			$inCAM->COM( 'delete_layer', "layer" => $lTmpName );
		}

		$inCAM->COM( 'create_layer', "layer" => $lTmpName, "context" => 'board', "type" => 'drill', "polarity" => 'positive', "ins_layer" => '' );

		# get all nested steps
		my @steps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $stepName );

		foreach my $nestStep (@steps) {
 
			$inCAM->COM( "set_step", "name" => $nestStep->{"stepName"} );
 
			foreach my $l (@routLayer) {

				my $lName = GeneralHelper->GetGUID();

				$inCAM->COM( "compensate_layer", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName, "dest_layer_type" => "document" );
				
				CamLayer->WorkLayer($inCAM, $lName);
				$inCAM->COM( "sel_contourize", "accuracy" => "6.35", "break_to_islands" => "yes", "clean_hole_size" => "76.2", "clean_hole_mode" => "x_or_y" );

				 
				$inCAM->COM(
					"copy_layer",
					"dest"         => "layer_name",
					"source_job"   => $jobId,
					"source_step"  => $nestStep->{"stepName"},
					"source_layer" => $lName,

					"dest_step"  => $nestStep->{"stepName"},
					"dest_layer" => $lTmpName,
					"mode"       => "append",
					"invert"     => "no"
				);
 

				$inCAM->COM( "delete_layer", "layer" => $lName );

			}

		}
		
		# copy frame from "m" to aoiTempLayer
		# in order, we could add aoiTempLayer to AOI set. Layer can not be empty
		$inCAM->COM(
					"copy_layer",
					"dest"         => "layer_name",
					"source_job"   => $jobId,
					"source_step"  => "panel",
					"source_layer" => "m",

					"dest_step"  => "panel",
					"dest_layer" => $lTmpName,
					"mode"       => "append",
					"invert"     => "no"
				);
		

		push( @drillLayer, $lTmpName );
	}

	if ( $layerCnt <= 2 ) {

		$cuThick = HegMethods->GetOuterCuThick( $jobId, $layerName );
		$pcbThick = HegMethods->GetPcbMaterialThick($jobId);

	}
	else {

		my $cuLayer = $stackup->GetCuLayer($layerName);
		$cuThick  = $cuLayer->GetThick();
		$pcbThick = $stackup->GetThickByLayerName($layerName);

	}

	
	$inCAM->COM( "set_step", "name" => $stepName );
 
	my $drill = join( "\;", @drillLayer );
	$inCAM->COM(
		"cdr_set_stage",
		"stage"         => "BARE_COPPER",
		"drill"         => $drill,
		"layer"         => $layerName,
		"copper_weight" => $cuThick,
		"panel_thick"   => $pcbThick * 1000    #in µm
	);

}

sub OutputOpfx {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $layerName    = shift;
	my $incamResult  = shift;
	my $reportResult = shift;

	my $exportPath = JobHelper->GetJobArchive($jobId) . "zdroje\\ot";

	unless ( -e $exportPath ) {
		mkdir($exportPath) or die "Can't create dir: " .  $exportPath;
	}

	my $report = EnumsPaths->Client_INCAMTMPAOI . $jobId;

	if ( -e $report ) {
		unlink($report);
	}

	$$incamResult = $inCAM->COM(
								 "cdr_opfx_output",
								 "units"              => "inch",
								 "anchor_mode"        => "zero",
								 "target_machine"     => "v300",
								 "output_layers"      => "affected",
								 "break_surf"         => "yes",
								 "break_arc"          => "yes",
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
								 "multi_trg_machines" => "discovery",
								 "report_file"        => $report
	);

	# delete rout temporary layer
	if ( CamHelper->LayerExists( $inCAM, $jobId, "aoi_rout_tmp" ) ) {

		 
	 	$inCAM->COM( 'delete_layer', "layer" => "aoi_rout_tmp" );
	}

	if ( -e $report ) {

		$$reportResult = "";
		my $f;
		open( $f, $report );
		while (<$f>) { $$reportResult .= $_ }
		close($f);

		if ( $$reportResult !~ /no output/i ) {
			$$reportResult = "";
		}

	}

	#if ok, InCAm return 0
	if ( $$reportResult ne "" || $$incamResult > 0 ) {
		return 0;
	}
	else {
		return 1;
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#	use aliased 'Packages::InCAM::InCAM';
#	use aliased 'Packages::ETesting::BasicHelper::OptSet';
#	use aliased 'Packages::ETesting::BasicHelper::ETSet';
#	my $inCAM = InCAM->new();
#
#	my $jobName      = "f13610";
#	my $stepName     = "panel";
#	my $setupOptName = "atg_flying";
#	my @steps        = ( "o+1", "mpanel" );
#
#	my $optName = OptSet->OptSetCreate( $inCAM, $jobName, $stepName, $setupOptName, \@steps );
#
#	my $etsetName = ETSet->ETSetCreate( $inCAM, $jobName, $stepName, $optName );
#
#	ETSet->ETSetOutput( $inCAM, $jobName, $stepName, $optName, $etsetName );
#
#	if ( ETSet->ETSetExist( $inCAM, $jobName, $stepName, $optName, $etsetName ) ) {
#
#		ETSet->ETSetDelete( $inCAM, $jobName, $stepName, $optName, $etsetName );
#	}
#
#	if ( OptSet->OptSetExist( $inCAM, $jobName, $stepName, $optName ) ) {
#
#		OptSet->OptSetDelete( $inCAM, $jobName, $stepName, $optName );
#	}

}

1;
