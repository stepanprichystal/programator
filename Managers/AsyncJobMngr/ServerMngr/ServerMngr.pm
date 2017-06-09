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
use Thread::Queue;
use Log::Log4perl qw(get_logger);

#use Try::Tiny;
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Managers::AsyncJobMngr::Helper';
use aliased 'Managers::AsyncJobMngr::Enums';
use aliased 'Managers::AsyncJobMngr::ServerMngr::ServerInfo';
use aliased 'Packages::Other::AppConf';
use aliased 'Managers::AbstractQueue::Helper' => "HelperAbstrQ";

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

	$self->{"maxCntUser"}      = -1;                                # max count of server set by user
	$self->{"maxCntTotal"}     = 9;                                 # max allowed number of server
	$self->{"actualCntRuning"} = -1;
	$self->{"startPort"}       = AppConf->GetValue("portStart");    # Port for ExportUtility start from 1000, Port for ExportChecker start from 2000,

	$self->{"destroyOnDemand"} = 1;                                 # close server only on demand, not immediately
	$self->{"destroyDelay"}    = -1;                                # destroy server after 12s of WAITING state

	$self->{"lastLaunch"} = undef;                                  # time when last server was launched (shared var)
	share( $self->{"lastLaunch"} );

	$self->{"appLoger"} = get_logger(Enums->Logger_APP); 
	$self->{"threadLoger"} = get_logger(Enums->Logger_SERVERTH); 
	 
	$self->__CloseZombie( undef, 0 );

	$self->__InitServers();

	return $self;                                                   # Return the reference to the hash.
}

# ==============================================
# Public method
# ==============================================

sub Init {
	my $self = shift;

	$self->{"abstractQueueFrm"} = shift;

	$PORT_READY_EXPORTER_EVT = ${ shift(@_) };

	$PORT_READY_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"abstractQueueFrm"}, -1, $PORT_READY_EVT, sub { $self->__PortReadyHandler(@_) } );

}

sub InitThreadPool {
	my $self = shift;

	# Maximum working threads, which start new incam
	$self->{"MAX_THREADS"} = 2;

	# Threads add their ID to this queue when they are ready for work
	# Also, when app terminates a -1 is added to this queue
	$self->{"IDLE_QUEUE"} = Thread::Queue->new();

	# Thread work queues referenced by thread ID
	my %work_queues;
	$self->{"work_queues"} = \%work_queues;

	# Create the thread pool
	for ( 1 .. $self->{"MAX_THREADS"} ) {
		
		$self->__AddThreadPool();

	}
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
	
	$self->{"appLoger"}->debug("Preparing server port for JobGUID: $jobGUID");

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

			my $inCAM = InCAM->new( "remote" => 'localhost',
									"port"   => $freePort );
									
			$inCAM->SetLogger(get_logger(Enums->Logger_INCAM));
									
			$self->{"appLoger"}->debug("Take waiting server. Port: $freePort");

			#server seems ready, try send message and get server pid
			my $pidServer = $inCAM->ServerReady();
 
 
			if ($pidServer) {
				
				$inCAM->ClientFinish();
				
				$self->{"appLoger"}->debug("Take waiting server. Server ready. Port: $freePort");
			}
			else {
	
				$self->{"appLoger"}->debug("Take waiting server. Server ready fail. Port: $freePort");


				# destroy broken server and try prepare port again
				$self->DestroyServer( $freePort, 1 );
				$self->PrepareServerPort($jobGUID);
				return 0;
			}

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
				
				$self->{"appLoger"}->debug("Free port exist, before create new incam server: $freePort");

				$s->{"state"} = Enums->State_PREPARING_SERVER;

				#create server in separete ports
				my $port = $s->{"port"};

				# Wait for an available thread
				my $tid = $self->{"IDLE_QUEUE"}->dequeue();

				# run thread

				my @ary : shared = ( $port, $jobGUID );
				$self->{"work_queues"}->{$tid}->enqueue( \@ary );

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
			#my $worker = threads->create( sub { $self->__CreateServerExternal( $serverInfo->{"port"}, $jobGUID ) } );
			$self->__CreateServerExternal( $serverInfo->{"port"}, $jobGUID );

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
	my $self         = shift;
	my $port         = shift;
	my $serverBroken = shift;    # if set to 1, don't try connect tot server

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
		unless ($serverBroken) {

			my $inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );
			if ( $inCAM->ServerReady() ) {

				my $closed = $inCAM->COM("close_toolkit");

				if ( $closed == 0 ) {
					$closedSucc = 1;

					# we has to close server perl scritp, unless inCAM will be still running
					Win32::Process::KillProcess( $s->{"pidServer"}, 0 );
					print STDERR "\n\n close toolikt ################ \n\n";
				}
			}
		}

		unless ($closedSucc) {

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
sub __AddThreadPool {
	my $self = shift;

	# Create a work queue for a thread
	my $work_q = Thread::Queue->new();

	# Create the thread, and give it the work queue
	my $thr = threads->create( sub { $self->__PoolWorker( $work_q, \$self->{"lastLaunch"} ) } );
	$thr->set_thread_exit_only(1);

	# Remember the thread's work queue
	$self->{"work_queues"}->{ $thr->tid() } = $work_q;
}

sub __PoolWorker {
	my $self       = shift;
	my $work_q     = shift;
	my $lastLaunch = shift;

	# This thread's ID
	my $tid = threads->tid();

	#	if ( AppConf->GetValue("logingType") == 2 ) {
	#
	#		HelperAbstrQ->Logging("ServerThreads", "LogThread_$tid" );
	#	}

	# Work loop
	do {

		# Indicate that were are ready to do work

		$self->{"IDLE_QUEUE"}->enqueue($tid);

		# Wait for work from the queue
		my $work = $work_q->dequeue();

		# Do work
		
		

		my $port    = $work->[0];
		my $jobGUID = $work->[1];
		
		$self->{"threadLoger"}->debug("Thread: $tid is creating new server for port: $port, $jobGUID: $jobGUID ");

		$self->__CreateServer( $port, $jobGUID, $lastLaunch );

		# Loop back to idle state if not told to terminate
	} while (1);
}

# This method is called asynchronously
# Start InCAM with "server" script and wait untill
# server is ready (till client can connect to serer script)
sub __CreateServer {

	my $self       = shift;
	my $freePort   = shift;
	my $jobGUID    = shift;
	my $lastLaunch = shift;

	# 1) Protection, more incam doesn't launch in same time
	my $lastTmp = $$lastLaunch;

	if ( defined $lastTmp ) {
		if ( $lastTmp + 5 > time() ) {

			# this is shared variable betwens threads, so set it as soon as possible
			# in order another income will not launch at same time (reserve this time for launch this incam)
			$$lastLaunch = $lastTmp + 5;

			#print "\nreserve time $freePort\n";
		}

		while ( $lastTmp + 15 > time() ) {
			sleep(1);

			$self->{"threadLoger"}->debug("Wait for gap 15 second between start servers: $freePort, $jobGUID ");
		}
	}

	$$lastLaunch = time();

	my $pidInCAM;
	my $pidServer;
	my $fIndicator = GeneralHelper->GetGUID();    # file name, where is value, which indicate if server is ready 1/0

	# create indicator file

	# 2) try to create inCAM server
	while (1) {
		
		

		# launch InCAm instance + server
		$pidInCAM = $self->__CreateInCAMInstance( $freePort, $fIndicator );

		# creaate and test server connection
		$pidServer = $self->__CreateServerConn( $freePort, $fIndicator );

		# if pid server returned, incam server is ok
		if ($pidServer) {

			last;
		}

		$self->{"threadLoger"}->debug("Launchin InCam server failed, try again: $freePort");
	}

	# 3) Temoporary solution because -x is not working in inCAM
	$self->__MoveWindowOut($pidInCAM);

	#if ok, reise event port ready
	if ($pidServer) {

		Helper->Print("PORT: $freePort ......................................................is ready\n");

		my %res : shared = ();

		$res{"port"}      = $freePort;
		$res{"jobGUID"}   = $jobGUID;
		$res{"pidInCAM"}  = $pidInCAM;
		$res{"pidServer"} = $pidServer;

		my $threvent = new Wx::PlThreadEvent( -1, $PORT_READY_EVT, \%res );
		Wx::PostEvent( $self->{"abstractQueueFrm"}, $threvent );

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
		Wx::PostEvent( $self->{"abstractQueueFrm"}, $threvent );

	}
	else {
		print STDERR "Error when running serverscript for InCAM";
		return 0;
	}
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
	$self->__CloseZombie( $port, 1 );

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

#THREAD_PRIORITY_NORMAL
#DETACHED_PROCESS
#CREATE_NEW_CONSOLE
	#run InCAM editor with serverscript
	
	
	use aliased 'Packages::SystemCall::SystemCall';
	
	my $script = GeneralHelper->Root() . "\\Managers\\AsyncJobMngr\\ServerMngr\\CreateInCAM.pl";
	my @cmds   = ( $inCAMPath, "InCAM.exe -s" . $path . " " . $port . " " . $fIndicator, );

	my $call = SystemCall->new( $script, \@cmds );
	my $result = $call->Run();

	my %output = $call->GetOutput();
	
	$pidInCAM = $output{"pidInCAM"};
	
	
#	
#	Win32::Process::Create( $processObj, $inCAMPath, "InCAM.exe -s" . $path . " " . $port . " " . $fIndicator, 0, THREAD_PRIORITY_NORMAL, "." )
#	  || die "$!\n";
#
#	$pidInCAM = $processObj->GetProcessID();
 
	$self->{"threadLoger"}->debug("CLIENT PID: " . $pidInCAM . " (InCAM)........................................is launching\n");

	return $pidInCAM;
}

# This helper function, wait until new incam server is ready
# Try to conenct every 2 second
# Called in asynchrounous thread
sub __CreateServerConn {
	my $self       = shift;
	my $port       = shift;
	my $fIndicator = shift;

	my $inCAMLaunched = 0;

	# if file indicator is not defined, it means, server is prepared external and is alreadz ready in this time
	if ( defined $fIndicator ) {

		my $pFIndicator = EnumsPaths->Client_INCAMTMPOTHER . $fIndicator;

		# 2 ) Test in loop if server is ready (file indicator has to contain value 1)
		for ( my $i = 0 ; $i < 25 ; $i++ ) {

			if ( open( my $f, "<", $pFIndicator ) ) {

				my $val = join( "", <$f> );
				close($f);

				if ( $val == 1 ) {

					unlink($pFIndicator);       # delete temp file
					sleep(1);                   # to be sure, server is ready to "listen" clients
					$inCAMLaunched = 1;
					last;
				}
			}
			else {
				print STDERR "Unable to open file $pFIndicator";
			}
 
			$self->{"threadLoger"}->debug("CLIENT(parent): PID: $$  try connect to server port: $port, attempt: $i ....failed\n");

			sleep(1);
		}
	}else{
		
		# InCam is prepared  (external sever)
		$inCAMLaunched = 1;
	}
	
	unless($inCAMLaunched){
		return 0;
	}

	#	my $inCAM;
	#
	#	# first test of connection
	#	$inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );
	#
	#
	#
	#	# next tests of connecton. Wait, until server script is not ready
	#	while ( !defined $inCAM || !$inCAM->{"socketOpen"} || !$inCAM->{"connected"} ) {
	#		if ($inCAM) {
	#
	#			# print RED, "Stop!\n", RESET;
	#
	#			Helper->Print("CLIENT(parent): PID: $$  try connect to server port: $port....failed\n");
	#		}
	#		sleep(1);
	#
	#		$inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );
	#	}

	# 3) Test connection with server

	my $inCAM = InCAM->new( "remote" => 'localhost',
							"port"   => $port );
							
	$inCAM->SetLogger(get_logger(Enums->Logger_INCAM));

	#server seems ready, try send message and get server pid
	my $pidServer = $inCAM->ServerReady();

	#print STDERR "Server ready, next client finish\n";

	if ($pidServer) {
		$inCAM->ClientFinish();

		return $pidServer;
	}
	else {
		die "\nError connect to incam server";
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
	my $wait = shift;

	# If port is not defined, kill all server with port in ranch
	my $range = "-";

	unless ( defined $port ) {
		$port = "-";
		$range = $self->{"startPort"} . "-" . ( $self->{"startPort"} + 999 );
	}

	my $processObj;
	my $perl = $Config{perlpath};

	Win32::Process::Create( $processObj, $perl, "perl " . GeneralHelper->Root() . "\\Managers\\AsyncJobMngr\\CloseZombie.pl -i $port -r $range",
							1, NORMAL_PRIORITY_CLASS, "." )
	  || die "Failed to create CloseZombie process.\n";

	if ($wait) {
		$processObj->Wait(INFINITE);
	}

}

sub __PortReady {
	my ( $self, $port, $pcbId, $pidInCAM ) = @_;

	my %res : shared = ();
	$res{"port"}     = $port;
	$res{"jobGUID"}  = $pcbId;
	$res{"pidInCAM"} = $pidInCAM;

	my $threvent = new Wx::PlThreadEvent( -1, $PORT_READY_EXPORTER_EVT, \%res );
	Wx::PostEvent( $self->{"abstractQueueFrm"}, $threvent );
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
