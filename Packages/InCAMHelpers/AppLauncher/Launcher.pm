
#-------------------------------------------------------------------------------------------#
# Description: Class allow run code in another perl instance
# Class take arguments: path of script  and array of parameters, which script consum
# All marameters are serialized to file ande than deserialized and pass to script
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::Launcher;

#3th party library
use strict;
use Config;
use Time::HiRes qw (sleep);
use Win32::Process;

# local libraru
use aliased 'Packages::Events::Event';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::InCAMHelpers::AppLauncher::BackgroundWorker::BackgroundWorker';
use aliased 'Packages::InCAMHelpers::AppLauncher::BackgroundWorker::InCAMWrapper';
use aliased 'Packages::InCAMHelpers::AppLauncher::PopupChecker::PopupChecker';
use aliased 'Packages::InCAMHelpers::AppLauncher::Helper';

#use aliased 'Enums::EnumsGeneral';
#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;    # Create an anonymous hash, and #self points to it.
	my $self  = {};
	bless $self;          # Connect the hash to the package Cocoa.

	# PROPERTIES

	my %server = ();
	$self->{"server"} = \%server;

	$self->{"server"}->{"port"}  = shift;
	$self->{"server"}->{"pid"}   = shift;
	$self->{"server"}->{"inCAM"} = undef;    # InCAM library

	$self->{"waitFrmPid"} = shift;           # PID of waiting frm

	$self->{"letServerRun"} = 0;             # After closing app, do not exit InCAM server

	$self->{"backgroundWorker"} = undef;     # Support background execution of task

	$self->{"pupupChecker"} = undef;         # Support background checker with error popup window

	# Connect to InCAM server
	unless ( $self->__Connect() ) {
		die "Unable to connect to InCAM editor, port: " . $self->{"server"}->{"port"};
	}

	# EVENTS

	# Only if Background worker is initialized
	# Raise if InCAM library wants execute command, but InCAM server is busy
	$self->{"inCAMIsBusyEvt"} = Event->new();

	return $self;    # Return the reference to the hash.
}

sub GetInCAM {
	my $self = shift;

	return $self->{"server"}->{"inCAM"};
}

# Init background woker and return "Background worker manager"
# for execution of asynchrounous background task
# - Do not forget add handler "inCAMIsBusyEvt", which indicate InCAM server is busy
sub InitBackgroundWorker {
	my $self        = shift;
	my $appMainFrm  = shift;        # app main frame
	my $MAX_THREADS = shift // 1;
	my $MIN_THREADS = shift // 1;
	my $loger       = shift;

	die "App main frame is not defined" unless ( defined $appMainFrm );

	#die "Async worker function is not defined" unless ( defined $asyncWorkerSub );

	if ( !defined $self->{"backgroundWorker"} ) {

		# Change standard InCAM library for InCAM Wrapper,
		# which support Events, which raise if InCAM server is busy
		# (it means, child thread is using inCAM server)

		# add handler for inCAM server busy
		$self->{"server"}->{"inCAM"}->SetWaitWhenBusy(1);
		$self->{"server"}->{"inCAM"}->{"inCAMServerBusyEvt"}->Add( sub { $self->{"inCAMIsBusyEvt"}->Do(@_) } );

		my $worker = BackgroundWorker->new();
		$worker->Init( $appMainFrm, $self->{"server"}->{"inCAM"}, $MAX_THREADS, $MIN_THREADS, $loger );

		$self->{"backgroundWorker"} = $worker;

	}

	return 1;

}

# Init background woker and return "Background worker manager"
# for execution of asynchrounous background task
# - Do not forget add handler "inCAMIsBusyEvt", which indicate InCAM server is busy
sub GetBackgroundWorker {
	my $self = shift;

	if ( !defined $self->{"backgroundWorker"} ) {

		die "Background worker is not inited";
	}

	return $self->{"backgroundWorker"};
}

sub InitPopupChecker {
	my $self          = shift;
	my $jobId         = shift;
	my $appMainFrm    = shift;    # app main frame
	my $titleName     = shift;
	my $commitBtnName = shift;

	if ( !defined $self->{"pupupCheckers"} ) {

		# Firstly create background worker for PopupChecker with one thread

		# Get background worker
		$self->InitBackgroundWorker($appMainFrm) if ( !defined $self->{"backgroundWorker"} );

		my $checker = PopupChecker->new( $jobId, $appMainFrm, $titleName, $commitBtnName );

		$checker->Init( $self->{"backgroundWorker"} );

		$self->{"pupupCheckers"} = $checker;
	}

	return 1;
}

sub GetPopupChecker {
	my $self = shift;

	if ( !defined $self->{"pupupCheckers"} ) {

		die "Popup checker in not inited";
	}

	return $self->{"pupupCheckers"};

}

sub GetServerPort {
	my $self = shift;

	return $self->{"server"}->{"port"};
}

sub SetLetServerRun {
	my $self = shift;

	$self->{"letServerRun"} = 1;
}

sub GetLetServerRun {
	my $self = shift;

	return $self->{"letServerRun"};
}

sub CloseWaitFrm {
	my $self = shift;

	if ( $self->{"waitFrmPid"} ) {

		Helper->CloseWaitFrm( $self->{"waitFrmPid"} );
	}

}

# First connection of InCAM library
sub __Connect {
	my $self = shift;

	my $inCAM = $self->{"server"}->{"inCAM"};
	my $port  = $self->{"server"}->{"port"};

	if ( defined $inCAM && $inCAM->IsConnected() ) {

		return 1;
	}

	my $maxTry = 4;
	my $tryCnt = 0;

	#wait, until server script is not ready
	while ( !defined $inCAM || !$inCAM->{"socketOpen"} || !$inCAM->{"connected"} ) {

		if ( $tryCnt >= $maxTry ) {

			print STDERR "CLIENT(parent): PID: $$  is not able to connect server on port: $port\n";
			return 0;
		}

		if ( $inCAM && $tryCnt > 0 ) {

			print STDERR "CLIENT(parent): PID: $$  try connect to server port: $port....failed\n";
			sleep(0.2);
		}

		$inCAM = InCAMWrapper->new( "remote" => 'localhost', "port" => $self->{"server"}->{"port"} );

		$tryCnt++;
	}

	#server seems ready, try send message and get server pid
	my $pidServer = $inCAM->ServerReady();

	$self->{"server"}->{"inCAM"} = $inCAM;

	#$self->{"server"}->{"pid"} = $pidServer;

	#if ok, make space for new client (child process)
	if ($pidServer) {
		$self->{"server"}->{"connected"} = 1;

		return 1;
	}
	else {

		return 0;
	}

}

#sub DestroyServer {
#	my $self = shift;
#
#	my $server = $self->{"server"};
#
#	print STDERR "\n\nSERVER PID IS " . $server->{"pidServer"} . "\n\n";
#
#	Win32::Process::KillProcess( $server->{"pidServer"}, 0 );
#
#	#Win32::Process::KillProcess( $server->{"pidInCAM"},  0 );
#
#	print STDERR "SERVER: PID: " . $server->{"pidServer"} . ", port:" . $server->{"port"} . "....................................was closed\n";
#
#	#${$serverRef}[$idx]{"state"}     = FREE_SERVER;
#	#${$serverRef}[$idx]{"pidInCAM"}  = -1;
#	#${$serverRef}[$idx]{"pidServer"} = -1;
#}

## Used when InCAMe need to be connected in child thread
## 1. Call Disconnect
## 2. Use inCAM library in child thread
## 3. Call Connect again
#sub Disconnect {
#	my $self = shift;
#
#	if ( $self->{"server"}->{"inCAM"}->IsConnected() ) {
#
#		$self->{"server"}->{"inCAM"}->ClientFinish();
#	}
#	else {
#		die "Unable to disconnect, because InCAM is not connected";
#	}
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
