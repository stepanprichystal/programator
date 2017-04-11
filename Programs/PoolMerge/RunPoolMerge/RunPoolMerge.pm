
#-------------------------------------------------------------------------------------------#
# Description: This class runs Exporter utility
# First check if some instance is not already running, if not launch pool merger
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::RunPoolMerge::RunPoolMerge;

#3th party library
use strict;
use warnings;
use Config;
use Win32::Process;
use Win32::Process::Info;
use Win32::Process::List;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Managers::AbstractQueue::Helper';

sub new {
	my $self = shift;
	$self = {};
	bless($self);

	# Tell if scrpt was launched manually by user
	my $userLaunch = shift;

	if(!defined $userLaunch) {
		$userLaunch = 1;
	}

	#run pool merger
	my $isRuning = Helper->CheckRunningInstance("RunPoolMerge.pl");

	if ($isRuning) {

		if ($userLaunch) {

			my $messMngr = MessageMngr->new("Pool merger");
			my @mess1    = ("Pool merger is already running, you can't run another.");
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1 );

		}

	}
	else {

 
		Helper->__RunPoolMerge();

	}
 
	
	return $self;
}
 

sub __RunPoolMerge {
	my $self = shift;

	my $processObj;
	my $perl = $Config{perlpath};

	# CREATE_NEW_CONSOLE - script will run in completely new console - no interaction with old console
 

	Win32::Process::Create( $processObj, $perl,
							"perl " . GeneralHelper->Root() . "\\Programs\\PoolMerge\\RunPoolMerge\\RunPoolMergeScript.pl ",
							0, NORMAL_PRIORITY_CLASS | CREATE_NEW_CONSOLE, "." )
	  || die "Failed to create PoolMerge process.\n";

	


}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::PoolMerge::RunPoolMerge::RunPoolMerge';

	#my $run = RunPoolMerge->new(0);

}

1;
