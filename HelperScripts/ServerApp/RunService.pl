#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use Win32::Service;
use Config;
use Win32::Process;
use Log::Log4perl qw(get_logger);

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Programs::Exporter::ExportUtility::RunExport::RunExportUtility';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';

# Init logger
my $logDir = 'c:\tmp\InCam\scripts\logs\serverApp';
unless ( -e $logDir ) {
	mkdir($logDir) or die "Can't create dir: " . $logDir . $_;
}
Log::Log4perl->init( GeneralHelper->Root() . "\\HelperScripts\\ServerApp\\Logger.conf" );
my $logger = get_logger("serverLog");

# ---------------------------------
# LAUNCH SERVER scripts, services
# ---------------------------------

# ======= InCAMServer =============================================

RunInCAMServer();

# ======= TPVCustomService =========================================

#RunService("TpvLogService", EnumsPaths->Client_INCAMTMPLOGS ."logService\\logAll.txt");    # Run log service

# ======= TPVLogService =========================================

RunService( "TpvCustomService", EnumsPaths->Client_INCAMTMPLOGS . "tpvService\\logAll.txt" );    # Run tpv service

# ======= Export utility =========================================

my $exporter = RunExportUtility->new(0);                                                         # Run exporter

# ---------------------------------
# Helper func
# ---------------------------------

# Service statuses:
#	  '1' => 'stopped.',
#	  '2' => 'start pending.',
#	  '3' => 'stop pending.',
#	  '4' => 'running.',
#	  '5' => 'continue pending.',
#	  '6' => 'pause pending.',
#	  '7' => 'paused.'
sub RunService {
	my $name       = shift;
	my $serviceLog = shift;

	my %status = ();

	Win32::Service::GetStatus( "", $name, \%status );

	if ( $status{"CurrentState"} == 1 ) {

		Win32::Service::StartService( "", $name );
		$logger->debug("Service \"$name\" status: START SERVICE");
	
	}else{
		
		$logger->debug("Service \"$name\" status: RUNNING");
	}

	# stop service if is running, but is not active more than 60 minutes (bug)

	if ( defined $serviceLog ) {

		my $diff = ( time() - ( stat($serviceLog) )[9] ) /60;    # diff  in minute

		if ( $status{"CurrentState"} == 4 && $diff > 60 ) {

			Win32::Service::StopService( "", $name );
			$logger->debug("Service \"$name\" status: STOP SERVICE");
		}
	}
}

sub RunInCAMServer {

	my $perl = $Config{perlpath};
	my $processObj1;
	Win32::Process::Create( $processObj1, $perl,
							"perl " . GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\InCAMServer\\Server\\InCAMServerScript.pl -h yes",
							0, NORMAL_PRIORITY_CLASS | CREATE_NEW_CONSOLE, "." )
	  || die "Failed to run InCAMServerScript \n";

}
