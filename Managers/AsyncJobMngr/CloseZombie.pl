#-------------------------------------------------------------------------------------------#
# Description: Close zombified InCAM server running on specific port
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
getopts( "i:n:", \%options );

my $port       = $options{"i"};
my $scriptName = $options{"n"};    # name of script which use AsyncJobMngr. We need this name for killing zombie perl and incam

if ($port eq "-") {
	$port = undef;
	print STDERR "\n\nPort is not specified, kill all\n";
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

			if ( defined $args && $args =~ /ServerAsyncJob/ && $args =~ /$scriptName/ ) {

				print STDERR "CLOSE ZOMBIE: $args $port\n";

				$args =~ m/pl\s(\d+)/;

				if ( defined $port ) {
					if ( $1 == $port ) {
						Win32::Process::KillProcess( $pid, 0 );
						Helper->Print( "ZOMBIE: NAME: $name PID: " . $pid . ", port:" . $port . "....................................was killed\n" );
					}
				}
				else {

					Win32::Process::KillProcess( $pid, 0 );
					Helper->Print( "ZOMBIE: NAME: $name PID: " . $pid .  "....................................was killed\n" );
				}

			}
		}
	}

}

