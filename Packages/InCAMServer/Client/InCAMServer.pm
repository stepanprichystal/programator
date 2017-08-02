
#-------------------------------------------------------------------------------------------#
# Description: Client which comunicate with InCAM server, Ask for inCAM port and
# return prepared InCAM libary
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMServer::Client::InCAMServer;

#3th party library
use strict;
use warnings;
use JSON;
use IO::Socket::INET;
use Log::Log4perl qw(get_logger);

#local library
use aliased 'Helpers::JobHelper';
use aliased "Helpers::FileHelper";
use aliased "Helpers::GeneralHelper";
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::Other::AppConf';

 
#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;    # name
	
	my $appConf = AppConf->new(GeneralHelper->Root() . "\\Packages\\InCAMServer\\Config");
	
	my %args = (
		"timeout"          => $appConf->GetValue("defaultTimeout"),    # default is 10 minutes
		"host"             => $appConf->GetValue("serverHost"),        # default is localhost
		"port"             => $appConf->GetValue("serverPort"),        # defaul is 3500
		"supressException" => 0,                                      # defaul is 3500
		@_,
	);

	my $self = {};
	bless $self;
	
	

	$self->{"timeout"}          = $args{"timeout"};                   # time (in minutes) when inCAm server will be close automatically
	$self->{"host"}             = $args{"host"};                      # default host where is incam server running
	$self->{"port"}             = $args{"port"};                      # default port where is incam server running
	$self->{"supressException"} = $args{"supressException"};
	$self->{"attemptCnt"}       = $appConf->GetValue("attemptCnt");    # max number of attmets, client will be try get free server (each 3 sec)

	$self->{"requested"}       = 0;                                   # tell if was already run method GetInCAM,
	$self->{"serverUsed"}      = 0;                                   # tell if was already run method GetInCAM,
	$self->{"getIncamFailCnt"} = 0;                                   # indicate, actual count of fail, during run method GetInCAM, 2 fails allowed

	$self->{"socket"} = undef;
	$self->{"inCAM"}  = undef;
	
	 

	#Log::Log4perl->init( "c:\\Perl\\site\\lib\\TpvScripts\\Scripts\\Packages\\InCAMServer\\Client\\Logger.conf" );

	 

	
	$self->{"logger"} = get_logger("inCAMServerClient");


	return $self;
}

# Return prepared InCAM library
sub GetInCAM {
	my $self = shift;

	if ( $self->{"requested"} ) {
		die "GetInCAM function has been already used";
	}

	$self->{"requested"} = 1;

	$self->{"logger"}->info("Request for InCAM server");

	$self->__GetInCAMAttempt();

}

sub __GetInCAMAttempt {
	my $self = shift;

	my $port = undef;

	eval {

		$port = $self->__GetInCAM();

	};
	if ($@) {

		$self->{"logger"}->error( "GetInCAM method fail. Actual fail cnt: " . $self->{"getIncamFailCnt"} );

		# max 3 attemt to get inCam again, before die
		if ( $self->{"getIncamFailCnt"} <= 2 ) {
			$self->{"getIncamFailCnt"}++;
			sleep(10);    # wait some time, then server get ready again
			$self->__GetInCAMAttempt();

		}
		else {

			my $e = "Getting InCAM was fail after: " . $self->{"getIncamFailCnt"} . " attempts\n";
			if ( $self->{"supressException"} ) {
				print STDERR $e;
				return 0;
			}
			else {
				die $e;
			}
		}

	}

	# Test if server ready and connect tu running InCAM
	$self->{"inCAM"} = InCAM->new( "port" => $port, "remote" => $self->{"host"} );
	if ( $self->{"inCAM"}->ServerReady() ) {

		$self->{"inCAM"}->SupressToolkitException(1);

	}

	$self->{"logger"}->info("InCAM received at port: $port");

	return $self->{"inCAM"};

}

# Let know to InCAM server, working with InCAM is done
sub JobDone {
	my $self = shift;

	if ( $self->{"serverUsed"} ) {

		# try to close incam
		$self->{"inCAM"}->COM("close_toolkit");
		$self->{"inCAM"}->CloseServer();

		my $sock = $self->{"socket"};

		my $m = "JobDone\n";
		$sock->send($m);
	}

}

sub __Connect {
	my $self = shift;

	my $result = 1;

	# flush after every write
	$| = 1;

	my $socket = undef;

	# creating object interface of IO::Socket::INET modules which internally creates
	# socket, binds and connects to the TCP server running on the specific port.
	unless (
			 $socket = new IO::Socket::INET(
											 PeerHost => $self->{"host"},
											 PeerPort => $self->{"port"},
											 Proto    => 'tcp',
			 )
	  )
	{

		$result = 0;
		print STDERR "ERROR in Socket Creation : $!\n";
	}

	# write on the socket to server.

	$self->{"socket"} = $socket;

	return $result;
}

sub __GetInCAM {
	my $self = shift;

	# 1) Wait until incam server has free incam instances

	foreach ( 1 .. $self->{"attemptCnt"} ) {
		
		$self->{"logger"}->debug("Attem to get inCAM number $_");

		unless ( $self->__Connect() ) {
			
			$self->{"logger"}->debug("Attem to get inCAM number $_ - FAIL");

			sleep(8);
			next;
		}

		my $mess = "ServerReady;" . $self->{"timeout"} . "\n";
		$self->{"socket"}->send($mess);

		# wait on answer
		my $serverReady = undef;
		my $e           = undef;
		unless ( $self->__ReadMess( \$serverReady, \$e ) ) {

			if ( $self->{"supressException"} ) {
				print STDERR $e;
				return 0;
			}
			else {
				die $e;
			}

		}

		if ( $serverReady == 1 ) {
			last;
		}
		elsif ( $serverReady == 0 ) {

			$self->{"logger"}->info( "Next attemt (" . $_ . ") to get free InCAM server" );
			sleep(8);
		}

	}

	# 3) Try to get port
	$self->{"logger"}->debug("Server is ready, so ask for new port");
	
	my $m = "GetPort\n";
	$self->{"socket"}->send($m);

	# wait for port
	my $port = undef;
	my $e    = undef;
	unless ( $self->__ReadMess( \$port, \$e ) ) {
		if ( $self->{"supressException"} ) {
			print STDERR $e;
			return 0;
		}
		else {
			die $e;
		}
	}
	
	$self->{"logger"}->debug("New port received");

	$self->{"serverUsed"} = 1;

	return $port;

}

sub __ReadMess {
	my $self = shift;
	my $m    = shift;
	my $e    = shift;

	my $sock = $self->{"socket"};

	my $answer = <$sock>;
	chomp($answer);

	my $format = 0;

	if ( $answer =~ m/Message=(.*);Error=(.*)/i ) {
		$$m     = $1;
		$$e     = $2;
		$format = 1;
	}

	# if wring format or message and error are empty, die
	if ( !$format
		 || ( ( !defined $$m || $$m eq "" ) && ( !defined $$e || $$e eq "" ) ) )
	{

		my $error = "Wrong message format: $answer";

		if ( $self->{"supressException"} ) {
			print STDERR $error;
			return 0;
		}
		else {
			die $error;
		}

	}

	#print STDERR "message from server: $$m\n";

	if ( defined $$e && $$e ne "" ) {
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
#
	use aliased 'Packages::InCAMServer::Client::InCAMServer';
#	use aliased 'CamHelpers::CamJob';
#
#	# ================================================#
#	# ================================================#
#
#	while (1) {
#
		my $server = InCAMServer->new();
		my $inCAM  = $server->GetInCAM();
#
		$inCAM->COM("get_user_name");
		my $rep = $inCAM->GetReply();
#
		print STDERR "\nOdpoved z InCAM - user name: " . $rep . "\n";
#		print STDERR "\nKonec pouziti InCAMu\n";
#
#		sleep( int( rand(20) ) );
#
#		$server->JobDone();
#
#		sleep( int( rand(50) ) );
#
#	}

	# ================================================#
	# ================================================#

}

1;

