#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::Helper;

#3th party library
use strict;
use warnings;
use Win32::GuiTest qw(FindWindowLike SetWindowPos ShowWindow);

use Config;
use Win32::Process;
use Win32::Process::Info;
use Win32::Process::List;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Managers::AbstractQueue::AppConf';


#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return base cu thick by layer
sub ShowAbstractQueueWindow {
	my $self  = shift;
	my $show  = shift;
	my $title = shift;

	my @windows = FindWindowLike( 0, $title );
	for (@windows) {

		ShowWindow( $_, $show );

		return 1;
	}

	return 0;
}

sub CheckRunningInstance {
	my $self       = shift;
	my $scriptName = shift;    # name of running script

	my $exist = 0;

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

					$exist = 1;
					last;
				}
			}
		}

	}

	return $exist;
}

sub Logging {
	my $self = shift;
	my $dir = shift;
	my $fileName = shift;

	my $appName = AppConf->GetValue("appName");
	$appName =~ s/\s//g;
	my $path = EnumsPaths->Client_INCAMTMPJOBMNGR.$appName."Logs";
	
	if($dir){
		$path .= "\\$dir";
	}
 	
 	unless($fileName){
 		$fileName = "Log";
 	}
 	
 	unless ( -e $path ) {
		die "Logging directory $path doesn't exist";
	}
 	
 	$path = $path."\\".$fileName;
 	
	my $OLDOUT;
	my $OLDERR;
	
	open $OLDOUT, ">&STDOUT" || die "Can't duplicate STDOUT: $!";
	open $OLDERR, ">&STDERR" || die "Can't duplicate STDERR: $!";
	open( STDOUT, "+>", $path );
	open( STDERR, ">&STDOUT" );

}






sub CreateDirs{
	my $self = shift;
 
	my $appName = AppConf->GetValue("appName");
	
	$appName =~ s/\s//g;
	
	my $dir = EnumsPaths->Client_INCAMTMPJOBMNGR.$appName."Logs";
	
	unless ( -e $dir ) {
		mkdir( $dir ) or die "Can't create dir: " . $dir . $_;
	}
#	
#	unless ( -e $dir."\\ServerThreads" ) {
#		mkdir(  $dir."\\ServerThreads" ) or die "Can't create dir: " . $dir."\\ServerThreads" . $_;
#	}
#	
#	unless ( -e $dir."\\TaskThreads" ) {
#		mkdir(  $dir."\\TaskThreads" ) or die "Can't create dir: " . $dir."\\TaskThreads" . $_;
#	}
#	
	 
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

