
#-------------------------------------------------------------------------------------------#
# Description: This package run exporter checker
# 1) run single window app as single perl program
# 2) run server.pl from this script
# 3) Export checker will be communicate with this server, after export, this server is killed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::RunExport::RunExportChecker;

#3th party library
#use strict;
use warnings;

#local library

use aliased 'Packages::InCAMHelpers::AppLauncher::AppLauncher';
use aliased 'Packages::InCAMHelpers::AppLauncher::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsIS';

sub new {
	my $self = shift;
	$self = {};
	bless($self);

	# 1) Check job

	my $jobId = $ENV{"JOB"};

	unless ( $self->{"jobId"} ) {

		$self->{"jobId"} = shift;
	}

	unless ( $self->__IsJobOpen( $self->{"jobId"} ) ) {

		return 0;
	}

	# 2) Checks if no pcb reorders are in aktualni_krok = zpracvoani-rucni nebo checkReorder-error
	unless ( $self->__CheckReorder( $self->{"jobId"} ) ) {

		return 0;
	}

	# 3) Launch app

	my $appName = 'Programs::Exporter::ExportChecker::ExportChecker::ExportChecker';    # has to implement IAppLauncher

	my $launcher = AppLauncher->new( $appName, $jobId );

	$launcher->SetWaitingFrm( "Exporter checker - $jobId", "Loading Exporter checker ...", Enums->WaitFrm_CLOSEAUTO );

	my $logPath = GeneralHelper->Root() . "\\Programs\\Exporter\\ExportChecker\\Config\\Logger.conf";

	$launcher->SetLogConfig($logPath);

	$launcher->Run();

}

sub __IsJobOpen {
	my $self  = shift;
	my $jobId = shift;

	unless ($jobId) {

		my $messMngr = MessageMngr->new("Exporter utility");
		my @mess1    = ("You have to run sript in open job.");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );

		return 0;

	}

	return 1;
}

# Checks if no pcb reorders are in aktualni_krok = zpracvoani-rucni nebo checkReorder-error
sub __CheckReorder {
	my $self  = shift;
	my $jobId = shift;

	my $result = 1;

	my @orders = HegMethods->GetPcbReorders($jobId);

	# filter only order zpracovani-rucni or checkReorder-error
	@orders =
	  grep {
		     $_->{"aktualni_krok"} eq EnumsIS->CurStep_ZPRACOVANIMAN
		  || $_->{"aktualni_krok"} eq EnumsIS->CurStep_CHECKREORDERERROR
		  || $_->{"aktualni_krok"} eq EnumsIS->CurStep_PROCESSREORDERERR
	  } @orders;

	if ( scalar(@orders) ) {

		my $messMngr = MessageMngr->new("Exporter utility");

		my @mess1 = (
			"Unable to run \"Exporter checker\":",
"There are re-orders for pcbid \"$jobId\" where \"Aktualni krok\" is one of: \"zpracovani-rucni\", \"checkReorder-error\", \"processReorder-error\" in Helios.",
			"First process job by \"Reorder script\" (Packages\\Reorder\\ReorderApp\\RunReorder\\RunReorderApp.pl)"
		);
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess1 );

		$result = 0;
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = Programs::Exporter::AsyncJobMngr->new();

	#$app->Test();

	#$app->MainLoop;

}
1;
