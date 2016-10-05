
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::AOIExport::AOIMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::ETesting::BasicHelper::OptSet';
use aliased 'Packages::ETesting::BasicHelper::ETSet';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::AOTesting::BasicHelper::AOSet';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamDrilling';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"stepToTest"} = shift;    # step, which will be tested
	$self->{"attemptCnt"} = 20;       # max count of attempt

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};
	my $stepToTest = $self->{"stepToTest"};
	my $layerName  = $self->{"layer"};

	my @signalLayers = CamJob->GetSignalLayerNames( $inCAM, $jobId );

	if ( $self->{"layerCnt"} > 2 ) {
		$self->{"stackup"} = Stackup->new($jobId);
	}

	# Delete old files
	$self->__DeleteOutputFiles();

	#open et step
	#$inCAM->COM( "set_step", "name" => $stepToTest );
	$inCAM->COM( 'open_entity', job => $jobId, type => 'step', name => $stepToTest, iconic => 'no' );
	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );

	my $setName = "cdr";

	#my $setName = GeneralHelper->GetGUID();

	print STDERR "\n\n=====================SET NAME======================== $setName\n\n";

	#my $strLayers = join("\;", @signalLayers);

	#$inCAM->COM("cdr_delete_sets_by_name","layers" => "","sets" => $setName);

	#$inCAM->COM("delete_entity","job" => $jobId,"name" => $setName, "type" => "cdr");

	# Raise result item for optimization set
	my $resultItemOpenSession = $self->_GetNewItem("Open AOI session");

	# try take AOI interface. If seats occupied, try again in two sec
	foreach ( my $i = 0 ; $i < $self->{"attemptCnt"} ; $i++ ) {

		$self->__OpenAOISession($setName);
		my $ex = $inCAM->GetException();

		# test if max session seats exceeded
		if ( $ex && $ex->{"errorId"} == 282002 ) {

			#print STDERR "Waiting n AOI seats..\n";
			sleep(2);
		}
		else {
			last;
		}
	}

	$resultItemOpenSession->AddErrors( $inCAM->GetExceptionsError() );
	$self->_OnItemResult($resultItemOpenSession);

	$inCAM->COM( "cdr_set_current_cdr_name", "job" => $jobId, "step" => $stepToTest, "set_name" => $setName );

	#$inCAM->COM( "cdr_clear_displayed_layers", );
	$inCAM->COM(
				 "cdr_create_configuration",
				 "set_name" => "",
				 "cfg_name" => "discoveryDefaultConfiguration",
				 "cfg_path" => "//incam/incam_server/site_data/hooks/cdr",
				 "sub_dir"  => "discovery"
	);
	$inCAM->COM( "cdr_set_machine", "machine" => "discovery", "cfg_name" => "discoveryDefaultConfiguration" );
	$inCAM->COM( "cdr_set_table", "set_name" => "", "name" => "27x24", "x_dim" => "685.8", "y_dim" => "609.6" );

	# un affected all layer
	foreach my $l (@signalLayers) {

		$inCAM->COM( "cdr_affected_layer", "mode" => "off", "layer" => $l );
		$inCAM->COM( "cdr_display_layer", "name" => "$l", "display" => "no", "type" => "physical" );

	}

	# For each layer export AOI
	foreach my $layer (@signalLayers) {

		# For each layer export AOI
		$self->__ExportAOI( $layer, $setName );
	}

	# After export, release licence/ close seeeion
	$inCAM->COM("cdr_close");

}

# Function try to open session manager
sub __OpenAOISession {
	my $self       = shift;
	my $setName    = shift;
	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};
	my $stepToTest = $self->{"stepToTest"};

	# START HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(1);

	$inCAM->COM(
				 "cdr_open_session",
				 "job"       => $jobId,
				 "step"      => $stepToTest,
				 "set_name"  => $setName,
				 "interface" => "discovery",
				 "cfg_type"  => "user_defined_cfg",
				 "cfg_name"  => "discoveryDefaultConfiguration",
				 "cfg_path"  => "//incam/incam_server/site_data/hooks/cdr",
				 "sub_dir"   => "discovery"
	);

	print STDERR "\n\n=====================SET NAME======================== $setName\n\n";

	# STOP HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(0);
}

sub __ExportAOI {

	my $self = shift;

	my $layerName = shift;
	my $setName   = shift;

	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};
	my $stepToTest = $self->{"stepToTest"};

	# ===== Set AOI parameters ======

	## START HANDLE EXCEPTION IN INCAM
	#$inCAM->HandleException(1);

	# Raise result item for optimization set
	#my $resultItemAOIparams = $self->_GetNewItem("Set params - $layerName");


	$inCAM->COM( "cdr_display_layer", "name" => $layerName, "display" => "yes", "type" => "physical" );

	#$inCAM->COM( "work_layer", "name" => $layerName );
	$inCAM->COM( "cdr_work_layer", "layer" => $layerName );


	# Param set driils
	AOSet->SetStage( $inCAM, $jobId, $stepToTest, $layerName, $self->{"stackup"} );

	# Set nominal space, line

	$inCAM->COM( "cdr_get_nom_line", "layer" => "c" );
	my $line = $inCAM->GetReply();

	$inCAM->COM( "cdr_get_nom_space", "layer" => "c", "space_type" => "nom_space" );
	my $space = $inCAM->GetReply();

	# If Incam didn't compute values, set it by construction class
	if ( $line == 0 || $space == 0 ) {

		my $class = CamJob->GetJobPcbClass( $inCAM, $jobId );
		my $isolation = JobHelper->GetIsolationByClass($class);

		$line  = $isolation;
		$space = $isolation;
	}

	$inCAM->COM( "cdr_line_width", "nom_width" => $line,  "min_width" => "0" );
	$inCAM->COM( "cdr_spacing",    "nom_space" => $space, "min_space" => "0" );

	# Set steps and repeat

	my @steps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $stepToTest );

	@steps = map { $_->{"stepName"} } @steps;

	my $stepsStr = join( "\;", @steps );
	$inCAM->COM( "cdr_set_area_auto", "steps" => $stepsStr, "margin_x" => "0", "margin_y" => "0", "inspected_steps" => "" );

	# Exclude texts from test
	$inCAM->COM( "cdr_auto_zone_text", "margin" => "0", "pcb" => "yes", "panel" => "no" );

	# STOP HANDLE EXCEPTION IN INCAM
	#$inCAM->HandleException(0);

	#$resultItemAOIparams->AddErrors( $inCAM->GetExceptionsError() );
	#$self->_OnItemResult($resultItemAOIparams);

	# ===== Do AOI output ======

	my $incamResult;
	my $reportResult;

	# START HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(1);

	# Raise result item for optimization set
	my $resultItemAOIOutput = $self->_GetNewItem($layerName);
	$resultItemAOIOutput->SetGroup("Layers");

	my $result = AOSet->OutputOpfx( $inCAM, $jobId, $layerName, \$incamResult, \$reportResult );

	# STOP HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(0);

	if ( $result == 0 ) {

		if ( $incamResult > 0 ) {
			$resultItemAOIOutput->AddErrors( $inCAM->GetExceptionsError() );
		}

		if ( $reportResult ne "" ) {
			$resultItemAOIOutput->AddError($reportResult);
		}
	}

	$self->_OnItemResult($resultItemAOIOutput);

}

sub __CreateTmpRoutLayer {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};
	my $stepToTest = $self->{"stepToTest"};

	my @pltLayer = CamDrilling->GetPltNCLayers( $inCAM, $jobId );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@pltLayer );

	# get plated rout, which goes from <$layerName>
	my @routLayer = grep { $_->{"gROWdrl_start_name"} eq $layerName && $_->{"gROWlayer_type"} eq "rout" } @pltLayer;

	if ( scalar(@routLayer) ) {

		my $lTmpName = "aoi_rout_tmp";

		if ( CamHelper->LayerExists( $inCAM, $jobId, $lTmpName ) ) {

			$inCAM->COM( 'delete_layer', "layer" => $lTmpName );
		}

		$inCAM->COM( 'create_layer', "layer" => $lTmpName, "context" => 'board', "type" => 'drill', "polarity" => 'positive', "ins_layer" => '' );

		my @steps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $stepToTest );

		foreach my $nestStep (@steps) {

			CamHelper->OpenStep( $inCAM, $jobId, $nestStep->{"stepName"} );

			foreach my $l (@routLayer) {

				my $lName = GeneralHelper->GetGUID();

				$inCAM->COM( "compensate_layer", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName, "dest_layer_type" => "document" );
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
	}
}

# Delete all files from ot dir
sub __DeleteOutputFiles {
	my $self = shift;

	my $path = JobHelper->GetJobArchive( $self->{"jobId"} ) . "zdroje\\ot\\";
	my $dir;

	if ( opendir( $dir, $path ) ) {
		while ( my $file = readdir($dir) ) {
			next if ( $file =~ /^\.$/ );
			next if ( $file =~ /^\.\.$/ );
			unlink $path . $file;
		}
		closedir($dir);
	}
}

sub ExportItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 1;                      # getting sucesfully AOI manager
	$totalCnt += $self->{"layerCnt"};    #export each layer

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::AOIExport::AOIMngr';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobName   = "f13610";
	my $stepName  = "panel";
	my $layerName = "c";

	my $mngr = AOIMngr->new( $inCAM, $jobName, $stepName, $layerName );
	$mngr->Run();
}

1;

