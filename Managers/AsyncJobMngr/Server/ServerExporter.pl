#! /sw/bin/perl

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

 

=head
Set up a socket so that a remote user can send commands
Most of this has been copied from the Perl manual.
=cut

#use local library;
use aliased 'Managers::AsyncJobMngr::Helper';

use Socket;
use Carp;
use Sys::Hostname;

sub spawn;    # forward declaration
sub logmsg { print "$0 $$: @_ at ", scalar localtime, "\n" }

my $hostName = hostname;
my $hostIpAddr = inet_ntoa( ( gethostbyname(hostname) )[4] );

my $defaultPort = 56753;

#get information about port
my $serverPort;
my $arg = $ARGV[0];

if ( defined $arg && $arg =~ /\d/ ) {
	$serverPort = $arg;
}
else {
	$serverPort = $defaultPort;    # 56753;
}

#if ( $port =~ /\D/ ) {
#	$port = getservbyname( $port, 'tcp' );

#	print STDERR "\n PORT OF SERVER: 4  ".$arg;
#}

# The port has not been defined. To define it you need to
# become root and add the following line in /etc/services
# genesis     56753/tcp    # Genesis port for debugging perl scripts

#print STDERR "\n";

die "No port" unless $serverPort;
my $proto = getprotobyname('tcp');
socket( Server, PF_INET, SOCK_STREAM, $proto ) || die "socket: $!";
setsockopt( Server, SOL_SOCKET, SO_REUSEADDR, pack( "l", 1 ) ) || die "setsockopt: $!";
bind( Server, sockaddr_in( $serverPort, INADDR_ANY ) ) || die "bind: $!";
listen( Server, SOMAXCONN ) || die "listen: $!";

my $waitedpid = 0;
my $paddr;

sub REAPER {
	$SIG{CHLD} = \&REAPER;    # loathe sysV
	$waitedpid = wait;

	# On the first successful reap, close down
	logmsg "reaped $waitedpid" . ( ($?) ? " with exit $?" : '' );

	#if ( !defined $dontStop ) {
	#	exit(0);              # this is important. It ensures that everything closes down nicely
	# when the script finishes
	#}
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

			#print "===============$command\n";
			if ( $command =~ /SERVERREADY/ ) {
				$line =~ m/PID:(\d*)/;

				#Helper->PrintServer ("SERVER: PID: $$, port: $serverPort accept new client.................CLIENT PID:". $1."\n");

				send( Client, $$ . "\n", 0 );    # and send it to the client

				next;
			}

			if ( $command =~ /CLIENTFINISH/ ) {

				$line =~ m/PID:(\d*)/;

				#Helper->PrintServer ("SERVER: PID: $$, port: $serverPort close client......................CLIENT PID:". $1."\n");

				send( Client, "1\n", 0 );

				last;
			}

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

			#			my $old_select   = select(STDOUT);
			#			my $flush_status = $|;               # save the flushing status
			#			$| = 1;                              # force flushing of the io buffer
			#			print $DIR_PREFIX, "$commandType $command\n";
			#			$| = $flush_status;                  # restore the original flush status
			#			select($old_select);

		}

		for $i ( 1 .. $noReplies ) {

			$line = <STDIN>;    # receive from Genesis

			send( Client, $line, 0 );    # and send it to the client
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

