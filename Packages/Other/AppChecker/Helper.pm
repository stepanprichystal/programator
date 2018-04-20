#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::AppChecker::Helper;

#3th party library
use strict;
use warnings;

use Config;
use Win32::Process;
use Win32::Process::Info;
use Win32::Process::List;


#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
 

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
 
sub CheckRunningInstance {
	my $self       = shift;
	my $scriptName = shift;    # name of running script

	my $pidApp = 0;

	my $procName;
	my $args;
	my $p    = Win32::Process::List->new();
	my $pi   = Win32::Process::Info->new();
	my %list = $p->GetProcesses();

	foreach my $pid ( sort { $a <=> $b } keys %list ) {
		$procName = $list{$pid};

		if ( $procName =~ /^perl.exe/i ) {

			my $procInfo = $pi->GetProcInfo($pid);
			if ( defined $procInfo && scalar( @{$procInfo} ) ) {

				$args = @{$procInfo}[0]->{"CommandLine"};

				if ( defined $args && $args =~ /$scriptName/ ) {

					$pidApp = $pid;
					last;
				}
			}
		}

	}

	return $pidApp;
}
 
 
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Helpers::JobHelper';

	#print JobHelper->GetBaseCuThick("F13608", "v3");

	#print "\n1";
}

1;

