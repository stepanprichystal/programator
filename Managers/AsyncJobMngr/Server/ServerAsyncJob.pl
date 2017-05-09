#! /sw/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Server is launched in InCAM, which are launched by AszncJobMngr
# Contain some special behaviour like: Disconnect client, sloce server, etc
# Author:SPR
#-------------------------------------------------------------------------------------------#

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

=head
Set up a socket so that a remote user can send commands
Most of this has been copied from the Perl manual.
=cut

use threads;
use threads::shared;
use Socket;
use Carp;
use Sys::Hostname;
use Path::Tiny qw(path);
use Thread::Queue;
use Time::HiRes qw (sleep);

#use local library;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Enums::EnumsPaths';

my $IDLE_QUEUE  = Thread::Queue->new();
my %work_queues = ();

# Create a work queue for a thread
my $work_q = Thread::Queue->new();

# Create the thread, and give it the work queue
my $thr = threads->create( sub { __PoolWorker($work_q) } );
$thr->set_thread_exit_only(1);

# Remember the thread's work queue
$work_queues{ $thr->tid() } = $work_q;

sub __PoolWorker {
	my ($work_q) = @_;

	# This thread's ID
	my $tid = threads->tid();

	# Work loop
	do {

		$IDLE_QUEUE->enqueue($tid);

		# Wait for work from the queue
		my $work = $work_q->dequeue();

		my $readOk = $work->[0];

		print STDERR "ctu stdin\n";

		my $reply = <STDIN>;

		print STDERR $reply;

		$reply = <STDIN>;

		print STDERR $reply;

		if ($reply) {
			$$readOk = 1;
		}

	} while (1);
}

sub spawn;    # forward declaration
sub logmsg { print "$0 $$: @_ at ", scalar localtime, "\n" }

my $hostName = hostname;
my $hostIpAddr = inet_ntoa( ( gethostbyname(hostname) )[4] );

my $defaultPort = 56753;

#get information about port
my $serverPort;

# try to get information from arguments
my $arg        = $ARGV[0];
my $fIndicator = $ARGV[1];    # File name if server is ready

if ( defined $arg && $arg =~ /\d/ ) {
	$serverPort = $arg;
}
else {
	$serverPort = $defaultPort;    # 56753;
}

# The port has not been defined. To define it you need to
# become root and add the following line in /etc/services
# genesis     56753/tcp    # Genesis port for debugging perl scripts

#print STDERR "\n";
#print STDERR "\n\n\n11111111111 $serverPort 111111111111111111\n\n";

die "No port" unless $serverPort;
my $proto = getprotobyname('tcp');
socket( Server, PF_INET, SOCK_STREAM, $proto ) || die "socket: $!";
setsockopt( Server, SOL_SOCKET, SO_REUSEADDR, pack( "l", 1 ) ) || die "setsockopt: $!";

#print STDERR "\n\n\n222222222222222221111111\n\n";
bind( Server, sockaddr_in( $serverPort, INADDR_ANY ) ) || die "bind: $!";

# Tell to clients, server is ready (only if exist "file" <$fIndicator>)
if ( defined $fIndicator ) {

	my $pFIndicator = EnumsPaths->Client_INCAMTMPOTHER . $fIndicator;

	#my $pFIndicator = "c:\\tmp\\InCam\\scripts\\other\\" . $fIndicator;

	my $file = path($pFIndicator);

	my $data = $file->slurp_utf8;
	$data =~ s/0/1/i;
	$file->spew_utf8($data);
}

#print STDERR "\n\n\n1133333333333333333111\n\n";
listen( Server, SOMAXCONN ) || die "listen: $!";

my $waitedpid = 0;
my $paddr;

sub REAPER {
	$SIG{CHLD} = \&REAPER;    # loathe sysV
	$waitedpid = wait;

	# On the first successful reap, close down
	logmsg "reaped $waitedpid" . ( ($?) ? " with exit $?" : '' );

}

$SIG{CHLD} = \&REAPER;

for ( $waitedpid = 0 ; ( $paddr = accept( Client, Server ) ) || $waitedpid ; $waitedpid = 0, close Client ) {
	next if $waitedpid;
	my ( $port, $iaddr ) = sockaddr_in($paddr);
	my $name = gethostbyaddr( $iaddr, AF_INET );

	#print STDERR "\n==============novy klient pid $waitedpid=================\n";

	#logmsg "connection from $name [",inet_ntoa($iaddr), "]	at port $port";

	%replies = ( "PAUSE" => 3, "MOUSE" => 3, "COM" => 2, "AUX" => 2 );
	$DIR_PREFIX = '@%#%@';
	while ( $line = <Client> ) {

		( $text = $line ) =~ s/\@%#%\@//;

		#print "===============GOT A LINE $text\n";
		if ( ($command) = $line =~ /^\@%#%\@\s*(\S+)/ ) {

			# If server is ready, return PID of server script
			if ( $command =~ /SERVERREADY/ ) {
				$line =~ m/PID:(\d*)/;

				# otestuj, jestli incam je pripojen

				my $DIR_PREFIX = '@%#%@';

				#print "dd";
				$noReplies    = $replies{$command};
				$old_select   = select(STDOUT);
				$flush_status = $|;                   # save the flushing status\
				$|            = 1;                    # force flushing of the io buffer

				$line = "COM get_user_name\n";

				print $DIR_PREFIX, $line;             # this goes to Genesis

				$| = $flush_status;                   # restore the original flush status
				select($old_select);

				print STDERR "ahoj\n";

				my $tid = $IDLE_QUEUE->dequeue();

				# run thread
				my $readOk = 0;
				share($readOk);
				my @ary : shared = ( \$readOk );
				$work_queues{$tid}->enqueue( \@ary );

				for ( my $f = 0 ; $f < 20 ; $f++ ) {

					if ( $readOk == 1 ) {
						last;
					}
					print STDERR "cyklus $f\n";
					sleep(0.1);
				}

				#
				#				my $replyOk = undef;
				#				my $reply  = undef;
				#
				#
				#
				#				use IO::Handle;
				#use IO::Select;
				#my $nb_stdin = new IO::Select( *STDIN );
				#
				#    			 if($nb_stdin->can_read(10)){
				#
				#    			 	$replyOk = <STDIN>;
				#					$reply = <STDIN>;          # receive from Genesis
				#
				#    			 }
				#
				#				print STDERR "\ntoto je odpoved" . $reply . "\n";
				#
				#				#Helper->PrintServer ("SERVER: PID: $$, port: $serverPort accept new client.................CLIENT PID:". $1."\n");
				#				if ( $replyOk == 0 ) {
				#					send( Client, $$ . "\n", 0 );     # and send it to the client
				#				}
				#				else {
				#					send( Client, 0 . "\n", 0 );      # and send it to the client
				#				}

				if ($readOk) {
					send( Client, $$ . "\n", 0 );    # and send it to the client
				}
				else {
					send( Client, 0 . "\n", 0 );     # and send it to the client
				}
				next;
			}

			# This cmd close connection with client
			# Server is readz to next client again
			if ( $command =~ /CLIENTFINISH/ ) {

				$line =~ m/PID:(\d*)/;

				#Helper->PrintServer ("SERVER: PID: $$, port: $serverPort close client......................CLIENT PID:". $1."\n");

				send( Client, "1\n", 0 );

				last;
			}

			# This exit server script
			if ( $command eq 'CLOSESERVER' ) {

				#Helper->PrintServer ("SERVER: PID: $$, port: $serverPort.......................................was closed\n");
				send( Client, "1\n", 0 );

				exit(0);
			}

			if ( $command eq 'CLOSEDOWN' ) {

				next;

				#exit(0);
			}

			if ( $command eq 'GETENVIRONMENT' ) {
				for $key ( keys %ENV ) {
					$value = $ENV{$key};
					send( Client, "$key=$value\n", 0 );    # and send it to the client
				}
				send( Client, "END\n", 0 );
				next;
			}

			my $DIR_PREFIX = '@%#%@';

			$noReplies    = $replies{$command};
			$old_select   = select(STDOUT);
			$flush_status = $|;                            # save the flushing status\
			$|            = 1;                             # force flushing of the io buffer

			$line =~ s/\@%#%\@//;

			#print STDERR "===============TOTO JDE PRES SERVER: " . $line . " ======\n";

			print $DIR_PREFIX, $line;                      # this goes to Genesis

			$| = $flush_status;                            # restore the original flush status
			select($old_select);

			for $i ( 1 .. $noReplies ) {

				$line = <STDIN>;                           # receive from Genesis

				send( Client, $line, 0 );                  # and send it to the client
			}

		}

	}
}

sub spawn {
	my $coderef = shift;

	unless ( @_ == 0 && $coderef && ref($coderef) eq 'CODE' ) {
		confess "usage: spawn CODEREF";
	}

	my $pid;
	if ( !defined( $pid = fork ) ) {
		logmsg "cannot fork: $!";
		return;
	}
	elsif ($pid) {

		# logmsg "begat $pid";
		return;    # i'm the parent
	}

	# else i'm the child -- go spawn
	exit &$coderef();
}

