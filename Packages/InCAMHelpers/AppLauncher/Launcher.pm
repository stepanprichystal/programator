
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

#use Try::Tiny;

use aliased 'Packages::InCAM::InCAM';
use Win32::Process;

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
	
	$self->{"letServerRun"} = 0;

	unless ( $self->__Connect() ) {
		die "Unable to connect to InCAM editor, port: ".$self->{"server"}->{"port"};
	}

	return $self;                            # Return the reference to the hash.
}

sub GetInCAM {
	my $self = shift;

	return $self->{"server"}->{"inCAM"};

	
}




sub GetServerPort {
	my $self = shift;

	return $self->{"server"}->{"port"};
}

sub SetLetServerRun{
	my $self = shift;
	
	$self->{"letServerRun"} = 1;
}

sub GetLetServerRun{
	my $self = shift;
	
	return $self->{"letServerRun"} = 1;
}

sub CloseWaitFrm {
	my $self = shift;

	if ( $self->{"waitFrmPid"} ) {

		Win32::Process::KillProcess( $self->{"waitFrmPid"}, 0 );
	}

}



# First connection of InCAM library
sub __Connect {
	my $self    = shift;
	my $jobGUID = shift;

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

		if ($inCAM) {

			print STDERR "CLIENT(parent): PID: $$  try connect to server port: $port....failed\n";
			sleep(0.2);
		}

		$inCAM = InCAM->new( "remote" => 'localhost', "port" => $self->{"server"}->{"port"} );

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
