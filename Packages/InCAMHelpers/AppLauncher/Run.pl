#! /sw/bin/perl
#-------------------------------------------------------------------------------------------#
# Description: Helper script which create App, pass arguments to app constructor,
# work with waiting form etc,..
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use threads;
use strict;
use warnings;
use JSON;
use Log::Log4perl qw(get_logger :levels);
use Win32::Process;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAMHelpers::AppLauncher::Helper';
use aliased 'Packages::InCAMHelpers::AppLauncher::Launcher';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::InCAMHelpers::AppLauncher::Enums';

#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

my $packageName  = shift;
my $serverPort   = shift;    # Port of server script running in InCAM
my $serverPid    = shift;    # Pid of server script running in InCAM
my $jobId        = shift;
my $waitFrmPid   = shift;    # PID of waiting form if exist
my $waitFrmClose = shift;    # Type of wait frm closing
my $logConfig    = shift;    # Log config path
my $PIDFile      = shift;    # File name, where PID of this script will be stored

my @appParams = ();
while ( my $p = shift ) {
	push( @appParams, $p );
}

# Init loger
if ($logConfig) {
	Log::Log4perl->init($logConfig);
}

my $logger = get_logger("appLauncher");

$logger->debug("packageName: $packageName");
$logger->debug("serverPort: $serverPort");
$logger->debug("serverPid: $serverPid");
$logger->debug("jobId: $jobId");
$logger->debug("waitFrmPid: $waitFrmPid");
$logger->debug("waitFrmClose: $waitFrmClose");
$logger->debug("PIDFile: $PIDFile");
$logger->debug( "appParams: " . join( ", ", @appParams ) );

$logger->debug("Run script start");

# 1) Store PID of this script fo file in order to kill this script

FileHelper->WriteString( $PIDFile, $$ );

my $result = 1;

# 2) Run Application

eval {

	# Create Launcher object (connect InCAM librarz to InCAM server)
	my $launcher = Launcher->new( $serverPort, $serverPid, $waitFrmPid );

	# Load custom package

	my @params = Helper->ParseParams( \@appParams );    # parse params

	eval("use $packageName;");                          # Load package library

	my $app = $packageName->new(@params);

	$logger->debug("App: $packageName, crated");

	$app->Init($launcher);

	# When all succesinit, close waiting form
	if ( $waitFrmPid && $waitFrmClose eq Enums->WaitFrm_CLOSEAUTO ) {

		Win32::Process::KillProcess( $waitFrmPid, 0 );
	}

	$app->Run();

	# After work, claunup
	# if option letServerRun is enabled, server has to by closed by App
	__CleanUp($launcher);

};
if ($@) {

	Win32::Process::KillProcess( $serverPid, 0 );    # kill server script

	if ($waitFrmPid) {
		Win32::Process::KillProcess( $waitFrmPid, 0 );    # Kill waiting frm
	}

	$logger->error( "Error during launching app: $packageName. \n\n " . $@ );

	my $messMngr = MessageMngr->new($jobId);

	my @mess1 = ( "App launcher fail:  " . $@ . "\n" );
	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess1 );

}

sub __CleanUp {
	my $launcher = shift;

	unless ( $launcher->GetLetServerRun() ) {

		my $inCAM = $launcher->GetInCAM();

		unless ( $inCAM->IsConnected() ) {
			$inCAM->Reconnect();
		}

		$inCAM->CloseServer();

		# For sure kill pid
		Win32::Process::KillProcess( $serverPid, 0 );    # kill server script

	}

}
