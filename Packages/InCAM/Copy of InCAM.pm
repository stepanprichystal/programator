
=head
Package for running Perl programs in a Genesis/Enterprise environment.

Usage 
    use Genesis; 
    use Genesis('122.12.1.87');
    $f = new Genesis;

    $f->COM($command);

This module enables Genesis/Enterprise scripts in perl. 
It also supports debugging from an xterm, or remote terminal. When running the perl 
script from inside Genesis, simply choose the relevant script from the 
"Script Run" screen. 

To run or debugging a script from an xterm, go the "Script Run" screen, 
and choose the  script called server.pl.  This script sets up a socket which waits
for commands from the perl script to be debugged. 
Having started the script server.pl, open up an xterm and start debugging the script. 

The conventions in the Perl script are slightly different from the csh equivalent.
 
The start of the each perl script must begin with

use Genesis;

To access this library do *one* of the following:
The options appear in the order of recommendation.

* Copy Genesis.pm into the normal Perl library
* Add the path of Genesis.pm to PERL5LIB
* Type "use lib qw(/pathname)" -- where /pathname must be the directory where the file
  Genesis.pm resides -- in each of your genesis scripts.
  The line 'use lib' must appear before the line 'use Genesis'.

The next line should be

    $f = new Genesis;

$f is simply a variable that you can choose.

The public functions are:
   VON, VOF, SU_ON, SU_OFF, PAUSE, MOUSE, COM, AUX, DO_INFO, and INFO

They are invoked in the object oriented way. Here is an example of the PAUSE command 
    $f->PAUSE($text); 

Now let's deal with variables created when using DO_INFO.
Unlike the csh, the variables are put into the the structure
pointed to by $f.

A call to "DOINFO" which reutnrs a value of "gEXISTS" would be referenced as
$f->{doinfo}{gEXISTS}. If an array were to be received, the elements could be referenced as
$f->{doinfo}{gWIDTHS}[$i].

Similary, the return results are called STATUS, READANS, PAUSANS, MOUSEANS and COMANS.
For the meantime these can be read using $f->{STATUS} etc.

BUGS

1. In debug mode: If the Abort button is pressed in Pause, the script does not terminate.

2. Every time an external script is started the Apply button has to be pressed to 
   restart the server side.

3. During debugging of the Perl script the Genesis editor is not updated.

Split into two files & revamped: 3 July 1997, Ben Michelson
Hacked out of all reconition, Peter Gordon
Original Version: 8 Nov 1996,  Herzl Rejwan
=cut

#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAM::InCAM;
@ISA = qw (Exporter);

#3th party library
use Exporter;
use Socket;
use Time::HiRes;

#my library
use aliased 'Packages::InCAM::Helper';
use aliased 'Packages::Exceptions::InCamException';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Global vars
#-------------------------------------------------------------------------------------------#

my $version = '2.0';

my $socketOpen = 0;
my $DIR_PREFIX = '@%#%@';



#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;    # name
	my $remote = shift;
	my $self;

	$remote = 'localhost' unless defined $remote;

	# If standard input is not a terminal then we are a pipe to csh, and hence
	# presumably running under Genesis. In this case use stdin and stdout as is.
	# If, on the other hand, stdin is a tty, then we are running remotely, in which case
	# set up the communications, namely the socket, so that we communicate.

	$self->{remote}            = $remote;
	$self->{port}              = 'genesis';
	$self->{"HandleException"} = 1;
	$self->{"socket"}          = undef;       #socket for debuging
	$self->{"connected"}       = 0;           #say if is library connected to InCAM/Genesis editor
	$self->{"comms"} = "pipe";

	bless $self, $class;

 

	#if (-t STDIN) {

	my $start = Time::HiRes::gettimeofday();

	my $sOpen = $self->openSocket();          #try to connect ro server (debug mode)

	#	if ( -t STDIN ){
	#		print "\n\n\nSOKET OPEN:$sOpen STDIN yes\n\n\n";
	#
	#	}else{
	#		print "\n\n\nSOKET OPEN:$sOpen STDIN no\n\n\n";
	#	}

	if ($sOpen) {
		my $end = Time::HiRes::gettimeofday();

		#printf( "%.2f\n", $end - $start );
		#print "YES";

		$self->{comms}      = 'socket';
		$self->{socketOpen} = 1;
		$self->inheritEnvironment();
		$self->{"connected"} = 1;
	}

	# Test if script run from InCAM (LOGNAME is present)
	elsif ( !( -t STDIN ) && $ENV{"LOGNAME"} ) {

		my $end = Time::HiRes::gettimeofday();

		#printf( "%.2f\n", $end - $start );
		$self->{comms} = 'pipe';
		$self->{"connected"} = 1;

	}
	else {

		runScriptFail();
	}

	binmode(STDOUT);
	return $self;
}

sub DESTROY {

	my $self = shift;
	my $s    = $self->{"socket"};

	if ( $socketOpen == 0 ) {
		return;
	}

	# send(SOCK, "${DIR_PREFIX}CLOSEDOWN \n", 0);
	if ($s) {

		print $s "${DIR_PREFIX}CLOSEDOWN \n";

		close($s) || warn "close: $!";
	}
}

sub closeDown {
	my ($self) = shift;
	$self->sendCommand( "CLOSEDOWN", "" );
}

sub inheritEnvironment {
	my ($self) = shift;
	$self->sendCommand( "GETENVIRONMENT", "" );
	while (1) {
		$reply = $self->getReply();
		if ( $reply eq 'END' ) {
			last;
		}
		( $var, $value ) = split( '=', $reply, 2 );
		$ENV{$var} = $value;
	}

	# And here is a patch for LOCALE. IBM AIX defines LC_MESSAGES and LC__FASTMSG
	# which are not right if you are running remotely
	undef $ENV{LC_MESSAGES};
	undef $ENV{LC__FASTMSG};
}

=head
sub DESTROY { 
    my ($self) = shift;
    $socketOpen -- ; # reduce reference count
    if ($socketOpen) { 
	return ;
    }
    if ($self->{socketOpen}) { 
        $self->closeDown() ;
	close (SOCK) || warn "close: $!";; 
    }
}
=cut

sub openSocket {
	my ($self) = shift;
	my ( $remote, $port, $iaddr, $paddr, $proto );
	$socketOpen++;
	return if $socketOpen != 1;
	$port   = $self->{port};
	$remote = $self->{remote};

	if ( $port =~ /\D/ ) {
		$port = getservbyname( $port, 'tcp' );
	}

	if ( !defined $port ) {
		$port = 56753;

		# The port has not been defined. To define it you need to
		# become root and add the following line in /etc/services
		# genesis     56753/tcp    # Genesis port for debugging perl scripts
	}
	$iaddr = inet_aton($remote) || die "no host: $remote";
	$paddr = sockaddr_in( $port, $iaddr );
	$proto = getprotobyname('tcp');

	#socket(SOCK, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";

	# return connect(SOCK, $paddr);

	use IO::Socket;
	$self->{"socket"} = IO::Socket::INET->new(
											   PeerAddr => "localhost",
											   PeerPort => $port,
											   Type     => SOCK_STREAM,
											   Timeout  => 0.1
	);

	if ( $self->{"socket"} ) {

		return 1;
	}
	else {

		return 0;
	}

}

# remove excess white space
sub removeNewlines {
	my ($command) = shift;
	$command =~ s/\n\s*/ /g;
	return $command;
}

# send the command to be executed
sub sendCommand {
	my ($self)      = shift;
	my $commandType = shift;
	my $command     = shift;

	$self->blankStatusResults();
	if ( $self->{comms} eq 'pipe' ) {
		$self->sendCommandToPipe( $commandType, $command );
	}
	elsif ( $self->{comms} eq 'socket' ) {
		$self->sendCommandToSocket( $commandType, $command );
	}
}

sub sendCommandToPipe {
	my ($self)       = shift;
	my $commandType  = shift;
	my $command      = shift;
	my $old_select   = select(STDOUT);
	my $flush_status = $|;               # save the flushing status
	$| = 1;                              # force flushing of the io buffer
	print $DIR_PREFIX, "$commandType $command\n";
	$| = $flush_status;                  # restore the original flush status
	select($old_select);
}

sub sendCommandToSocket {
	my ($self)      = shift;
	my $commandType = shift;
	my $command     = shift;

	my $s = $self->{"socket"};

	# send(SOCK, "${DIR_PREFIX}$commandType $command\n", 0);
	print $s "${DIR_PREFIX}$commandType $command\n";

	# should check for errors here !!!
}

# wait for the reply
sub getReply {
	my $self = shift;
	my $s    = $self->{"socket"};

	my $reply;
	if ( $self->{comms} eq 'pipe' ) {

		chomp( $reply = <STDIN> );    # chop new line character
	}
	elsif ( $self->{comms} eq 'socket' ) {

		chomp( $reply = <$s> );       # chop new line character
	}
	return $reply;
}

sub runScriptFail {
	print STDERR "You are using InCAM/Genesis library and RUN SCRIPT FAILED:\n";
	print STDERR "- either run script from InCAM/Genesis editor\n";
	print STDERR "- or start script Server.pl in editor for debugging from Eclipse or CMD\n";
	#exit(0);
}

# Checking is on. If a command fails, the script fail
sub VON {
	my ($self) = shift;
	$self->sendCommand( "VON", "" );
}

# Checking is off. If a command fails, the script continues
sub VOF {
	my ($self) = shift;
	$self->sendCommand( "VOF", "" );
}

# Allow Genesis privileged activities. Normally this is executed at the
# start of each script.
sub SU_ON {
	my ($self) = shift;
	$self->sendCommand( "SU_ON", "" );
}

sub SU_OFF {
	my ($self) = shift;
	$self->sendCommand( "SU_OFF", "" );
}

sub blankStatusResults {
	my ($self) = shift;
	undef $self->{STATUS};
	undef $self->{READANS};
	undef $self->{PAUSANS};
	undef $self->{MOUSEANS};
	undef $self->{COMANS};
}

# Wait for a reply from a popup
sub PAUSE {
	my ($self)    = shift;
	my ($command) = @_;
	$self->sendCommand( "PAUSE", removeNewlines($command) );
	$self->{STATUS}  = $self->getReply();
	$self->{READANS} = $self->getReply();
	$self->{PAUSANS} = $self->getReply();
}

# Get the mouse position
sub MOUSE {
	my ($self)    = shift;
	my ($command) = @_;
	$self->sendCommand( "MOUSE", removeNewlines($command) );
	$self->{STATUS}   = $self->getReply();
	$self->{READANS}  = $self->getReply();
	$self->{MOUSEANS} = $self->getReply();
}

# Send a command
sub COM {
	my ($self) = shift;
	

	unless ( $self->{"connected"} ) {
		return;
	}

	$self->{"exception"} = undef;
	my ( $package, $filename, $line ) = caller;

	my $command;
	if ( @_ == 1 ) {
		($command) = @_;
		$self->sendCommand( "COM", removeNewlines($command) );
	}
	else {
		$command = shift;
		my %args = @_;
		foreach ( keys %args ) {
			$command .= ",$_=$args{$_}";
		}
		$self->sendCommand( "COM", $command );
	}
	$self->{STATUS}  = $self->getReply();
	$self->{READANS} = $self->getReply();
	$self->{COMANS}  = $self->{READANS};

	

	if ( $self->{STATUS} > 1 ) {
		
		$self->{"exception"} = InCamException->new( $self->{STATUS}, $filename, $line );
		
		if($self->{"HandleException"} == 0 )
		{
			die $self->{"exception"};
		
		}
	}

	return $self->{STATUS};

}

sub COM_test {
	my ($self) = shift;

	unless ( $self->{"connected"} ) {
		return;
	}

	my ( $package, $filename, $line ) = caller;

	if ( $self->{"HandleException"} == 0 ) {

		#print $trace->as_string();    # like carp

		# from top (most recent) of stack to bottom.
		#while ( my $frame = $trace->next_frame() ) {
		#	print "Has args\n" if $frame->hasargs();
		#}

		# from bottom (least recent) of stack to top.

		die InCamException->new(1009013);
	}

	return $self->{STATUS};

}

# Send an auxiliary command
sub AUX {
	my ($self) = shift;

	unless ( $self->{"connected"} ) {
		return;
	}

	my $command;
	if ( @_ == 1 ) {
		($command) = @_;
		$self->sendCommand( "AUX", removeNewlines($command) );
	}
	else {
		$command = shift;
		my %args = @_;
		foreach ( keys %args ) {
			$command .= ",$_=$args{$_}";
		}
		$self->sendCommand( "AUX", $command );
	}
	$self->{STATUS}  = $self->getReply();
	$self->{READANS} = $self->getReply();
	$self->{COMANS}  = $self->{READANS};
}

# Get some basic info
# It is received in the form of a csh script, so the information needs
# hacking to get into a form suitable for perl

sub DO_INFO {
	my ($self) = shift;

	unless ( $self->{"connected"} ) {
		return;
	}

	my $info_pre = "info,out_file=\$csh_file,write_mode=replace,args=";
	my $info_com = "$info_pre @_ -m SCRIPT";
	$self->parse($info_com);
}

#hen InCAM error happens during COM function:
#- if  HandleException = 0, InCAMException raise
#- if  HandleException = 1, COM function return error code and script continue
sub HandleException {
	my $self  = shift;
	my $value = shift;

	$self->{"HandleException"} = $value;

}

sub parse {
	my ($self)    = shift;
	my ($request) = shift;
	my $csh_file  = "$ENV{GENESIS_DIR}/tmp/info_csh.$$";
	$request =~ s/\$csh_file/$csh_file/;
	$self->COM($request);

	open( CSH_FILE, "$csh_file" )
	  or warn "Cannot open info file - $csh_file: $!\n";
	while (<CSH_FILE>) {
		chomp;
		next if /^\s*$/;    # ignore blank lines
		( $var, $value ) = /set\s+(\S+)\s*=\s*(.*)\s*/;    # extract the name and value

		$value =~ s/^\s*|\s*$//g;                          # remove leading and trailing spaces from the value
		$value =~ s/\cM/<^M>/g;                            # change ^M temporarily to something else
		                                                   # This happens mainly in giSEP, and shellwords makes it disappear

		@value = shellwords($_);

		# Deal with an csh array differently from a csh scalar
		if ( $value =~ /^\(/ ) {
			$value =~ s/^\(|\)$//g;                        # remove leading and trailing () from the value
			@words = shellwords($value);                   # This is a standard part of the Perl library
			grep { s/\Q<^M>/\cM/g } @words;
			$self->{doinfo}{$var} = [@words];
			$self->{$var} = [@words];
		}
		else {
			$value =~ s/\Q<^M>/\cM/g;
			$value =~ s/^'|'$//g;

			$self->{doinfo}{$var} = $value;
			$self->{$var} = $value;
		}
	}
	close(CSH_FILE);
	unlink($csh_file);
}

sub INFO {
	my ($self) = shift;

	unless ( $self->{"connected"} )
	{
		return;
	}

	my %args = @_;
	my ( $entity_path, $data_type, $parameters, $serial_number, $options, $help, $entity_type ) = ( "", "", "", "", "", "", "" );
	my $i;
	my $units = 'units = inch';
	my $parse = 'yes';

	foreach ( keys %args ) {
		$i = $args{$_};
		if ( $_ eq "entity_type" ) {
			$entity_type = "-t $i";
		}
		elsif ( $_ eq "entity_path" ) {
			$entity_path = "-e $i";
		}
		elsif ( $_ eq "data_type" ) {
			$data_type = "-d $i";
		}
		elsif ( $_ eq "parameters" ) {
			$parameters = "-p $i";
		}
		elsif ( $_ eq "serial_number" ) {
			$serial_number = "-s $i";
		}
		elsif ( $_ eq "options" ) {
			$options = "-o $i";
		}
		elsif ( $_ eq "help" ) {
			$help = "-help";
		}
		elsif ( $_ eq "units" ) {
			$units = "units= $i";
		}
		elsif ( $_ eq "parse" ) {
			$parse = $i;
		}
	}
	my $info_pre = "info,out_file=\$csh_file,write_mode=replace,$units,args=";
	my $info_com = "$info_pre $entity_type $entity_path $data_type " . "$parameters $serial_number $options $help";
	if ( $parse eq 'yes' ) {
		$self->parse($info_com);
	}
	else {
		my $csh_file = "$ENV{GENESIS_DIR}/tmp/info_csh.$$";
		$info_com =~ s/\$csh_file/$csh_file/;
		$self->COM($info_com);
		return $csh_file;
	}
}

=item printFile($file);

=cut

sub printFile {
	my ($self)     = shift;
	my ($filename) = shift;

	open( FILE, "$filename" ) or warn "can not open file $filename";
	while (<FILE>) {
		print;
	}
	close(FILE);
}

=item $float = round($value,$precision)

=cut

sub round {
	my ($self)      = shift;
	my ($value)     = shift;
	my ($precision) = shift;

	$precision = 0.05 unless defined $precision;
	if ( $precision == 0 ) {
		return $value;
	}
	return int( $value / $precision + 1 ) * $precision;
}

#
sub shellwords {

	#package shellwords;
	my ($_) = join( '', @_ ) if @_;
	my ( @words, $snippet, $field );

	s/^\s+//;
	while ( $_ ne '' ) {
		$field = '';
		for ( ; ; ) {
			if (s/^"(([^"\\]|\\[\\"])*)"//) {
				( $snippet = $1 ) =~ s#\\(.)#$1#g;
			}
			elsif (/^"/) {
				die "Unmatched double quote: $_\n";
			}
			elsif (s/^'(([^'\\]|\\[\\'])*)'//) {
				( $snippet = $1 ) =~ s#\\(.)#$1#g;
			}
			elsif (/^'/) {
				die "Unmatched single quote: $_\n";
			}
			elsif (s/^\\(.)//) {
				$snippet = $1;
			}
			elsif (s/^([^\s\\'"]+)//) {
				$snippet = $1;
			}
			else {
				s/^\s+//;
				last;
			}
			$field .= $snippet;
		}
		push( @words, $field );
	}
	@words;
}

1;
