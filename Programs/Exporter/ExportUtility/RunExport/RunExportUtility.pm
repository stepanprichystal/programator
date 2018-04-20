
#-------------------------------------------------------------------------------------------#
# Description: This class runs Exporter utility
# First check if some instance is not already running, if not launch exporter
# Author:SPR
#-------------------------------------------------------------------------------------------#


package Programs::Exporter::ExportUtility::RunExport::RunExportUtility;

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
use aliased 'Packages::Other::AppConf';

sub new {
	my $self = shift;
	$self = {};
	bless($self);

	# Tell if scrpt was launched manually by user
	my $userLaunch = shift;

	if(!defined $userLaunch) {
		$userLaunch = 1;
	}
 

	#run exporter
	my $isRuning = Helper->CheckRunningInstance("RunExportUtilityScript.pl");

	if ($isRuning) {

		if ($userLaunch) {

			my $messMngr = MessageMngr->new("Exporter utility");
			my @mess1    = ("Exporter utility is already running, you can't run another.");
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1 );

		}

	}
	else {

 
		$self->__RunExportUtility();

	}
	
	
	 # Run app for checking status of some application
 	$self->__RunAppChecker();
 
	
	return $self;
}
 

sub __RunExportUtility {
	my $self = shift;

	my $processObj;
	my $perl = $Config{perlpath};

	# CREATE_NEW_CONSOLE - script will run in completely new console - no interaction with old console
 

	Win32::Process::Create( $processObj, $perl,
							"perl " . GeneralHelper->Root() . "\\Programs\\Exporter\\ExportUtility\\RunExport\\RunExportUtilityScript.pl ",
							0, NORMAL_PRIORITY_CLASS | CREATE_NEW_CONSOLE, "." )
	  || die "Failed to create ExportUtility process.\n";
 
}


sub __RunAppChecker {
	 my $self = shift;
	 
	my $processObj;
	my $perl = $Config{perlpath};

	# CREATE_NEW_CONSOLE - script will run in completely new console - no interaction with old console
 

	Win32::Process::Create( $processObj, $perl,
							"perl " . GeneralHelper->Root() . "\\Programs\\AppChecker\\RunAppChecker.pl",
							0, NORMAL_PRIORITY_CLASS | CREATE_NEW_CONSOLE, "." )
	  || die "Failed to create ExportUtility process.\n";
 
}	



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportUtility::RunExport::RunExportUtility';

	#my $run = RunExportUtility->new(0);

}

1;
