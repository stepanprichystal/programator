#! /sw/bin/perl

=head
Set up a socket so that a remote user can send commands
Most of this has been copied from the Perl manual.
=cut

use Socket;
use Carp;

sub spawn;    # forward declaration
sub logmsg { print "$0 $$: @_ at ", scalar localtime, "\n" }

if ( $ARGV[0] eq 1 ) {
	$dontStop = 1;
}

#my $port = '56754';    # 56753;
my $port = 'genesis';    # 56753;
if ( $port =~ /\D/ ) {
	$port = getservbyname( $port, 'tcp' );
}
if ( !defined $port ) {
	$port = 56753;

	# The port has not been defined. To define it you need to
	# become root and add the following line in /etc/services
	# genesis     56753/tcp    # Genesis port for debugging perl scripts
}

die "No port" unless $port;
my $proto = getprotobyname('tcp');
socket( Server, PF_INET, SOCK_STREAM, $proto ) || die "socket: $!";
setsockopt( Server, SOL_SOCKET, SO_REUSEADDR, pack( "l", 1 ) ) || die "setsockopt: $!";
bind( Server, sockaddr_in( $port, INADDR_ANY ) ) || die "bind: $!";
listen( Server, SOMAXCONN ) || die "listen: $!";

my $waitedpid = 0;
my $paddr;

sub REAPER {
	$SIG{CHLD} = \&REAPER;    # loathe sysV
	$waitedpid = wait;

	# On the first successful reap, close down
	logmsg "reaped $waitedpid" . ( ($?) ? " with exit $?" : '' );
	if ( !defined $dontStop ) {
		exit(0);              # this is important. It ensures that everything closes down nicely
		                      # when the script finishes
	}
}

$SIG{CHLD} = \&REAPER;

for ( $waitedpid = 0 ; ( $paddr = accept( Client, Server ) ) || $waitedpid ; $waitedpid = 0, close Client ) {
	next if $waitedpid;
	my ( $port, $iaddr ) = sockaddr_in($paddr);
	my $name = gethostbyaddr( $iaddr, AF_INET );

	#logmsg "connection from $name [",inet_ntoa($iaddr), "]	at port $port";

	%replies = ( PAUSE => 3, MOUSE => 3, COM => 2, AUX => 2 );
	$DIR_PREFIX = '@%#%@';
	while ( $line = <Client> ) {
		( $text = $line ) =~ s/\@%#%\@//;

		#print "GOT A LINE $text\n" ;

		if ( ($command) = $line =~ /^\@%#%\@\s*(\S+)/ ) {
			if ( $command eq 'CLOSEDOWN' ) {

				# kill 9, getppid() ; # kill father
				# kill 9, $$ ; # kill myself
				exit(0);
			}
			if ( $command eq 'GETENVIRONMENT' ) {
				for $key ( keys %ENV ) {
					$value = $ENV{$key};
					send( Client, "$key=$value\n", 0 );    # and send it to the client
				}
				send( Client, "END\n", 0 );
				next;
			}
			$noReplies    = $replies{$command};
			$old_select   = select(STDOUT);
			$flush_status = $|;                            # save the flushing status
			$|            = 1;                             # force flushing of the io buffer
			print $line ;                                  # this goes to Genesis
			$| = $flush_status;                            # restore the original flush status
			select($old_select);
		}
		for $i ( 1 .. $noReplies ) {
			$line = <STDIN>;                               # receive from Genesis
			send( Client, $line, 0 );                      # and send it to the client
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
