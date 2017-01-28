#-------------------------------------------------------------------------------------------#
# Description: Class responsible for keep free servers and launch server on demand
# See all other methods
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AsyncJobMngr::ServerMngr::ServerMngr;

#3th party library
use strict;
use threads;
use threads::shared;
use Win32::Process;
use Wx;
use Config;
use Win32::GuiTest qw(FindWindowLike SetWindowPos ShowWindow);
use Time::HiRes qw (sleep);

#use Try::Tiny;

use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Managers::AsyncJobMngr::Helper';
use aliased 'Managers::AsyncJobMngr::Enums';
use aliased 'Managers::AsyncJobMngr::ServerMngr::ServerInfo';

#use aliased 'Enums::EnumsGeneral';
#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

my $PORT_READY_EXPORTER_EVT : shared;
my $PORT_READY_EVT : shared;

sub new {

	my $self = shift;    # Create an anonymous hash, and #self points to it.
	$self = {};
	bless $self;         # Connect the hash to the package Cocoa.

	my @servers = ();

	$self->{"servers"} = \@servers;

	$self->{"maxCntUser"}      = -1;      # max count of server set by user
	$self->{"maxCntTotal"}     = 9;       # max allowed number of server
	$self->{"actualCntRuning"} = -1;
	$self->{"startPort"}       = 1000;    # Port for ExportUtility start from 1000, Port for ExportChecker start from 2000,

	$self->{"destroyOnDemand"} = 1;       # close server only on demand, not immediately
	$self->{"destroyDelay"}    = -1;      # destroy server after 12s of WAITING state

	$self->__InitServers();

	return $self;                         # Return the reference to the hash.
}

# ==============================================
# Public method
# ==============================================

sub Init {
	my $self = shift;

	$self->{"exporterFrm"} = shift;

	$PORT_READY_EXPORTER_EVT = ${ shift(@_) };

	$PORT_READY_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"exporterFrm"}, -1, $PORT_READY_EVT, sub { $self->__PortReadyHandler(@_) } );

}

# Check if free server are available
sub IsFreePortAvailable {
	my $self    = shift;
	my $jobGUID = shift;

	my $serverRef = $self->{"servers"};

	my $freePort = 0;

	#check if some server is ready == is WAITING
	for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {

		if ( ${$serverRef}[$i]->{"state"} eq Enums->State_FREE_SERVER ) {

			return 1;
		}
	}

	return 0;
}

# Check if waiting/free server are available
sub IsPortAvailable {
	my $self    = shift;
	my $jobGUID = shift;

	# Test if next server exceed max server count set by user
	if ( $self->__ExceedServersCnt() ) {
		return 0;
	}

	my $serverRef = $self->{"servers"};

	my $freePort = 0;
	my $s;

	#check if some server is ready == is WAITING or FREE
	for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {

		$s = ${$serverRef}[$i];

		if ( ( $s->{"state"} eq Enums->State_WAITING_SERVER || $s->{"state"} eq Enums->State_FREE_SERVER ) && !$s->{"external"} ) {

			return 1;
		}
	}

	return 0;
}

# Check is there is some server in state - waiting
# If not, start launching new InCAM server
sub PrepareServerPort {
	my $self    = shift;
	my $jobGUID = shift;

	my $serverRef = $self->{"servers"};

	#lock @servers

	#my $prepare  = 0;    #indicate, if prot will be prepared or there is no free port
	my $freePort = 0;
	my $s;

	#check if some server is ready == is WAITING
	for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {

		$s = ${$serverRef}[$i];

		if ( $s->{"state"} eq Enums->State_WAITING_SERVER && !$s->{"external"} ) {

			$s->{"state"} = Enums->State_RUNING_SERVER;
			$freePort = $s->{"port"};

			#$prepare = 1;
			$self->__PortReady( $freePort, $jobGUID );    #send event, port ready

			last;

			#return $prepare;

		}
	}

	#test if some server is at least FREE
	unless ($freePort) {
		my $s;

		for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {

			$s = ${$serverRef}[$i];

			if ( $s->{"state"} eq Enums->State_FREE_SERVER && !$s->{"external"} ) {

				$s->{"state"} = Enums->State_PREPARING_SERVER;

				#create server in separete ports
				my $port = $s->{"port"};

				my $worker = threads->create( sub { $self->__CreateServer( $port, $jobGUID ) } );

				last;
			}
		}

	}

}

# Method is used, when some external InCAM is already
# init (launched and server script on some port is running inside)
# Only assign this port to some "server number", if free numbers are available
sub PrepareExternalServerPort {
	my $self       = shift;
	my $jobGUID    = shift;
	my $serverInfo = shift;

	my $serverRef = $self->{"servers"};

	#test if some server is FREE

	for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {

		if ( ${$serverRef}[$i]->{"state"} eq Enums->State_FREE_SERVER ) {

			# save default and set real port number of server
			${$serverRef}[$i]->{"port"}     = $serverInfo->{"port"};
			${$serverRef}[$i]->{"external"} = 1;

			#test, if server is really ready. Try to connect
			my $worker = threads->create( sub { $self->__CreateServerExternal( $serverInfo->{"port"}, $jobGUID ) } );

			last;

		}
	}
}

# If thread finish its job, return port
# Manager decide if close server definitely or if switch server to state WAITING
sub ReturnServerPort {
	my $self     = shift;
	my $busyPort = shift;

	my $serverRef = $self->{"servers"};

	my @s = @{$serverRef};
	my $idx = ( grep { $s[$_]->{"state"} eq Enums->State_RUNING_SERVER && $s[$_]->{"port"} == $busyPort } 0 .. $#s )[0];

	if ( defined $idx ) {

		if ( $self->{"destroyOnDemand"} ) {
			${$serverRef}[$idx]->{"state"} = Enums->State_WAITING_SERVER;
			${$serverRef}[$idx]{"waitingFrom"} = time();

			Helper->Print(   "SERVER: PID: "
						   . ${$serverRef}[$idx]->{"pidServer"}
						   . ", port:"
						   . ${$serverRef}[$idx]->{"port"}
						   . "....................................is waiting\n" );

		}
		else {

			# If server is external, not destroy
			# Server will by destroyed "mannualy" by DestroyExternalServer method
			if ( ${$serverRef}[$idx]->{"external"} ) {

				return 0;
			}
			else {

				$self->DestroyServer($busyPort);
			}

		}
	}
}

# Periodically called method.
# Check all waiting servers and delete that one,
# which wait longer time than time given by "delayTime"
sub DestroyServersOnDemand {
	my $self      = shift;
	my $serverRef = $self->{"servers"};

	unless ( $self->{"destroyOnDemand"} ) {
		return 0;
	}

	my $waitFrom;

	for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {

		if ( ${$serverRef}[$i]->{"state"} eq Enums->State_WAITING_SERVER ) {

			#test if wait more than 2 minutes
			$waitFrom = ${$serverRef}[$i]{"waitingFrom"};

			if ( time() - $waitFrom > $self->{"destroyDelay"} ) {
				$self->DestroyServer( ${$serverRef}[$i]->{"port"} );
			}
		}
	}
}

# ==============================================
# Settings server property
# ==============================================
sub SetMaxServerCount {
	my $self   = shift;
	my $maxCnt = shift;

	if ( $maxCnt <= $self->{"maxCntTotal"} ) {
		$self->{"maxCntUser"} = $maxCnt;
		return 1;
	}
	else {
		return 0;
	}
}

# Destroy delay in second
sub SetDestroyDelay {
	my $self    = shift;
	my $seconds = shift;

	if ( $seconds >= 0 ) {
		$self->{"destroyDelay"} = $seconds;
		return 1;
	}
	else {
		return 0;
	}
}

# Set, if servers will by closed just after thread finish its job
# Or server will be switched to state - WAITING
sub SetDestroyOnDemand {
	my $self     = shift;
	my $onDemand = shift;

	unless ($onDemand) {

		#destroy all actually waiting servers
		my $serverRef = $self->{"servers"};

		for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {

			if ( ${$serverRef}[$i]->{"state"} eq Enums->State_WAITING_SERVER ) {

				$self->DestroyServer( ${$serverRef}[$i]->{"port"} );
			}
		}
	}

	$self->{"destroyOnDemand"} = $onDemand;
}

# Method for destroying "external" server
# ServerMngr is not responsible for destroying InCAM
# So only exit server and set server as free
sub DestroyExternalServer {
	my $self = shift;
	my $port = shift;

	my $serverRef = $self->{"servers"};

	my @s = @{$serverRef};
	my $idx = ( grep { $s[$_]->{"port"} == $port } 0 .. $#s )[0];

	if ( defined $idx ) {

		#Win32::Process::KillProcess( $s->{"pidServer"}, 0 );
		# set default  port number
		${$serverRef}[$idx]->{"port"} = ${$serverRef}[$idx]->{"portDefault"};

		#${$serverRef}[$idx]->{"portDefault"} = -1;

		${$serverRef}[$idx]->{"state"}     = Enums->State_FREE_SERVER;
		${$serverRef}[$idx]->{"pidInCAM"}  = -1;
		${$serverRef}[$idx]->{"pidServer"} = -1;
	}
}

# Kill InCAM server
sub DestroyServer {
	my $self      = shift;
	my $port      = shift;
	my $serverRef = $self->{"servers"};

	my @s = @{$serverRef};
	my $idx = ( grep { $s[$_]->{"port"} == $port } 0 .. $#s )[0];
	if ( defined $idx ) {

		# never kill "external" server
		if ( ${$serverRef}[$idx]->{"external"} ) {
			return 0;
		}

		my $s = @{$serverRef}[$idx];
		
		my $closedSucc = 0;
		
		#try to connect to server and close it nice
		
		my $inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );
		if( $inCAM->ServerReady()){
			
			my $closed = $inCAM->COM("close_toolkit");
			
			if($closed == 0){
				$closedSucc = 1;
				
				# we has to close server perl scritp, unless inCAM will be still running
				Win32::Process::KillProcess( $s->{"pidServer"}, 0 );
				print STDERR "\n\n close toolikt ################ \n\n";
			}
		}
		
		unless($closedSucc){	 

			Win32::Process::KillProcess( $s->{"pidServer"}, 0 );
			Win32::Process::KillProcess( $s->{"pidInCAM"},  0 );
		}
		


		Helper->Print( "SERVER: PID: " . $s->{"pidServer"} . ", port:" . $s->{"port"} . "....................................was closed\n" );

		${$serverRef}[$idx]->{"state"}     = Enums->State_FREE_SERVER;
		${$serverRef}[$idx]->{"pidInCAM"}  = -1;
		${$serverRef}[$idx]->{"pidServer"} = -1;

	}
}

sub GetInfoServers {
	my $self = shift;

	my $serverRef = $self->{"servers"};
	my $str       = "";

	for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {

		$str .= "port: " . ${$serverRef}[$i]->{"port"} . "\n";
		$str .= "- state: " . ${$serverRef}[$i]->{"state"} . "\n";
		$str .= "- pidInCAM: " . ${$serverRef}[$i]->{"pidInCAM"} . "\n";
		$str .= "- pidServer: " . ${$serverRef}[$i]->{"pidServer"} . "\n\n";

	}

	return $str;
}

sub GetServerSettings {
	my $self = shift;

	my %sett = ();

	$sett{"maxCntUser"}      = $self->{"maxCntUser"};
	$sett{"destroyDelay"}    = $self->{"destroyDelay"};
	$sett{"destroyOnDemand"} = $self->{"destroyOnDemand"};

	return %sett;
}

# Return server statistic
sub GetServerStat {
	my $self = shift;

	my %stat = ();

	my @serverRef = @{ $self->{"servers"} };

	$stat{"running"} = scalar( grep { $_->{"state"} eq Enums->State_RUNING_SERVER } @serverRef );
	$stat{"waiting"} = scalar( grep { $_->{"state"} eq Enums->State_WAITING_SERVER } @serverRef );

	# waiting, which are not external
	$stat{"waitingNoExt"} = scalar( grep { $_->{"state"} eq Enums->State_WAITING_SERVER && !$_->{"external"} } @serverRef );
	$stat{"preparing"}    = scalar( grep { $_->{"state"} eq Enums->State_PREPARING_SERVER } @serverRef );
	$stat{"free"}         = scalar( grep { $_->{"state"} eq Enums->State_FREE_SERVER } @serverRef );

	# free server which are not used (user set server count which can be used by maxCntUser)
	my $notUsed = $self->{"maxCntTotal"} - $self->{"maxCntUser"};

	# thus, edit readl free server scount
	$stat{"free"} = $stat{"free"} - $notUsed;

	return %stat;
}

# ==============================================
# Private method
# ==============================================

# This method is called asynchronously
# Start InCAM with "server" script and wait untill
# server is ready (till client can connect to serer script)
sub __CreateServer {

	my $self     = shift;
	my $freePort = shift;
	my $jobGUID  = shift;

	my $pidInCAM;
	my $pidServer;

	#test on zombified server and close
	$self->__CloseZombie($freePort);

	#start new server on $freePort

	my $inCAMPath = GeneralHelper->GetLastInCAMVersion();

	unless ( -f $inCAMPath )    # does it exist?
	{
		print "InCAM does not exist on path: " . $inCAMPath;
		return 0;
	}

	my $processObj;
	my $inCAM;
	
	my $path =  GeneralHelper->Root() . "\\Managers\\AsyncJobMngr\\Server\\ServerExporter.pl";
	# turn all backslash - incam need this
	$path =~ s/\\/\//g;
	

	#run InCAM editor with serverscript
	Win32::Process::Create( $processObj, $inCAMPath,
							"InCAM.exe -x -s" . $path." " . $freePort,
							0, THREAD_PRIORITY_NORMAL, "." )
	  || die "$!\n";

	$pidInCAM = $processObj->GetProcessID();

	# Temoporary solution because -x is not working in inCAM
	#$self->__MoveWindowOut($pidInCAM);

	#my $worker = threads->create( sub { $self->__MoveWindowOut($pidInCAM) } );

	Helper->Print( "CLIENT PID: " . $pidInCAM . " (InCAM)........................................is launching\n" );

	# creaate and test server connection
	$pidServer = $self->__CreateServerConn($freePort);


	#if ok, reise event port ready
	if ($pidServer) {

		Helper->Print("PORT: $freePort ......................................................is ready\n");

		my %res : shared = ();

		$res{"port"}      = $freePort;
		$res{"jobGUID"}   = $jobGUID;
		$res{"pidInCAM"}  = $pidInCAM;
		$res{"pidServer"} = $pidServer;

		my $threvent = new Wx::PlThreadEvent( -1, $PORT_READY_EVT, \%res );
		Wx::PostEvent( $self->{"exporterFrm"}, $threvent );

	}
	else {
		print STDERR "Error when running serverscript for InCAM";
		return 0;
	}

	#no another free ports
	return 0;
}

# Method test, if external server is ready for client
# This method is called asynchronously
sub __CreateServerExternal {
	my $self     = shift;
	my $freePort = shift;
	my $jobGUID  = shift;

	my $pidInCAM;
	my $pidServer;

	# creaate and test server connection
	$pidServer = $self->__CreateServerConn($freePort);

	#if ok, reise event port ready
	if ($pidServer) {

		Helper->Print("PORT: $freePort ......................................................is ready\n");

		my %res : shared = ();

		$res{"port"}      = $freePort;
		$res{"jobGUID"}   = $jobGUID;
		$res{"pidInCAM"}  = undef;
		$res{"pidServer"} = $pidServer;

		my $threvent = new Wx::PlThreadEvent( -1, $PORT_READY_EVT, \%res );
		Wx::PostEvent( $self->{"exporterFrm"}, $threvent );

	}
	else {
		print STDERR "Error when running serverscript for InCAM";
		return 0;
	}
}

# This helper function, wait until new incam server is ready
# Try to conenct every 2 second
# Called in asynchrounous thread
sub __CreateServerConn {
	my $self = shift;
	my $port = shift;

	my $inCAM;

	# first test of connection
	$inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );

	# next tests of connecton. Wait, until server script is not ready
	while ( !defined $inCAM || !$inCAM->{"socketOpen"} || !$inCAM->{"connected"} ) {
		if ($inCAM) {

			# print RED, "Stop!\n", RESET;

			Helper->Print("CLIENT(parent): PID: $$  try connect to server port: $port....failed\n");
		}
		sleep(2);

		$inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );
	}

	#server seems ready, try send message and get server pid
	my $pidServer = $inCAM->ServerReady();

	if ($pidServer) {
		$inCAM->ClientFinish();

		return $pidServer;
	}
	else {

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

			ShowWindow( $_, 0 );
			SetWindowPos( $_, 0, -10000, -10000, 0, 0, 0 );

			return 1;
		}
		
		sleep(0.02);

		#print STDERR ".";
	}

}

sub __InitServers {
	my $self = shift;

	my $serverRef = $self->{"servers"};

	for ( my $i = 0 ; $i < $self->{"maxCntTotal"} ; $i++ ) {

		my $sInfo = ServerInfo->new();

		# set default port number
		$sInfo->{"portDefault"} = $self->{"startPort"} + $i + 1;    #server ports 1001, 1002....

		# set working port number
		$sInfo->{"port"} = $sInfo->{"portDefault"};

		push( @{$serverRef}, $sInfo );
	}

}

# Close InCAM servers, which are not properly exited
# E.g when AsyncMngr break down...
sub __CloseZombie {

	my $self = shift;
	my $port = shift;

	my $processObj;
	my $perl = $Config{perlpath};

	Win32::Process::Create( $processObj, $perl, "perl " . GeneralHelper->Root() . "\\Managers\\AsyncJobMngr\\CloseZombie.pl -i $port",
							1, NORMAL_PRIORITY_CLASS, "." )
	  || die "Failed to create CloseZombie process.\n";

	$processObj->Wait(INFINITE);

}

sub __PortReady {
	my ( $self, $port, $pcbId, $pidInCAM ) = @_;

	my %res : shared = ();
	$res{"port"}     = $port;
	$res{"jobGUID"}  = $pcbId;
	$res{"pidInCAM"} = $pidInCAM;

	my $threvent = new Wx::PlThreadEvent( -1, $PORT_READY_EXPORTER_EVT, \%res );
	Wx::PostEvent( $self->{"exporterFrm"}, $threvent );
}

sub __PortReadyHandler {

	my ( $self, $frame, $event ) = @_;
	my $serverRef = $self->{"servers"};

	my %d = %{ $event->GetData() };

	my @s = @{$serverRef};
	my $idx = ( grep { $s[$_]->{"port"} == $d{"port"} } 0 .. $#s )[0];

	if ( defined $idx ) {

		${$serverRef}[$idx]->{"state"}     = Enums->State_RUNING_SERVER;
		${$serverRef}[$idx]->{"port"}      = $d{"port"};
		${$serverRef}[$idx]->{"pidInCAM"}  = $d{"pidInCAM"};
		${$serverRef}[$idx]->{"pidServer"} = $d{"pidServer"};

		$self->__PortReady( $d{"port"}, $d{"jobGUID"}, $d{"pidInCAM"} );
	}
}

# Test if tehere is request for launchong another server
# if max number would be exceeded, return false
sub __ExceedServersCnt {
	my $self = shift;

	my %stat = $self->GetServerStat();

	my $serverRef = $self->{"servers"};

	my $maxUser  = $self->{"maxCntUser"};
	my $maxTotal = $self->{"maxCntTotal"};

	# potencially cnt exceeded
	if ( $stat{"free"} == 0 ) {

		if ( $stat{"waitingNoExt"} ) {

			# Ok
			return 0;
		}
		else {

			# another server would be exceed server count
			return 1;
		}
	}

	return 0;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
