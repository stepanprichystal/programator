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

use aliased 'Helpers::GeneralHelper';

use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Packages::CAMJob::AOI::AOIRepair::AOIRepair';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Helpers::JobHelper';

my $inCAM = InCAM->new();

my $jobId = "$ENV{JOB}";

#$jobId = "d288860";

my $messMngr = MessageMngr->new("AOI Helper");

# -------------------------------------------
# 1) Get source job id
# -------------------------------------------
my $jobIdSrc = undef;
my $sourceJobOpened = 1;
if ( !defined $jobId || $jobId eq "" ) {

	my $sourceJobPar = $messMngr->GetTextParameter( "Source job", "" );

	my @params = ($sourceJobPar);

	while ( !defined $sourceJobPar->GetResultValue() ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_INFORMATION,
							  ["Script redukuje data jobu a odešle je na AOI server"],
							  [ "Cancel", "Next" ],
							  undef, \@params );
							  
		exit() if ( $messMngr->Result() == 0 );
	}

	$jobIdSrc = lc( $sourceJobPar->GetResultValue() );

	CamHelper->OpenJob( $inCAM, $jobIdSrc, 0 );
	CamJob->CheckOutJob( $inCAM, $jobIdSrc );
	$sourceJobOpened = 0;

}
else {
	$jobIdSrc = $jobId;
	$sourceJobOpened = 1;
}

#d177693_ot
# -------------------------------------------
# 2) Get parameters for create AOI job
# -------------------------------------------

my $AOIRepair = AOIRepair->new( $inCAM, $jobIdSrc );

$AOIRepair->{"onItemResult"}->Add( sub { __OnOPFXResult(@_) } );

my @mess = ("Set parameters for job  for output OPFX");

# App parameters
# Generate new job name in format D<xxxxxx>_ot<\d>
# Trz to find job with last _ot number

my $jobIdOut = $AOIRepair->GenerateJobName();

my $lTxt = join( "; ", CamJob->GetSignalLayerNames( $inCAM, $jobIdSrc ) );

my $outputJobPar = $messMngr->GetTextParameter( "Output job (format: d123456_ot123)", "$jobIdOut" );
my $keepJobNamePar = $messMngr->GetCheckParameter( "Keep original job name in OPFX files", 1 );
my $layersPar = $messMngr->GetTextParameter( "Layers (separated by comma ; )", $lTxt );
my $reduceStepsPar = $messMngr->GetCheckParameter( "Remove nested steps (zatim nepouzivat!)", 0 );
my $resizePar = $messMngr->GetTextParameter( "Resize data [µm]", 0 );
my $contourPar = $messMngr->GetCheckParameter( "Contourize", 0 );

my $opfxP          = JobHelper->GetJobArchive($jobIdSrc) . "zdroje\\ot\\";
my $opfxPathPar    = $messMngr->GetTextParameter( "OPFX path", "$opfxP" );
my $sent2serverPar = $messMngr->GetCheckParameter( "Sent to AOI server", 1 );
my $closeOtJobPar  = $messMngr->GetCheckParameter( "Close OT job", 1 );
my $removeOtJobPar = $messMngr->GetCheckParameter( "Remove OT job", 1 );

#my $levelPar   = $messMngr->GetCheckParameter( "Reduce layer data level", 0 );
my $attrPar = $messMngr->GetCheckParameter( "Del feats attr (not: .nomencl; .smd)", 0 );

my @params =
  ( $outputJobPar, $keepJobNamePar,  $layersPar,  $resizePar, $contourPar, $attrPar,$reduceStepsPar, $opfxPathPar, $sent2serverPar, $closeOtJobPar, $removeOtJobPar );

while (1) {

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, [ "Cancel", "Next" ], undef, \@params );

	exit() if ( $messMngr->Result() == 0 );

	# Check if output job is well defined
	$jobIdOut = $outputJobPar->GetResultValue(1);

	if ( !defined $jobIdOut || $jobIdOut eq "" || $jobIdOut !~ m/\w\d+_ot\d*/i ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, ["Output job name is not defined or has wrong format. Repait it"] );
		next;

	}

	if ( $jobIdOut =~ m/\w\d+_ot(\d+)/i && $jobIdOut !~ m/$jobIdSrc/i ) {

		$messMngr->ShowModal( -1,
							  EnumsGeneral->MessageType_WARNING,
							  ["Output job name ($jobIdOut) has to contain source job name ($jobIdSrc). Repait it"] );
		next;

	}

	if ( -d EnumsPaths->Jobs_AOITESTSFUSIONDB . $jobIdOut ) {

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
		else {
			next;
		}
	}

	my $lRes = $layersPar->GetResultValue(1);
	$lRes =~ s/\s//ig;
	my @layersUsr = split( ";", $lRes );
	chomp(@layersUsr);
	@layersUsr = grep { $_ ne "" } @layersUsr;

	if ( !scalar(@layersUsr) ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Layers are not set in correct format. Repait it"] );
		next;

	}

	last;

}

# Create layers
my $lRes = $layersPar->GetResultValue(1);
$lRes =~ s/\s//ig;
my @layersUsr = split( ";", $lRes );
@layersUsr = grep { $_ ne "" } @layersUsr;

$AOIRepair->CreateAOIRepairJob( $jobIdOut, \@layersUsr,
								$opfxPathPar->GetResultValue(1),
								$sent2serverPar->GetResultValue(1),
								$keepJobNamePar->GetResultValue(1),
								$reduceStepsPar->GetResultValue(1),
								$contourPar->GetResultValue(1),
								$resizePar->GetResultValue(1),
								$attrPar->GetResultValue(1) );

if ( !$closeOtJobPar->GetResultValue(1) ) {

	CamHelper->OpenJob( $inCAM, $jobIdOut, 1 );    # Set source
	CamHelper->OpenStep( $inCAM, $jobIdOut, "panel" );     
}

if ( $closeOtJobPar->GetResultValue(1) ) {

	CamJob->DeleteJob( $inCAM, $jobIdOut );
}


if(!$sourceJobOpened){
	CamJob->CheckInJob( $inCAM, $jobIdSrc );
	CamJob->CloseJob( $inCAM, $jobIdSrc );    
}


sub __OnOPFXResult {
	my $result = shift;

	print STDERR $result->ItemId() . " Result: " . $result->Result() . "\n";

	unless ( $result->Result() ) {
		print STDERR $result->GetErrorStr() . "\n";
		print STDERR $result->GetWarningStr() . "\n";
	}

}

1;
