#-------------------------------------------------------------------------------------------#
# Description: Helper pro obecne operace se soubory
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AsyncJobMngr::ServerMngr::ServerMngr;

#3th party library
use strict;

use threads;
use threads::shared;
use Wx;
use Config;
use Win32::GuiTest qw(FindWindowLike SetWindowPos ShowWindow);

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

	$self->{"maxCntUser"}      = 5;
	$self->{"maxCntTotal"}     = 9;       #max allowed number of server
	$self->{"actualCntRuning"} = 0;
	$self->{"startPort"}       = 1000;    #Port for ExportUtility start from 1000, Port for ExportChecker start from 2000,

	$self->{"destroyOnDemand"} = 1;       #close server only on demand, not immediately
	$self->{"destroyDelay"}    = 10;      #destroy server after 12s of WAITING state

	$self->__InitServers();

	return $self;                         # Return the reference to the hash.
}

sub Init {
	my $self = shift;

	$self->{"exporterFrm"} = shift;

	$PORT_READY_EXPORTER_EVT = ${ shift(@_) };

	$PORT_READY_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"exporterFrm"}, -1, $PORT_READY_EVT, sub { $self->__PortReadyHandler(@_) } );

}

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

# destroy delay in second
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

	my $serverRef = $self->{"servers"};

	my $freePort = 0;

	#check if some server is ready == is WAITING
	for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {

		if ( ${$serverRef}[$i]->{"state"} eq Enums->State_WAITING_SERVER || ${$serverRef}[$i]->{"state"} eq Enums->State_FREE_SERVER ) {

			return 1;
		}
	}

	return 0;
}

sub PrepareServerPort {
	my $self    = shift;
	my $jobGUID = shift;

	my $serverRef = $self->{"servers"};

	#test on free server
	#lock @servers

	#my $prepare  = 0;    #indicate, if prot will be prepared or there is no free port
	my $freePort = 0;

	#check if some server is ready == is WAITING

	#check if some server is ready == is WAITING
	for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {

		if ( ${$serverRef}[$i]->{"state"} eq Enums->State_WAITING_SERVER ) {

			${$serverRef}[$i]->{"state"} = Enums->State_RUNING_SERVER;
			$freePort = ${$serverRef}[$i]->{"port"};

			#$prepare = 1;
			$self->__PortReady( $freePort, $jobGUID );    #send event, port ready

			last;

			#return $prepare;

		}
	}

	#test if some server is at least FREE
	unless ($freePort) {
		for ( my $i = 0 ; $i < scalar( @{$serverRef} ) ; $i++ ) {

			if ( ${$serverRef}[$i]->{"state"} eq Enums->State_FREE_SERVER ) {

				${$serverRef}[$i]->{"state"} = Enums->State_PREPARING_SERVER;

				#create server in separete ports
				my $port = ${$serverRef}[$i]->{"port"};

				my $worker = threads->create( sub { $self->__CreateServer( $port, $jobGUID ) } );

				#$worker->detach();

				last;

				#$freePort = $self->__CreateServer( $idx2 + 1, \$pidInCAM, \$pidServer );

				#$prepare = 1;    #port will be ready

				#return $prepare;

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

			#
			#
			#
			#			my $inCAM = InCAM->new("remote" => 'localhost', "port" => $serverInfo->{"port"} );
			#
			#			# next tests of connecton. Wait, until server script is not ready
			#			if ( !$inCAM->{"socketOpen"} || !$inCAM->{"connected"} ) {
			#				return 0;
			#			}
			#
			#			my $pidServer = $inCAM->ServerReady();
			#
			#			#if ok, make space for new client (child process)
			#			if ($pidServer) {
			#				$inCAM->ClientFinish();
			#			}
			#
			#			${$serverRef}[$i]->{"state"}     = Enums->State_RUNING_SERVER;
			#			${$serverRef}[$i]->{"port"}      = $serverInfo->{"port"};
			#			${$serverRef}[$i]->{"pidInCAM"}  = $serverInfo->{"pidInCAM"};
			#			${$serverRef}[$i]->{"pidServer"} = $pidServer;
			#			${$serverRef}[$i]->{"external"}  = 1;
			#
			#			$self->__PortReady( $serverInfo->{"port"}, $jobGUID );

			last;

		}
	}

}

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

#check all waiting servers and delete that one, which wait more than 2 minute
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

sub __CreateServer {

	my $self     = shift;
	my $freePort = shift;
	my $jobGUID  = shift;

	use Win32::Process;

	#my $serverRef = $self->{"servers"};
	my $pidInCAM;
	my $pidServer;

	#my $freePort = $self->{"startPort"} + $serverNumber;

	#test on yombified server and close
	$self->__CloseZombie($freePort);

	#	for ( my $i = 0 ; $i < $self->{"maxCntTotal"} ; $i++ ) {
	#
	#		my @res = grep { $_{"port"} == $self->{"startPort"} + $i } @{$serverRef};
	#
	#		unless (@res) {
	#			$freePort = $self->{"startPort"} + $i;
	#			last;
	#		}
	#
	#	}

	#start new server on $freePort

	my $inCAMPath = GeneralHelper->GetLastInCAMVersion();

	unless ( -f $inCAMPath )    # does it exist?
	{
		print "InCAM does not exist on path: " . $inCAMPath;
		return 0;
	}

	my $processObj;
	my $inCAM;

	#run InCAM editor with serverscript
	Win32::Process::Create( $processObj, $inCAMPath,
							"InCAM.exe    -s" . GeneralHelper->Root() . "\\Managers\\AsyncJobMngr\\Server\\ServerExporter.pl  " . $freePort,
							0, THREAD_PRIORITY_NORMAL, "." )
	  || die "$!\n";

	$pidInCAM = $processObj->GetProcessID();

	# Temoporary solution because -x is not working in inCAM
	$self->__MoveWindowOut($pidInCAM);

	Helper->Print( "CLIENT PID: " . $pidInCAM . " (InCAM)........................................is launching\n" );

	# creaate and test server connection
	$pidServer = $self->__CreateServerConn($freePort);

	# Temoporary solution because -x is not working in inCAM
	$self->__MoveWindowOut($pidInCAM);

	#if ok, make space for new client (child process)
	if ($pidServer) {

		#$inCAM->ClientFinish();

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

sub __CreateServerExternal {
	my $self     = shift;
	my $freePort = shift;
	my $jobGUID  = shift;

	my $pidInCAM;
	my $pidServer;

	# creaate and test server connection
	$pidServer = $self->__CreateServerConn($freePort);

	#if ok, make space for new client (child process)
	if ($pidServer) {

		#$inCAM->ClientFinish();

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

sub __MoveWindowOut {
	my $self = shift;
	my $pid  = shift;

	my @windows = FindWindowLike( 0, "$pid" );
	for (@windows) {

		#print "$_>\t'", GetWindowText($_), "'\n";

		ShowWindow( $_, 0 );
		SetWindowPos( $_, 0, -10000, -10000, 0, 0, 0 );

	}
}

sub __InitServers {
	my $self = shift;

	my $serverRef = $self->{"servers"};

	for ( my $i = 0 ; $i < $self->{"maxCntUser"} ; $i++ ) {

		my $sInfo = ServerInfo->new();

		# set default port number
		$sInfo->{"portDefault"} = $self->{"startPort"} + $i + 1,    #server ports 1001, 1002....

		  # set working port number
		  $sInfo->{"port"} = $sInfo->{"portDefault"};

		push( @{$serverRef}, $sInfo );
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

	my $point =

	  $stat{"running"} = scalar( grep { $_->{"state"} eq Enums->State_RUNING_SERVER } @serverRef );
	$stat{"waiting"}   = scalar( grep { $_->{"state"} eq Enums->State_WAITING_SERVER } @serverRef );
	$stat{"preparing"} = scalar( grep { $_->{"state"} eq Enums->State_PREPARING_SERVER } @serverRef );
	$stat{"free"}      = scalar( grep { $_->{"state"} eq Enums->State_FREE_SERVER } @serverRef );

	return %stat;
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

		if ( ${$serverRef}[$idx]->{"state"} eq Enums->State_PREPARING_SERVER ) {

			print "\n\nPREPAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAR\n\n";
		}

		Win32::Process::KillProcess( $s->{"pidServer"}, 0 );
		Win32::Process::KillProcess( $s->{"pidInCAM"},  0 );

		Helper->Print( "SERVER: PID: " . $s->{"pidServer"} . ", port:" . $s->{"port"} . "....................................was closed\n" );

		${$serverRef}[$idx]->{"state"}     = Enums->State_FREE_SERVER;
		${$serverRef}[$idx]->{"pidInCAM"}  = -1;
		${$serverRef}[$idx]->{"pidServer"} = -1;

	}

}

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
	my ( $self, $port, $pcbId ) = @_;

	my %res : shared = ();
	$res{"port"}    = $port;
	$res{"jobGUID"} = $pcbId;

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

		$self->__PortReady( $d{"port"}, $d{"jobGUID"} );
	}
}

#sub GetRunServerCnt {
#	my $self = shift;
#
#	return scalar( @{ $self->{"servers"} } );
#}

sub __SetMaxServerCnt {
	my $self = shift;
	$self->{"maxContUser"} = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $m     = Programs::Exporter::ServerMngr->new();
	#my $port1 = $m->GetServerPort();

	#sleep(500);

	#$m->ReturnServerPort($port1);

	#	my $port2 = $m->GetServerPort();
	#	my $port3 = $m->GetServerPort();
	#	my $port4 = $m->GetServerPort();
	#
	#	$m->ReturnServerPort($port1);
	#
	#	$port3 = $m->GetServerPort();
	#	$port4 = $m->GetServerPort();
	#
	#	$m->ReturnServerPort($port3);
	#	$port4 = $m->GetServerPort();
	#
	#	$m->ReturnServerPort($port4);
	#	$m->ReturnServerPort($port2);

	#$m->ReturnServerPort($port2);

	#	$m->ReturnServerPort($port3);
	#	$m->ReturnServerPort($port4);
	#	$m->ReturnServerPort($port5);
	#	$m->ReturnServerPort($port6);
	#	$m->ReturnServerPort($port7);
	#	$m->ReturnServerPort($port8);
	#	$m->ReturnServerPort($port9);

	#my $port2 = $m->GetServerPort();

	#$m->ReturnServerPort($port1);

	#$m->DestroyServersOnDemand();
	#sleep(10);
	#$m->DestroyServersOnDemand();
	#$m->ReturnServerPort($port3);
	#$m->ReturnServerPort($port1);

}

sub doExport {
	my ( $port, $id ) = @_;

	my $inCAM = InCAM->new( 'localhost', $port );

	$inCAM->VON();

	my $errCode = $inCAM->COM( "clipb_open_job", job => "F17116+2", update_clipboard => "view_job" );

	#
	#	$errCode = $inCAM->COM(
	#		"open_entity",
	#		job  => "F17116+2",
	#		type => "step",
	#		name => "test"
	#	);

	#return 0;
	#for ( my $i = 0 ; $i < 5 ; $i++ ) {

	$inCAM->COM(
				 'output_layer_set',
				 layer        => "top",
				 angle        => '0',
				 x_scale      => '1',
				 y_scale      => '1',
				 comp         => '0',
				 polarity     => 'positive',
				 setupfile    => '',
				 setupfiletmp => '',
				 line_units   => 'mm',
				 gscl_file    => ''
	);

	$inCAM->COM(
				 'output',
				 job                  => $id,
				 step                 => 'input',
				 format               => 'Gerber274x',
				 dir_path             => "c:/Perl/site/lib/TpvScripts/Scripts/data",
				 prefix               => "incam1_" . $id . "_i",
				 suffix               => "",
				 break_sr             => 'no',
				 break_symbols        => 'no',
				 break_arc            => 'no',
				 scale_mode           => 'all',
				 surface_mode         => 'contour',
				 min_brush            => '25.4',
				 units                => 'inch',
				 coordinates          => 'absolute',
				 zeroes               => 'Leading',
				 nf1                  => '6',
				 nf2                  => '6',
				 x_anchor             => '0',
				 y_anchor             => '0',
				 wheel                => '',
				 x_offset             => '0',
				 y_offset             => '0',
				 line_units           => 'mm',
				 override_online      => 'yes',
				 film_size_cross_scan => '0',
				 film_size_along_scan => '0',
				 ds_model             => 'RG6500'
	);

	#}

}

1;
