
#3th party library
use strict;
use warnings;
use Config;
use Win32::Process;
use Win32::Process::Info;
use Win32::Process::List;

#local library

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;
 

use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Managers::AbstractQueue::Helper';
use aliased 'Packages::Other::AppConf';

#run exporter
my $isRuning = Helper->CheckRunningInstance("RunChangePcbStatusScript.pl");

if ($isRuning) {

	my $messMngr = MessageMngr->new("Change pcb status");
	my @mess1    = ("\"Change pcb status\" is already running, you can't run another.");
	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1 );

}
else {

	 __Run();

}

sub __Run {

	my $processObj;
	my $perl = $Config{perlpath};

	# CREATE_NEW_CONSOLE - script will run in completely new console - no interaction with old console

	Win32::Process::Create( $processObj, $perl, "perl " . GeneralHelper->Root() . "\\HelperScripts\\ChangePcbStatus\\RunChangePcbStatusScript.pl ",
							0, NORMAL_PRIORITY_CLASS | CREATE_NO_WINDOW, "." )
	  || die "Failed to create RunChangePcbStatusScript process.\n";

}

