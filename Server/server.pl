


#3th party library
 use strict;
use IO::Select;

use IO::Socket;
 use Win32::Process;
use Config;
use Win32::GuiTest qw(FindWindowLike SetWindowPos ShowWindow);
use Time::HiRes qw (sleep);
 
use Log::Log4perl qw(get_logger);

#use Try::Tiny;
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAM::InCAM';
 
use aliased 'Packages::Other::AppConf';
 

my %clients = ();

my $main_socket = new IO::Socket::INET(
										LocalHost => 'localhost',
										LocalPort => 1200,
										Proto     => 'tcp',
										Listen    => 5,
										Reuse     => 1,
);
die "Could not connect: $!" unless $main_socket;


my $cnt = 0;

# Forking server
use IO::Socket;
$SIG{CHLD} = sub { wait() };

 
die "Socket could not be created. Reason: $!\n" unless ($main_socket);
while ( my $new_sock = $main_socket->accept() ) {
	
	print STDERR "Child count $cnt\n";
	$cnt++;
	
	sleep (5);
	
	my $pid = fork();
	die "Cannot fork: $!" unless defined($pid);
	
	if ( $pid == 0 ) {
		
		$cnt++;
		
		 

		# Child process
		while ( defined( my $buf = <$new_sock> ) ) {

			print STDERR $buf;
			
			
			
			#__CreateServer(1234);
			
			print STDERR "InCAM ready for client $buf\n";

			# do something with $buf ....
			print $new_sock "Server reply: $buf\n";
		}
		exit(0);    # Child process exits when it is done.
	}    # else 'tis the parent process, which goes back to accept()
}


close($main_socket);




sub __CreateServer {

	 
	my $freePort   = shift;
	 
 

	my $pidInCAM;
	my $pidServer;
	my $fIndicator = GeneralHelper->GetGUID();    # file name, where is value, which indicate if server is ready 1/0

	# create indicator file

	# 2) try to create inCAM server
	while (1) {
		
		

		# launch InCAm instance + server
		$pidInCAM =  __CreateInCAMInstance( $freePort, $fIndicator );

		# creaate and test server connection
		$pidServer =  __CreateServerConn( $freePort, $fIndicator );

		# if pid server returned, incam server is ok
		if ($pidServer) {

			last;
		}

		 
	}
  
}


# This helper function, wait until new incam server is ready
# Try to conenct every 2 second
# Called in asynchrounous thread
sub __CreateInCAMInstance {
	 
	my $port       = shift;
	my $fIndicator = shift;

	my $pidInCAM;

	#1 )test on zombified server and close
	#$self->__CloseZombie( $port, 1 );

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
	Win32::Process::Create( $processObj, $inCAMPath, "InCAM.exe -s" . $path . " " . $port . " " . $fIndicator, 0, THREAD_PRIORITY_NORMAL, "." )
	  || die "$!\n";

	$pidInCAM = $processObj->GetProcessID();
 
	#$self->{"threadLoger"}->debug("CLIENT PID: " . $pidInCAM . " (InCAM)........................................is launching\n");

	return $pidInCAM;
}

# This helper function, wait until new incam server is ready
# Try to conenct every 2 second
# Called in asynchrounous thread
sub __CreateServerConn {
 
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
 
			#$self->{"threadLoger"}->debug("CLIENT(parent): PID: $$  try connect to server port: $port, attempt: $i ....failed\n");

			sleep(1);
		}
	}else{
		
		# InCam is prepared  (external sever)
		$inCAMLaunched = 1;
	}
	
	unless($inCAMLaunched){
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
		$inCAM->ClientFinish();

		return $pidServer;
	}
	else {
		die "\nError connect to incam server";
		return 0;
	}
}

