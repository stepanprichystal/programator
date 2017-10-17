#!/usr/bin/perl -w

use strict;
use warnings;
use Win32::Process;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsIS';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::InCAMHelpers::AppLauncher::AppLauncher';
use aliased 'Packages::InCAMHelpers::AppLauncher::Enums';
use aliased 'Helpers::GeneralHelper';

my $jobId = $ENV{"JOB"};

# 1) Check before run
unless(__CheckBeforeRun()){
	
	#exit(0);
}


# 2) Launch app

my $appName = 'Programs::StencilCreator::StencilCreator';    # has to implement IAppLauncher

my $launcher = AppLauncher->new( $appName, $jobId );
$launcher->SetWaitingFrm( "Stencil creator - $jobId", "Loading application ...", Enums->WaitFrm_CLOSEAUTO );

#my $logPath = GeneralHelper->Root() . "\\Packages\\Reorder\\ReorderApp\\Config\\Logger.conf";

#$launcher->SetLogConfig($logPath);

$launcher->Run();

# Check before run app
sub __CheckBeforeRun {

#	my $messMngr = MessageMngr->new($jobId);
#
#	# 1) Check if run in open job
#	if ( !defined $jobId || $jobId eq "" ) {
#
#		my @mess1 = ("Run script in editor with open job!\n");
#		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess1 );
#
#		return 0;
#	}
#
#	# 2) Check if exist order in step "zpracovani-rucni"
#
#	my @orders = HegMethods->GetPcbReorders($jobId);
#
#	# filter only order zpracovani-rucni or checkReorder-error
#	@orders =
#	  grep { $_->{"aktualni_krok"} eq EnumsIS->CurStep_ZPRACOVANIMAN ||
#	  	$_->{"aktualni_krok"} eq EnumsIS->CurStep_PROCESSREORDERERR ||
#	  	 $_->{"aktualni_krok"} eq EnumsIS->CurStep_CHECKREORDERERROR } @orders;
#
#	unless ( scalar(@orders) ) {
#		my @mess1 = ("Run \"Reorder application\" is not possible:", "No re-orders in Helios for pcbid \"$jobId\" where \"Aktualni krok\" is one of: \"zpracovani-rucni\", \"checkReorder-error\", \"processReorder-error\".");
#		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess1 );
#
#		return 0;
#	}

}

