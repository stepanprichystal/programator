#!/usr/bin/perl -w
use utf8;
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
use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper' => 'StencilHelper';
use aliased 'Programs::Stencil::StencilCreator::Enums'           => 'StnclEnums';
use aliased 'Packages::InCAM::InCAM';

my $jobId = shift(@_);

unless ( defined $jobId ) {
	$jobId = $ENV{"JOB"};
}

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

my $appName = 'Programs::Stencil::StencilCreator::StencilCreator';    # has to implement IAppLauncher

my $launcher = AppLauncher->new( $appName, $jobId );
$launcher->SetWaitingFrm( "Stencil creator - $jobId", "Loading application ...", Enums->WaitFrm_CLOSEAUTO );

#my $logPath = GeneralHelper->Root() . "\\Packages\\Reorder\\ReorderApp\\Config\\Logger.conf";

#$launcher->SetLogConfig($logPath);

$launcher->Run();

# Check before run app
sub __CheckBeforeRun {
	my $mess = shift;

	my %stencilInfo = StencilHelper->GetStencilInfo($jobId);

	unless ( defined $stencilInfo{"tech"} ) {

		$$mess .= "Nebyl dohledán typ šablony (laserová, leptaná, vrtaná)";
		return 0;
	}

	unless ( defined $stencilInfo{"type"} ) {

		$$mess .= "Nebyl dohledán typ šablony (TOP, BOT, TOP+BOT). Zapište typ do poznámky v IS.";
		return 0;
	}

	my $inCAM   = InCAM->new();
	my @layers  = CamJob->GetAllLayers( $inCAM, $jobId );
	my $saExist = scalar( grep { $_->{"gROWname"} =~ /sa-ori/ } @layers );
	my $sbExist = scalar( grep { $_->{"gROWname"} =~ /sb-ori/ } @layers );

	if ( $stencilInfo{"type"} eq StnclEnums->StencilType_TOP && !$saExist ) {

		$$mess .= "Šablona je typ TOP, ale v metrixhu chybí vrstva sa-ori.";
		return 0;
	}
	elsif ( $stencilInfo{"type"} eq StnclEnums->StencilType_BOT && !$sbExist ) {

		$$mess .= "Šablona je typ BOT, ale v metrixhu chybí vrstva sb-ori.";
		return 0;

	}
	elsif ( $stencilInfo{"type"} eq StnclEnums->StencilType_TOPBOT && ( !$sbExist || !$saExist ) ) {

		$$mess .= "Šablona je typ TOP + BOT. Metrix musí obsahovat vrstvy sa-ori a sb-ori.";
		return 0;
	}
	
	return 1;

}

