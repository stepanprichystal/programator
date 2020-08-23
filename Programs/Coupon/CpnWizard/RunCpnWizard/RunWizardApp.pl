#!/usr/bin/perl -w
use utf8;
use strict;
use warnings;
use Win32::Process;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsIS';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::InCAMHelpers::AppLauncher::AppLauncher';
use aliased 'Packages::InCAMHelpers::AppLauncher::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Coupon::CpnSource::CpnSource';

my $jobId = shift;

unless ( defined $jobId ) {
	$jobId = $ENV{"JOB"};
}

my $inCAM   = InCAM->new();


#$jobId ="f13610";

# 1) Check before run
my $mess = "";
unless ( __CheckBeforeRun( \$mess ) ) {

	my $messMngr = MessageMngr->new($jobId);

	my @mess1 = ($mess);
	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess1 );

	exit(0);
}

# 2) Launch app

my $appName = 'Programs::Coupon::CpnWizard::CpnWizard';    # has to implement IAppLauncher

my $sourceJob = undef;
 

my $launcher = AppLauncher->new( $appName, $jobId);
$launcher->SetWaitingFrm( "Impedance coupon generator - $jobId", "Loading application ...", Enums->WaitFrm_CLOSEAUTO );

#my $logPath = GeneralHelper->Root() . "\\Packages\\Reorder\\ReorderApp\\Config\\Logger.conf";
#$launcher->SetLogConfig($logPath);

$launcher->RunFromInCAM();


exit(1);

# Check before run app
sub __CheckBeforeRun {
	my $mess = shift;

	my $result = 1;


	# 1) Check if class is not empty
	my $class = CamJob->GetLimJobPcbClass($inCAM, $jobId, "max");
 
	
	if(!defined $class || $class == 0){

		$result = 0;
		$$mess .= "Job pcb class is not defined. First set job attributes: Pcbclass; Pcbclass_inner ";
	}
	
	# 2) Check if layer cnt is same in job and instack
	my $cpnSource = CpnSource->new($jobId);
	if( CamJob->GetSignalLayerCnt($inCAM, $jobId) != scalar($cpnSource->GetCopperLayers())){
 
		$result = 0;
		$$mess .= "Job layer count is not equals to InStack copper layer count";
	}
	
	return $result;
}




