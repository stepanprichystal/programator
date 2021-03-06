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
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamDrilling';

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
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $stepName   = shift;
	my $layerName  = shift;
	my $cuThick    = shift;
	my $pcbThick   = shift;
	my $etchFactor = shift;

	# variables to fill
	my @drillLayer = ();
	my @routLayer  = ();

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	my @pltLayer = CamDrilling->GetPltNCLayers( $inCAM, $jobId );
	push( @pltLayer, CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_rsMill ) )
	  ;                        # add rs layer, because it is done before AOI testing too
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@pltLayer );

	# get plated drill layers, which goes from <$layerName>
	@drillLayer = grep { $_->{"gROWlayer_type"} eq "drill" } @pltLayer;

	# Remove blind drill
	@drillLayer = grep {
		     $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_nFillDrill
		  && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bFillDrillTop
		  && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bFillDrillBot
		  && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cFillDrill
	} @drillLayer;

	@drillLayer = grep {
		$_->{"NCSigStart"} eq $layerName
		  || (    $_->{"NCSigEnd"} eq $layerName
			   && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bDrillTop
			   && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bDrillBot )
	} @drillLayer;

	@drillLayer = map { $_->{"gROWname"} } @drillLayer;

	# get plated rout, which goes from <$layerName>

	@routLayer = grep { $_->{"gROWlayer_type"} eq "rout" } @pltLayer;
	@routLayer = grep { $_->{"NCSigStart"} eq $layerName || $_->{"NCSigEnd"} eq $layerName } @routLayer;

	if ( scalar(@routLayer) ) {

		my $lTmpName = "aoi_rout_tmp";

		if ( CamHelper->LayerExists( $inCAM, $jobId, $lTmpName ) ) {

			$inCAM->COM( 'delete_layer', "layer" => $lTmpName );
		}

		$inCAM->COM( 'create_layer', "layer" => $lTmpName, "context" => 'board', "type" => 'drill', "polarity" => 'positive', "ins_layer" => '' );

		# get all nested steps
		my @steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $stepName );

		foreach my $nestStep ( @steps, $stepName ) {

			CamHelper->SetStep($inCAM, $nestStep);
			 

			foreach my $l (@routLayer) {

				my $lName = GeneralHelper->GetGUID();

				$inCAM->COM( "compensate_layer", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName, "dest_layer_type" => "document" );

				CamLayer->WorkLayer( $inCAM, $lName );
				$inCAM->COM(
							 "sel_contourize",
							 "accuracy"         => "6.35",
							 "break_to_islands" => "yes",
							 "clean_hole_size"  => "76.2",
							 "clean_hole_mode"  => "x_or_y"
				);

				$inCAM->COM(
							 "copy_layer",
							 "dest"         => "layer_name",
							 "source_job"   => $jobId,
							 "source_step"  => $nestStep,
							 "source_layer" => $lName,
							 "dest_step"    => $nestStep,
							 "dest_layer"   => $lTmpName,
							 "mode"         => "append",
							 "invert"       => "no"
				);

				$inCAM->COM( "delete_layer", "layer" => $lName );

			}

		}

		#		# copy frame from "v" to aoiTempLayer
		#		# in order, we could add aoiTempLayer to AOI set. Layer can not be empty
		#		$inCAM->COM(
		#			"copy_layer",
		#			"dest"         => "layer_name",
		#			"source_job"   => $jobId,
		#			"source_step"  => "panel",
		#			"source_layer" => "v",
		#
		#			"dest_step"  => "panel",
		#			"dest_layer" => $lTmpName,
		#			"mode"       => "append",
		#			"invert"     => "no"
		#		);

		push( @drillLayer, $lTmpName );
	}
	
	CamHelper->SetStep($inCAM, $stepName);
	 

	my $drill = join( "\;", @drillLayer );
	$inCAM->COM(
		"cdr_set_stage",
		"stage"         => "BARE_COPPER",
		"drill"         => $drill,
		"layer"         => $layerName,
		"copper_weight" => $cuThick,
		"panel_thick"   => $pcbThick,       #in mm
		"etch"          => $etchFactor
	);

}

sub OutputOpfx {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $exportPath   = shift;
	my $layerName    = shift;
	my $machineName  = shift;
	my $incamResult  = shift;
	my $reportResult = shift;

	unless ( -e $exportPath ) {
		mkdir($exportPath) or die "Can't create dir: " . $exportPath;
	}

	# remove slash
	$exportPath =~ s/\\$//i;

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
								 "multi_trg_machines" => $machineName,
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
