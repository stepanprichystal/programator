
#-------------------------------------------------------------------------------------------#
# Description: Helper for InCAMCall class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::InCAMServer::Server::Helper;

#3th party library
use strict;
use Log::Log4perl qw(get_logger :levels);
use Win32::Process;
use Config;
use Win32::Console;
use Win32::GuiTest qw(FindWindowLike SetWindowPos ShowWindow);
use Getopt::Std;

#use Win32::Console;

#use Try::Tiny;
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
#
sub HideConsole {
	my $self = shift;

	my $console = Win32::Console->new;
	$console->Title("InCAM server script");

	my @windows = FindWindowLike( 0, "InCAM server script" );
	for (@windows) {
		ShowWindow( $_, 0 );
	}

	return 0;
}

# if another app is running, exit
# Protection against run more than one instance of running server
sub CheckRunningApp {
	my $self = shift;

	my $script = GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\InCAMServer\\Server\\HelperScripts\\CheckInstances.pl";
	my @cmds   = ( );

	my $call = SystemCall->new( $script, \@cmds );
	my $result = $call->Run();
	my %resultHash = $call->GetOutput();
  
	my $cnt = $resultHash{"runInstanceCnt"};

	# if another app with name
	if ( $cnt > 1 ) {

		print STDERR "Attempt to run another instance of InCAMServerScript.pl. Actual cnt of instances: $cnt";
		
		sleep(2);
		exit(0);

	}

}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::InCAMHelpers::InCAMServer::Server::Helper';
	
	Helper->CheckRunningApp();

}

1;

