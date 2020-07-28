#!/usr/bin/perl-w

#-------------------------------------------------------------------------------------------#
# Description: Reduce job to necessary minimum and output OPFX for aoi
# Source job data are copied layer by layer to new jon D<xxxxxx>_OT<\d>
# This should be prevention for locking OPFX data during processing on server
# Author:SPR
#-------------------------------------------------------------------------------------------#

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;
use utf8;
use List::Util qw[max min];

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Widgets::Forms::SimpleInput::SimpleInputFrm';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardBase';
use aliased 'Packages::CAMJob::Panelization::SRStep';

my $inCAM = InCAM->new();
my $jobId = "$ENV{JOB}";

my $messMngr = MessageMngr->new("AOI Helper");

# -------------------------------------------
# 1) Get source job id
# -------------------------------------------
my $jobIdSrc = undef;
if ( !defined $jobId || $jobId eq "" ) {

	my $sourceJobPar = $messMngr->GetTextParameter( "Source job", "" );

	my @params = ($sourceJobPar);

	while ( !defined $sourceJobPar->GetResultValue() ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_INFORMATION,
							  ["Script redukuje data jobu a odešle je na AOI server"],
							  [ "Cancel", "Next" ],
							  undef, \@params );
	}

	$jobIdSrc = lc( $sourceJobPar->GetResultValue() );
}
else {
	$jobIdSrc = $jobId;
}

#d177693_ot
# -------------------------------------------
# 2) Get parameters for create AOI job
# -------------------------------------------

my @mess = ("Set parameters for job  for output OPFX");

# App parameters
# Generate new job name in format D<xxxxxx>_ot<\d>
# Trz to find job with last _ot number

my @dirs = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_AOITESTSFUSIONDB, $jobIdSrc );
my $IDx = max( grep { defined $_ } map { ( $_ =~ m/\w\d+_ot(\d+)/i )[0] } @dirs );
$IDx = 1 if ( !defined $IDx );
my $newJobName = $jobIdSrc . "_ot$IDx";

my $outputJobPar = $messMngr->GetTextParameter( "Output job (must be in format d123456_ot123 )", "$newJobName" );
my $reduceStepsPar = $messMngr->GetCheckParameter( "Reduce steps (only panel step left)", 0 );
my $resizePar = $messMngr->GetTextParameter( "Resize data [µm]", 0 );
my $contourPar = $messMngr->GetCheckParameter( "Contourize",              0 );
my $levelPar   = $messMngr->GetCheckParameter( "Reduce layer data level", 0 );
my $attrPar    = $messMngr->GetCheckParameter( "Remove layer attributes", 1 );

my @params = ( $outputJobPar, $reduceStepsPar, $resizePar, $contourPar, $levelPar, $attrPar );

while (1) {

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Cancel", "Next" ], undef, \@params );

	exit() if ( $messMngr->Result() == 0 );

	# Check if output job is well defined
	my $jobIdOut = $outputJobPar->GetResultValue();

	if ( !defined $jobIdOut || $jobIdOut eq "" || $jobIdOut !~ m/\w\d+_ot(\d+)/i ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, ["Output job name is not defined or has wrong format. Repait it"] );

	}
	elsif ( $jobIdOut =~ m/\w\d+_ot(\d+)/i && $jobIdOut !~ m/$jobIdSrc/i ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_WARNING,
							  ["Output job name ($jobIdOut) has to contain source job name ($jobIdSrc). Repait it"] );

	}
	elsif ( -d EnumsPaths->Jobs_AOITESTSFUSIONDB . $jobIdOut ) {

		$messMngr->ShowModal(
							  -1,
							  EnumsGeneral->MessageType_WARNING,
							  [
								 "Job name: $jobIdOut, has been already exported.",
								 "Folder was found at: " . EnumsPaths->Jobs_AOITESTSFUSIONDB . $jobIdOut,
								 "If you continue, OPFX might be locked again on AOI server"
							  ],
							  [ "Accept", "Change name" ]
		);

		if ( $messMngr->Result() == 0 ) {
			last;
		}
	}
}

# -------------------------------------------
# 3) Create job and output OPFX
# -------------------------------------------
$inCAM->COM( "new_job", "name" => $jobIdOut, "db" => "incam", "customer" => "", "disp_name" => "", "notes" => "", "attributes" => "" );
$inCAM->COM( "check_inout", "mode" => "out", "type" => "job", "job" => $jobIdOut );
$inCAM->COM( "open_job", "job" => $jobIdOut, "open_win" => "yes" );

# Set job attributes

my %srcJobAttr = CamAttributes->GetJobAttr( $inCAM, $jobIdSrc );

CamAttributes->SetJobAttribute( $inCAM, $jobIdOut, "USER_NAME",       $srcJobAttr{"USER_NAME"} );
CamAttributes->SetJobAttribute( $inCAM, $jobIdOut, "PCB_CLASS",       $srcJobAttr{"PCB_CLASS"} );
CamAttributes->SetJobAttribute( $inCAM, $jobIdOut, "PCB_CLASS_INNER", $srcJobAttr{"PCB_CLASS_INNER"} );

# Create step structure

# Nested steps
if ( !$reduceStepsPar->GetResultValue() ) {

	my @srcSteps = CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobIdSrc );

	foreach my $srcS (@srcSteps) {

		my %datSrc = CamStep->GetDatumPoint( $inCAM, $jobIdOut, $srcS->{"stepName"}, 1 );

		CamStep->CreateStep( $inCAM, $jobIdOut, $srcS->{"stepName"} );    # create step
		CamStep->SetDatumPoint( $inCAM, $srcS->{"stepName"}, $datSrc{"x"}, $datSrc{"y"} );    # Set Datum point

		CamMatrix->CreateLayer( $inCAM, $jobId, "o", "document", "positive", 0 );

		CamStep->CreateStep( $inCAM, $jobIdOut, $srcS->{"stepName"} );                        # create step

		my $profL = GeneralHelper->GetGUID();
		CamStep->ProfileToLayer( $inCAM, $jobIdSrc, $profL, 200 );
		CamLayer->WorkLayer( $inCAM, $profL );

		$inCAM->COM( "sel_buffer_copy", "x_datum" => 0, "y_datum" => 0 );
		CamLayer->WorkLayer( $inCAM, "o" );
		CamMatrix->DeleteLayer( $inCAM, $jobIdSrc, $profL );

		$inCAM->COM( "sel_buffer_paste", "x" => 0, "y" => 0 );
	}
}

# Panel step
my $scrPnl = StandardBase->new( $inCAM, $jobIdSrc );

my $SRStep = SRStep->new( $inCAM, $jobIdOut, "panel" );

$SRStep->Create( $scrPnl->W(), $scrPnl->H(),
				 ( $scrPnl->H() - $scrPnl->HArea() ) / 2,
				 ( $scrPnl->H() - $scrPnl->HArea() ) / 2,
				 ( $scrPnl->W() - $scrPnl->WArea() ) / 2,
				 ( $scrPnl->W() - $scrPnl->WArea() ) / 2 );

# Set step structure
if ( !$reduceStepsPar->GetResultValue() ) {
	
	# Get repeat step	
	
}

