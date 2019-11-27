#!/usr/bin/perl-w
#################################

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';

use aliased 'Widgets::Forms::SimpleInput::SimpleInputFrm';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Managers::MessageMngr::MessageMngr';

my $inCAM = InCAM->new();

#  tolik mezer tam je schvalne, protoze se tim logicky zvetsi policko pro zadavani jobu

my $ACTIONTYPE_OPENCHECKOUT = "Open job + check out                        "; 
my $ACTIONTYPE_OPENCHECKIN  = "Open job + check in";
my $ACTIONTYPE_NOACTION     = "No action";

my $messMngr = MessageMngr->new("");

my @mess = ("JOB UNARCHIVE + CHECK IN");

my $jobPar = $messMngr->GetTextParameter( "Put jobs separated by \";\" ", "" );
my @option = ( $ACTIONTYPE_OPENCHECKOUT, $ACTIONTYPE_OPENCHECKIN, $ACTIONTYPE_NOACTION );
my $actionTypePar = $messMngr->GetOptionParameter( "Set action after unarchive", $option[0], \@option );
my $firstOnlyPar = $messMngr->GetCheckParameter( "Do action for first job only", 1 );

my @params = ( $jobPar, $actionTypePar, $firstOnlyPar );

$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, undef, undef, \@params );

my @jobList = split /;/, $jobPar->GetResultValue(1);

for ( my $i = 0 ; $i < scalar(@jobList) ; $i++ ) {

	my $job = $jobList[$i];
	if ( $job =~ /[FfDd]\d{5,}/ ) {
		$job = lc $job;

		# 1) Acquire job

		my $result = _AcquireNew( $inCAM, $job );

		CamJob->CheckInJob( $inCAM, $job );

		next if ( $firstOnlyPar->GetResultValue(1) == 1 && $i > 0 );

		# 2) Do action

		if ( $actionTypePar->GetResultValue(1) eq $ACTIONTYPE_OPENCHECKOUT || $actionTypePar->GetResultValue(1) eq $ACTIONTYPE_OPENCHECKIN ) {
			$inCAM->COM( "open_job", "job" => $job, "open_win" => "yes" );
			$inCAM->COM( "set_subsystem", "name" => "1-Up-Edit" );
			$inCAM->COM( "set_step",      "name" => "o+1" );
 
			CamJob->CheckOutJob( $inCAM, $job ) if ( $actionTypePar->GetResultValue(1) eq $ACTIONTYPE_OPENCHECKOUT );

		}
	}
}

sub _AcquireNew {
	my $inCAM = shift;
	my $jobId = shift;

	if ( $jobId =~ /^[df]\d{5}$/i ) {

		$jobId = JobHelper->ConvertJobIdOld2New($jobId);
	}

	# Supress all toolkit exception/error windows
	$inCAM->SupressToolkitException(1);
	my $result = AcquireJob->Acquire( $inCAM, $jobId );
	$inCAM->SupressToolkitException(0);

	return $result;
}
