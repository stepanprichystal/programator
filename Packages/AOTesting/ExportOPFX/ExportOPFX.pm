
#-------------------------------------------------------------------------------------------#
# Description: Class responsible for creatuing OT OPFX file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::AOTesting::ExportOPFX::ExportOPFX;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::ItemResult::Enums' => "ItemResEnums";
use aliased 'Packages::AOTesting::BasicHelper::AOSet';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"stepToTest"} = shift;          # step, which will be tested
	$self->{"attemptCnt"} = shift // 50;    # max count of attempt to AOI manager
	                                        # case, when OPFX are created from job which is not in IS and no stackup is created
	                                        # jobId should have then format: Dxxxxxx_ot<\d>
	$self->{"jobCloned"}  = shift // 0;

	# PROPERTIES
	$self->{"machineName"} = "fusion";
	$self->{"layerCnt"}    = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"jobIdSource"} = $self->{"jobId"};

	if ( $self->{"jobCloned"} ) {

		# Extract source job id
		if ( $self->{"jobId"} =~ m/^(\w\d+)_ot\d+$/ ) {
			$self->{"jobIdSource"} = $1;
		}
		else {

			die "Wrong name of job id: " . $self->{"jobId"};
		}
	}

	$self->{"stackup"} = undef;
	if ( $self->{"layerCnt"} > 2 ) {
		$self->{"stackup"} = Stackup->new( $self->{"inCAM"}, $self->{"jobIdSource"} );
	}

	return $self;
}

# Return IPC file path
sub Export {
	my $self           = shift;
	my $exportPath     = shift;            # Keep profiles for SR steps
	my @signalLayers   = @{ shift(@_) };
	my $incldMpanelFrm = shift // 1;       # Ref to storing Test Point report after optimization

	die "Export path is not defined" if ( !defined $exportPath );

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Remove old OPDF files
	$self->__DeleteOutputFiles( $exportPath, \@signalLayers );

	# 2) Try to get AOI manager
	CamHelper->SetStep( $inCAM, $self->{"stepToTest"} );

	my $setName = "cdr";

	# Raise result item for optimization set
	my $resultItemOpenSession = $self->_GetNewItem("Open AOI session");

	# START HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(1);

	# try take AOI interface. If seats occupied, try again in two sec
	foreach ( my $i = 0 ; $i < $self->{"attemptCnt"} ; $i++ ) {

		$self->__OpenAOISession($setName);
		my $ex = $inCAM->GetException();

		# test if max session seats exceeded
		if ( $ex && $ex->{"errorId"} == 282002 ) {

			print STDERR "\n\nTrying to attempt AOI seat (try $i)...\n\n";
			sleep(5);
		}
		else {
			last;
		}
	}

	# STOP HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(0);

	$resultItemOpenSession->AddError( $inCAM->GetExceptionError() );
	$self->_OnItemResult($resultItemOpenSession);

	# Do not continue, if any AOI seats is not free
	if ( $resultItemOpenSession->Result() eq ItemResEnums->ItemResult_Fail ) {

		$result = 0;
		return $result;
	}

	# 3) Create CDR set
	$inCAM->COM( "cdr_set_current_cdr_name", "job" => $jobId, "step" => $self->{"stepToTest"}, "set_name" => $setName );

	$inCAM->COM(
				 "cdr_create_configuration",
				 "set_name" => "",
				 "cfg_name" => $self->{"machineName"} . "DefaultConfiguration",
				 "cfg_path" => "//incam/incam_server/site_data/hooks/cdr",
				 "sub_dir"  => $self->{"machineName"}
	);

	$inCAM->COM( "cdr_set_machine", "machine" => $self->{"machineName"}, "cfg_name" => $self->{"machineName"} . "DefaultConfiguration" );
	$inCAM->COM( "cdr_set_table", "set_name" => "", "name" => "30X30", "x_dim" => "762", "y_dim" => "762" );

	# un affected all layer
	foreach my $l (@signalLayers) {

		$inCAM->COM( "cdr_affected_layer", "mode" => "off", "layer" => $l );
		$inCAM->COM( "cdr_display_layer", "name" => "$l", "display" => "no", "type" => "physical" );
	}

	# 4) Axport OPFX
	foreach my $layer (@signalLayers) {

		# For each layer export AOI
		$self->__ExportAOI( $exportPath, $layer, $setName, $incldMpanelFrm );
	}

	# For each layer export AOI
	foreach my $layer (@signalLayers) {
		$inCAM->COM( "cdr_display_layer", "name" => $layer, "display" => "no", "type" => "physical" );
	}

	# 5) After export, release licence/ close seeeion
	$inCAM->COM("cdr_close");

	return $result;

}

# Function try to open session manager
sub __OpenAOISession {
	my $self    = shift;
	my $setName = shift;

	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};
	my $stepToTest = $self->{"stepToTest"};

	# START HANDLE EXCEPTION IN INCAM

	$inCAM->COM(
				 "cdr_open_session",
				 "job"       => $jobId,
				 "step"      => $stepToTest,
				 "set_name"  => $setName,
				 "interface" => $self->{"machineName"},
				 "cfg_type"  => "user_defined_cfg",
				 "cfg_name"  => $self->{"machineName"} . "DefaultConfiguration",
				 "cfg_path"  => "//incam/incam_server/site_data/hooks/cdr",
				 "sub_dir"   => $self->{"machineName"}
	);

	# STOP HANDLE EXCEPTION IN INCAM

}

sub __ExportAOI {

	my $self           = shift;
	my $exportPath     = shift;
	my $layerName      = shift;
	my $setName        = shift;
	my $incldMpanelFrm = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $jobIdSource = $self->{"jobIdSource"};
	my $stepToTest  = $self->{"stepToTest"};

	# ===== Set AOI parameters ======
	$inCAM->COM( "cdr_display_layer", "name" => $layerName, "display" => "yes", "type" => "physical" );
	$inCAM->COM( "cdr_work_layer", "layer" => $layerName );

	# Param set driils
	my $cuThick  = undef;
	my $pcbThick = undef;

	if ( $self->{"layerCnt"} <= 2 ) {

		$cuThick = HegMethods->GetOuterCuThick( $jobIdSource, $layerName );
		$pcbThick = HegMethods->GetPcbMaterialThick($jobIdSource) * 1000;

	}
	else {

		my %lPars = JobHelper->ParseSignalLayerName($layerName);
		my $IProduct = $self->{"stackup"}->GetProductByLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );
		
		$cuThick =
		  $self->{"stackup"}->GetCuLayer( $lPars{"sourceName"} )->GetThick() + ($IProduct->GetIsPlated()
		  ? StackEnums->Plating_STD
		  : 0);
		$pcbThick = sprintf( "%.3f", $self->{"stackup"}->GetThickByCuLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} ) );
	}

	AOSet->SetStage( $inCAM, $jobId, $stepToTest, $layerName, $cuThick, $pcbThick );

	# Set nominal space, line

	my $class = undef;

	if ( $layerName =~ /^v\d+$/ ) {
		$class = CamJob->GetJobPcbClassInner( $inCAM, $jobId );
	}
	else {
		$class = CamJob->GetJobPcbClass( $inCAM, $jobId );
	}

	my $isolation = JobHelper->GetIsolationByClass($class);

	$inCAM->COM( "cdr_line_width", "nom_width" => $isolation, "min_width" => "0" );
	$inCAM->COM( "cdr_spacing",    "nom_space" => $isolation, "min_space" => "0" );

	# Set step to test
	my @steps = ();

	if ( $stepToTest eq "mpanel" ) {

		if ($incldMpanelFrm) {
			@steps = ( { "stepName" => $stepToTest } );
		}
		else {
			@steps = CamStepRepeat->GetUniqueDeepestSR( $inCAM, $jobId, $stepToTest );
		}
	}
	elsif ( $stepToTest eq "panel" ) {

		my $mPanelExist = CamStepRepeat->ExistStepAndRepeat( $inCAM, $jobId, $stepToTest, "mpanel" );

		if ( $mPanelExist && $incldMpanelFrm ) {

			@steps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $stepToTest );
		}
		else {

			@steps = CamStepRepeat->GetUniqueDeepestSR( $inCAM, $jobId, $stepToTest );
		}
	}
	else {

		@steps = ( { "stepName" => $stepToTest } );
	}

	CamStepRepeat->RemoveCouponSteps( \@steps, 1, [ EnumsGeneral->Coupon_IMPEDANCE, EnumsGeneral->Coupon_IPC3MAIN ] );

	@steps = map { $_->{"stepName"} } @steps;

	my $stepsStr = join( "\;", @steps );
	$inCAM->COM( "cdr_set_area_auto", "steps" => $stepsStr, "margin_x" => "0", "margin_y" => "0", "inspected_steps" => "" );

	# Exclude texts from test
	$inCAM->COM( "cdr_auto_zone_text", "margin" => "100", "pcb" => "yes", "panel" => "no" );

	# ===== Do AOI output ======

	my $incamResult;
	my $reportResult;

	# START HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(1);

	# Raise result item for optimization set
	my $resultItemAOIOutput = $self->_GetNewItem($layerName);
	$resultItemAOIOutput->SetGroup("Layers");

	my $result = AOSet->OutputOpfx( $inCAM, $jobId, $exportPath, $layerName, $self->{"machineName"}, \$incamResult, \$reportResult );

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

# Delete all files from ot dir
sub __DeleteOutputFiles {
	my $self         = shift;
	my $path         = shift;
	my @signalLayers = @{ shift(@_) };

	my $dir;

	if ( opendir( $dir, $path ) ) {
		while ( my $file = readdir($dir) ) {
			next if ( $file =~ /^\.$/ );
			next if ( $file =~ /^\.\.$/ );

			# delete only if layer is requested to export
			foreach my $exportL (@signalLayers) {

				if ( $file =~ /$exportL/i ) {
					unlink $path . $file;
					last;
				}
			}
		}

		closedir($dir);
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::ETesting::ExportIPC::ExportIPC';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "d269726";
	my $inCAM = InCAM->new();

	my $step = "panel";

	my $max = ExportIPC->new( $inCAM, $jobId, $step, 1, );
	$max->Export( undef, 1 );

	print "area exceeded=" . $max . "---\n";

}

1;

