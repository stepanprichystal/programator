#!/usr/bin/perl -w
use utf8;
use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::InCAMHelpers::AppLauncher::AppLauncher';
use aliased 'Packages::InCAMHelpers::AppLauncher::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::InCAM::InCAM';

my $jobId = shift;

unless ( defined $jobId ) {
	$jobId = $ENV{"JOB"};
}

my $inCAM   = InCAM->new();


#$jobId ="f13610";

# 1) Check before run
my $mess = "";
unless ( __CheckBeforeRun( \$mess ) ) {

	my $messMngr = MessageMngr->new($jobId);

	my @mess1 = ($mess);
	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess1 );

	exit(0);
}

# 2) Launch app

my $appName = 'Programs::Comments::CommWizard';    # has to implement IAppLauncher

 
my $launcher = AppLauncher->new( $appName, $jobId);
$launcher->SetWaitingFrm( "Comments builder - $jobId", "Loading application ...", Enums->WaitFrm_CLOSEAUTO );



$launcher->Run();

print STDERR "Stencil creator finish\n";

exit(1);

# Check before run app
sub __CheckBeforeRun {
	my $mess = shift;
	
	return 1;
}




