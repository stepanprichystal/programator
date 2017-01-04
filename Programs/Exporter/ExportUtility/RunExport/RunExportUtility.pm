
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
	my $isRuning = $self->__CheckRunningInstance();

	if ($isRuning) {

		if ($userLaunch) {

			my $messMngr = MessageMngr->new("Exporter utility");
			my @mess1    = ("Exporter utility is already running, you can't run another.");
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1 );

		}

	}
	else {

		#run exporter
		$self->__RunExportUtility();

	}
 
	
	return $self;
}

sub __CheckRunningInstance {
	my $self = shift;

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

				if ( defined $args && $args =~ /RunExportUtilityScript.pl/ ) {

					$exist = 1;
					last;
				}
			}
		}

	}

	return $exist;
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
