#-------------------------------------------------------------------------------------------#
# Description: Close zombified InCAM server running on specific port or port range
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use strict;
use warnings;
use Win32::Process;
use Win32::Process::Info;
use Win32::Process::List;
use Getopt::Std;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#use local library;
use aliased 'Managers::AsyncJobMngr::Helper';

my %options = ();
getopts( "i:r:", \%options );

my $port      = $options{"i"};
my $portRange = $options{"r"};

my $portFrom = undef;
my $portTo   = undef;

if ( $port eq "-" ) {

	( $portFrom, $portTo ) = $portRange =~ m/(\d+)-(\d+)/;
	$port = undef;
	print STDERR "\n\nPort is not specified, kill all\n";
}
else {

	$portFrom = $port;
	$portTo   = $port;
}

my $args;
my $name;

my $p = Win32::Process::List->new();

my $pi   = Win32::Process::Info->new();
my %list = $p->GetProcesses();

foreach my $pid ( sort { $a <=> $b } keys %list ) {
	$name = $list{$pid};

	if ( $name =~ /^perl.exe/i || $name =~ /^InCAM.exe/i ) {

		my $procInfo = $pi->GetProcInfo($pid);
		if ( defined $procInfo && scalar( @{$procInfo} ) ) {

			$args = @{$procInfo}[0]->{"CommandLine"};    # Get the max

			if ( defined $args && $args =~ /ServerAsyncJob/ ) {
 
				$args =~ m/pl\s(\d+)/;

				if ( $1 >= $portFrom && $1 <= $portTo ) {
					
					Win32::Process::KillProcess( $pid, 0 );
					Helper->Print( "ZOMBIE: NAME: $name PID: " . $pid . " PORT: $1 ....................................was killed. Path $args \n" );
				}

			}
		}
	}

}

