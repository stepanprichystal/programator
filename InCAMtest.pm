#! /sw/bin/perl


use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use aliased 'CamHelpers::CamHelper';



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
package InCAMtest;
@ISA = qw (Exporter);

#3th party library
use Exporter;

#my library
use aliased 'Packages::InCAM::Helper';
use aliased 'Packages::Exceptions::InCamException';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Global vars
#-------------------------------------------------------------------------------------------#

my $version = '2.0';

#my $socketOpen = 0;
my $DIR_PREFIX = '@%#%@';
my $defaultPort = 56753;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;    # name
	my $remote = shift;
	my $port = shift;
	my $self;

#	$remote = 'localhost' unless defined $remote;

#	# If standard input is not a terminal then we are a pipe to csh, and hence
#	# presumably running under Genesis. In this case use stdin and stdout as is.
#	# If, on the other hand, stdin is a tty, then we are running remotely, in which case
#	# set up the communications, namely the socket, so that we communicate.
#
#	$self->{"remote"}            = $remote;
#	$self->{"HandleException"} = 1;
#	$self->{"socket"}          = undef;       #socket for debuging
#	$self->{"socketOpen"} = 0;
#	$self->{"connected"}       = 0;           #say if is library connected to InCAM/Genesis editor
#	$self->{"comms"}           = "pipe";
#	my @cmds = ();
#	$self->{"cmdHistory"}           = \@cmds;
	
	if($port){
		$self->{"port"}              = $port;
	}else{
		$self->{"port"}              = $defaultPort; #default port number
	}
 
		# The port has not been defined. To define it you need to
		# become root and add the following line in /etc/services
		# genesis     56753/tcp    # Genesis port for debugging perl scripts
	 

	bless $self, $class;

	undef $ENV{LC_MESSAGES};
	undef $ENV{LC__FASTMSG};
 
	return $self;
}




sub sendCommandToPipe {
	my ($self)       = shift;
	my $commandType  = shift;
	my $command      = shift;

	
	my $old_select   = select(STDOUT);
	my $flush_status = $|;               # save the flushing status
	$| = 1;                              # force flushing of the io buffer
	
	print STDERR "\n\n//////////////////////////////////////////////////TOTO JDE PRES KNIHOVNU: "."$commandType $command\n"." ///////////////// \n\n";
	
	print $DIR_PREFIX, "$commandType $command\n";
	$| = $flush_status;                  # restore the original flush status
	select($old_select);
}




#TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT


my $inCAM = InCAMtest->new();
my $jobName    = "F13608";
	my $stepName = "panel";
	my $machine = "machine_b";
	my $tempLayer = "ca_tmp";
	 
	
	$inCAM->sendCommandToPipe("COM", "clipb_open_job,update_clipboard=view_job,job=F13608");
	$inCAM->sendCommandToPipe("COM", "open_job,open_win=yes,job=F13608");
	$inCAM->sendCommandToPipe("COM", "nc_cre_output,layer=ca_tmp,ncset=test");
	

	sleep(1);
 


1;
