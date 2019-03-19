
#-------------------------------------------------------------------------------------------#
# Description: Helper for InCAMCall class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::InCAMServer::Server::CreateServer;

#3th party library
use strict;
use Win32::Process;
use Config;
use Win32::GuiTest qw(FindWindowLike SetWindowPos ShowWindow);
use Time::HiRes qw (sleep);
use Log::Log4perl qw(get_logger :levels);

use Getopt::Std;

#use Try::Tiny;
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::SystemCall::SystemCall';
use aliased 'CamHelpers::CamEditor';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub CreateServer {
	my $self     = shift;
	my $freePort = shift;

	my $logger = get_logger("serverLog");

	my %result = ( "result" => 0 );

	eval {

		my $pidInCAM;
		my $pidServer;
		my $fIndicator = GeneralHelper->GetGUID();    # file name, where is value, which indicate if server is ready 1/0

		# create indicator file

		# 2) try to create inCAM server. Max number of attempts 10
		my $waitForLaunch = 25;    # 25 s
		for ( 1 .. 10 ) {

			$logger->debug( "Create Incam server attempt num.: " . $_ . " \n" );

			# launch InCAm instance + server
			$pidInCAM = $self->__CreateInCAMInstance( $freePort, $fIndicator );

			# creaate and test server connection
			$pidServer = $self->__CreateServerConn( $freePort, $fIndicator, $waitForLaunch );

			# if pid server returned, incam server is ok
			if ($pidServer) {

				$result{"result"}    = 1;
				$result{"inCAMPID"}  = $pidInCAM;
				$result{"serverPID"} = $pidServer;

				# 3) Temoporary solution because -x is not working in inCAM
				$self->__MoveWindowOut($pidInCAM);

				last;

			}
			else {

				$logger->debug( "Increase wait time for InCAM launching from: $waitForLaunch on: ".($waitForLaunch + 5)."\n" );
				
				# for next attempt, increase wait time of launchong InCAM
				$waitForLaunch += 5;

			}

		}
	};
	if ($@) {
		$logger->error( "Error during create InCAM server. Details: " . $@ );
	}

	return %result;
}

sub CloseZombie {
	my $self     = shift;
	my $port     = shift;
	my $portFrom = shift;
	my $portTo   = shift;

	my $logger = get_logger("serverLog");

	if ( defined $port ) {
		$portFrom = $port;
		$portTo   = $port;
	}
	else {
		if ( !defined $portFrom || !defined $portTo ) {
			die "Port range is not defined";
		}
	}

	my $script = GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\InCAMServer\\Server\\HelperScripts\\CloseZombie.pl";
	my @cmds = ( $portFrom, $portTo );

	my $call = SystemCall->new( $script, \@cmds );
	my $result = $call->Run();

}

# This helper function, wait until new incam server is ready
# Try to conenct every 2 second
# Called in asynchrounous thread
sub __CreateInCAMInstance {
	my $self       = shift;
	my $port       = shift;
	my $fIndicator = shift;

	my $pidInCAM;

	#1 )test on zombified server and close
	$self->CloseZombie($port);

	# 2) Create file where is stored vlue if server is ready
	my $pFIndicator = EnumsPaths->Client_INCAMTMPOTHER . $fIndicator;

	if ( open( my $f, "+>", $pFIndicator ) ) {

		print $f 0;
		close($f);
	}
	else {
		die "unable to create file  file $pFIndicator";
	}

	# 3) start new server on $freePort

	my $inCAMPath = GeneralHelper->GetLastInCAMVersion();

	$inCAMPath .= "bin\\InCAM.exe";

	unless ( -f $inCAMPath )    # does it exist?
	{
		die "InCAM does not exist on path: " . $inCAMPath;
		return 0;
	}

	my $processObj;
	my $inCAM;

	my $path = GeneralHelper->Root() . "\\Managers\\AsyncJobMngr\\Server\\ServerAsyncJob.pl";

	# turn all backslash - incam need this
	$path =~ s/\\/\//g;

	# sometimes happen, when 2 or more INCAM servers are launeched a same time, parl fail (no reason)
	# this is stupid solution, sleep random time
	#my $sleep = int( rand(10));
	#sleep($sleep);

	#run InCAM editor with serverscript
	Win32::Process::Create( $processObj, $inCAMPath, "InCAM.exe -s" . $path . " " . $port . " " . $fIndicator . ' >c:\Export\test\test1.txt',
							0, THREAD_PRIORITY_NORMAL, "." )
	  || die "$!\n";

	$pidInCAM = $processObj->GetProcessID();

	#$self->{"threadLoger"}->debug("CLIENT PID: " . $pidInCAM . " (InCAM)........................................is launching\n");

	return $pidInCAM;
}

# This helper function, wait until new incam server is ready
# Try to conenct every 2 second
# Called in asynchrounous thread
sub __CreateServerConn {
	my $self              = shift;
	my $port              = shift;
	my $fIndicator        = shift;
	my $waitTimeForLaunch = shift;

	my $inCAMLaunched = 0;

	# if file indicator is not defined, it means, server is prepared external and is alreadz ready in this time
	if ( defined $fIndicator ) {

		my $pFIndicator = EnumsPaths->Client_INCAMTMPOTHER . $fIndicator;

		my $sleepTime = 1;    # 1 s than next attempt

		# 2 ) Test in loop if server is ready (file indicator has to contain value 1)
		for ( my $i = 0 ; $i < $waitTimeForLaunch ; $i++ ) {

			if ( open( my $f, "<", $pFIndicator ) ) {

				my $val = join( "", <$f> );
				close($f);

				if ( $val == 1 ) {

					unlink($pFIndicator);                       # delete temp file
					sleep(1);                                   # to be sure, server is ready to "listen" clients
					$inCAMLaunched = 1;
					last;
				}
			}
			else {
				print STDERR "Unable to open file $pFIndicator";
			}

			#$self->{"threadLoger"}->debug("CLIENT(parent): PID: $$  try connect to server port: $port, attempt: $i ....failed\n");

			sleep(1); # sleep for one second
		}
	}
	else {

		# InCam is prepared  (external sever)
		$inCAMLaunched = 1;
	}

	unless ($inCAMLaunched) {
		return 0;
	}

	# 3) Test connection with server

	my $inCAM = InCAM->new( "remote" => 'localhost',
							"port"   => $port );

	#$inCAM->SetLogger(get_logger(Enums->Logger_INCAM));

	#server seems ready, try send message and get server pid
	my $pidServer = $inCAM->ServerReady();

	#print STDERR "Server ready, next client finish\n";

	if ($pidServer) {

		# test if there is a free editor
		if ( CamEditor->GetFreeEditorLicense($inCAM) ) {

			$inCAM->ClientFinish();
			return $pidServer;

		}
		else {

			# Close created InCAM server, because there is no free editor
			$self->CloseZombie($port);
			return 0;
		}

	}
	else {

		my $logger = get_logger("serverLog");
		$logger->error( "Error connect to incam server" );
		return 0;
	}
}

# Temporary solution, for disappearing InCAM window from user screen
# Because parameter -X not work
sub __MoveWindowOut {
	my $self = shift;
	my $pid  = shift;

	print STDERR "Searchin InCAM window PID $pid.\n";

	while (1) {

		my @windows = FindWindowLike( 0, "$pid" );
		for (@windows) {
			print STDERR "windows hiden\n\n";
			ShowWindow( $_, 0 );
			SetWindowPos( $_, 0, -10000, -10000, 0, 0, 0 );

			return 1;
		}

		sleep(0.02);

		#print STDERR ".";
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

