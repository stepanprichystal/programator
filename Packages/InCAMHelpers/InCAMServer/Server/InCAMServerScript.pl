#-------------------------------------------------------------------------------------------#
# Description: "InCAM server " is server which is able to run and prepare InCAM editor
# Allow control amount of launched editor, see config file
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use strict;

use threads;
use threads::shared;
use Win32::Process;

#use IO::Socket;
#use Thread::Queue;
#use IO::Select;
#use IO::Socket;
use Config;

#use Time::HiRes qw (sleep);
use Log::Log4perl qw(get_logger);

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;
use Getopt::Std;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#use Try::Tiny;
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Other::AppConf';
use aliased 'Packages::InCAMHelpers::InCAMServer::Server::CreateServer';
use aliased 'Packages::InCAMHelpers::InCAMServer::Server::Helper';
use aliased 'Packages::InCAMHelpers::InCAMServer::Server::Enums';

# Parse script arguments
my %options = ();
getopts( "h:", \%options );

# Check if another instance is not running. If so exit
Helper->CheckRunningApp();

my $hideApp = $options{"h"};

# test if hide console window after start
if ( defined $hideApp && $hideApp eq "yes" ) {
	Helper->HideConsole(1);
}

$main::configPath = GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\InCAMServer\\Config";

# Create log dir, if doesnt exist
my $logDir = 'c:\tmp\InCam\scripts\logs\InCAMServer';
unless ( -e $logDir ) {
	mkdir($logDir) or die "Can't create dir: " . $logDir . $_;
}

Log::Log4perl->init( GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\InCAMServer\\Server\\Logger.conf" );
my $logger = get_logger("serverLog");

# redirect all sdtou + stderr to file
#my $OLDOUT;
#my $OLDERR;
#
#open $OLDOUT, ">&STDOUT" || die "Can't duplicate STDOUT: $!";
#open $OLDERR, ">&STDERR" || die "Can't duplicate STDERR: $!";
#open( STDOUT, "+>", $logDir."\\stdout.txt" );
#open( STDERR, ">&STDOUT" );

# global variables #

my @clients : shared = ();                                 # info about running incam and  client which use it
my %clientsThreads   = ();                                 # contain client id and its thread object
my $clientsCnt       = 0;                                  # total count of client, which incam edotor was launched for
my $MAX_INCAM_CNT    = AppConf->GetValue("maxClients");    # max incam instance running in same time
my $portStarts       = AppConf->GetValue("portStart");     # all incam edotros are running on this or heigher port
my $defPort          = AppConf->GetValue("serverPort");    #
my $defHost          = AppConf->GetValue("serverHost");    #

CreateServer->CloseZombie( undef, $portStarts, $portStarts + $MAX_INCAM_CNT );

my $main_socket = new IO::Socket::INET(
										LocalHost => $defHost,
										LocalPort => $defPort,
										Proto     => 'tcp',
										Listen    => 10,
										Reuse     => 1,
);
die "Could not connect: $!" unless $main_socket;

my $cnt = 0;

$SIG{CHLD} = sub { wait() };

# Create Cleanup thread
my $thrCleanUp = threads->create( sub { __KillOldServers() } );
$thrCleanUp->set_thread_exit_only(1);
$thrCleanUp->detach();

die "Socket could not be created. Reason: $!\n" unless ($main_socket);
while ( my $new_sock = $main_socket->accept() ) {

	my $clientId = GeneralHelper->GetGUID();
	$logger->debug("new client accepted. Client id: $clientId");

	# 1) Kill old incams
	#__KillOldServers();

	# 2) Determine if there are free servers
	my $acceptClient = 1;
	my $freePort     = -1;

	if ( __GetAceptClients() >= $MAX_INCAM_CNT ) {
		$acceptClient = 0;
	}

	# 3) Add new client structure
	my %client : shared = ();

	$client{"clientId"}  = $clientId;
	$client{"state"}     = $acceptClient ? Enums->Client_ACCEPT : Enums->Client_REJECT;
	$client{"inCAMPID"}  = -1;
	$client{"serverPID"} = -1;
	$client{"inCAMPort"} = $acceptClient ? __GetFreePort() : -1;
	$client{"launched"}  = time();
	$client{"duration"}  = -1;
	$client{"finished"}  = $acceptClient ? 0 : 1;
	$client{"cleanUp"}   = 0;

	push( @clients, \%client );

	$clientsCnt++ if ($acceptClient);

	my $thr = threads->create( sub { __ClientThread( $new_sock, $clientId, \@clients ) } );
	$thr->set_thread_exit_only(1);
	$thr->detach();

	$clientsThreads{$clientId} = $thr;

	$logger->info("Total accepted clients: $clientsCnt");

	# else 'tis the parent process, which goes back to accept()
}

close($main_socket);

# this is child thread
sub __ClientThread {

	my $sock       = shift;
	my $clientId   = shift;
	my $clients    = shift;
	my $clientsCnt = shift;

	$SIG{'KILL'} = sub {
		exit(0);
	};

	my $clientIdx = ( grep { $clients[$_]->{"clientId"} eq $clientId } 0 .. $#clients )[0];

	# variable init
	my $clientMess;

	$logger->debug("Thread created for (client: $clientId)");

	# 1) receive only request for new InCAM server "server ready message"
	# wait until server ready

	$clientMess = <$sock>;
	chomp($clientMess);

	$logger->debug("First client message  $clientMess.(client: $clientId)");

	my ( $message, $duration ) = split( ";", $clientMess );

	if ( $message ne "ServerReady" ) {
		$logger->debug("First client message  NOT ok.(client: $clientId)");
		$clients->[$clientIdx]->{"finished"} = 1;

		__SendMessage( $sock, undef, "Wrong message $clientMess" );
		exit(0);

	}
	else {

		if ( $clients->[$clientIdx]->{"state"} eq Enums->Client_REJECT ) {

			$logger->debug("Maximum number of incam NOT ok.(client: $clientId)");
			__SendMessage( $sock, "0" );
			exit(0);

		}
		elsif ( $clients->[$clientIdx]->{"state"} eq Enums->Client_ACCEPT ) {

			# send client, this server is working/ready
			$logger->debug("Maximum number of incam ok.(client: $clientId)");
			__SendMessage( $sock, "1" );
			$clients->[$clientIdx]->{"duration"} = $duration;

		}
	}

	# 2) Create new incam server

	#take first free port from start port number
	$clients->[$clientIdx]->{"inCAMPort"} = __GetFreePort($clients);
	$clients->[$clientIdx]->{"state"}     = Enums->Client_ACCEPT;

	$logger->debug( "Free port is " . $clients->[$clientIdx]->{"inCAMPort"} . ".(client: $clientId)" );

	$clientMess = <$sock>;
	chomp($clientMess);

	$logger->debug("Second client message: $clientMess .(client: $clientId)");

	# receive only request for new InCAM server "server ready message"
	if ( $clientMess ne "GetPort" ) {
		$logger->debug("Second client message NOT ok.(client: $clientId)");
		__SendMessage( $sock, undef, "Wrong message $clientMess" );
		$clients->[$clientIdx]->{"finished"} = 1;
		exit(0);
	}

	# 1) prepare server
	my %result = CreateServer->CreateServer( $clients->[$clientIdx]->{"inCAMPort"} );
	unless ( $result{"result"} ) {

		$logger->debug(" Failed to create server for: (client: $clientId)");
		__SendMessage( $sock, undef, "Failed to create server $clientMess" );
		$clients->[$clientIdx]->{"finished"} = 1;
		exit(0);
	}

	$clients->[$clientIdx]->{"inCAMPID"}  = $result{"inCAMPID"};
	$clients->[$clientIdx]->{"serverPID"} = $result{"serverPID"};

	$logger->debug( "Before send port: " . $clients->[$clientIdx]->{"inCAMPort"} . " to (client: $clientId)" );

	# send port to clients
	__SendMessage( $sock, $clients->[$clientIdx]->{"inCAMPort"} );

	$logger->debug( "After send port: " . $clients->[$clientIdx]->{"inCAMPort"} . " to (client: $clientId)" );

	# 2) wait on finish client job
	$clientMess = <$sock>;
	chomp($clientMess);

	$logger->debug("Third client message: $clientMess .(client: $clientId)");

	if ( $clientMess ne "JobDone" ) {
		$logger->debug("Third client message NOT ok.(client: $clientId)");
		__SendMessage( $sock, undef, "Wrong client message $clientMess" );
		$clients->[$clientIdx]->{"finished"} = 1;
		exit(0);
	}

	$logger->debug(   "Job is done.(client: $clientId)"
					. "InCAM pid : "
					. $clients->[$clientIdx]->{"inCAMPID"}
					. ", server pid: "
					. $clients->[$clientIdx]->{"serverPID"} );

	close($sock);    # close socket

	$clients->[$clientIdx]->{"finished"} = 1;

}

sub __SendMessage {
	my $sock = shift;
	my $mess = shift;
	my $err  = shift;
	chomp($mess) if ( defined $mess );
	chomp($err)  if ( defined $err );

	my $clientMess = "Message=$mess;Error=$err\n";

	$sock->send($clientMess);
}


# Clean up old servers
sub __KillOldServers {

	while (1) {

		$logger->debug("=== Cleanup ===\n");

		foreach my $client (@clients) {

			if ( $client->{"cleanUp"} ) {
				next;
			}

			$logger->debug("Cleint ID:" . $client->{"clientId"} . "\n");
			$logger->debug("Cleint ID Duration:" . $client->{"duration"} . "\n");
			$logger->debug("Cleint ID Launched:" . $client->{"launched"} . "\n");
			$logger->debug("              Time:" . time() . "\n");

			# duration is in minutes
			if ( ( $client->{"duration"} > -1 && ( $client->{"launched"} + ( $client->{"duration"} * 60 ) ) < time() )
				 || $client->{"finished"} )
			{

				# Log reason of finish client
				if ( ( $client->{"duration"} > -1 && ( $client->{"launched"} + ( $client->{"duration"} * 60 ) ) < time() ) ) {
					 
					$logger->debug( "Cleint ID:" . $client->{"clientId"} . " finished because of duration: " . $client->{"duration"} );
				}

				if ( $client->{"finished"} ) {

					$logger->debug( "Cleint ID:" . $client->{"clientId"} . " finished because of real finish" );
				}

				__CleanUpClient( $client->{"clientId"} );
			}
		}

		# prin actual status of cloents
		my $str = "\n ================ Actual status of clients ===============\n";

		my $start = scalar(@clients) - 10;
		if ( $start < 0 ) {
			$start = 0;
		}

		for ( my $i = $start ; $i < scalar(@clients) ; $i++ ) {

			next if ( $i < 0 );

			$str .=
			    "client: "
			  . $clients[$i]->{"clientId"}
			  . ", state: "
			  . $clients[$i]->{"state"}
			  . ", client finish: "
			  . $clients[$i]->{"finished"} . "\n";
		}

		$logger->info($str);
		
		sleep(10);    # Do celanup every 5 minutes
	}

	

}

sub __CleanUpClient {
	my $clientId = shift;

	my $idx = ( grep { $clients[$_]->{"clientId"} eq $clientId } 0 .. $#clients )[0];

	unless ( defined $idx ) {
		$logger->error("undef client");
		die;
	}

	my $client = $clients[$idx];

	$logger->debug( "Clean up client .(client: " . $client->{"clientId"} . ")" );

	# kill incam if is still not closed
	Win32::Process::KillProcess( $client->{"inCAMPID"},  0 );
	Win32::Process::KillProcess( $client->{"serverPID"}, 0 );

	my $thrObj = $clientsThreads{ $client->{"clientId"} };

	unless ( defined $thrObj ) {
		$logger->error("undef thread obj");
		die;
	}

	if ( defined $thrObj && $thrObj->is_running() ) {
		$thrObj->kill('KILL');
	}

	$clients[$idx]->{"cleanUp"}  = 1;
	$clients[$idx]->{"finished"} = 1;

	delete $clientsThreads{ $client->{"clientId"} };

	#delete $clients[$idx];

}

sub __GetAceptClients {

	my @active = grep { $_->{"state"} eq Enums->Client_ACCEPT && !$_->{"finished"} } @clients;

	return scalar(@active);

}

sub __GetFreePort {

	my $freePort = $portStarts;

	while (1) {

		my $result = 1;
		my @acceptClients = grep { $_->{"state"} eq Enums->Client_ACCEPT && !$_->{"finished"} } @clients;

		foreach my $c (@acceptClients) {

			if ( $c->{"inCAMPort"} eq $freePort ) {
				$result = 0;
				last;
			}
		}

		if ($result) {
			last;
		}
		else {
			$freePort++;
		}
	}

	return $freePort;
}

