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

my $appName = 'Programs::Stencil::StencilCreator::StencilCreator';    # has to implement IAppLauncher

my $sourceJob = undef;
my $type = __GetSourceDataType(\$sourceJob);

my $launcher = AppLauncher->new( $appName, $jobId, $type, $sourceJob);
$launcher->SetWaitingFrm( "Stencil creator - $jobId", "Loading application ...", Enums->WaitFrm_CLOSEAUTO );

#my $logPath = GeneralHelper->Root() . "\\Packages\\Reorder\\ReorderApp\\Config\\Logger.conf";

#$launcher->SetLogConfig($logPath);

$launcher->Run();

print STDERR "Stencil creator finish\n";

exit(1);

# Check before run app
sub __CheckBeforeRun {
	my $mess = shift;

	my %stencilInfo = StencilHelper->GetStencilInfo($jobId);

	unless ( defined $stencilInfo{"tech"} ) {

		$$mess .= "Nebyl dohledán typ šablony (laserová, leptaná, vrtaná)";
		return 0;
	}

#	unless ( defined $stencilInfo{"type"} ) {
#
#		$$mess .= "Nebyl dohledán typ šablony (TOP, BOT, TOP+BOT). Zapište typ do poznámky v IS.";
#		return 0;
#	}
	
	my @layers  = CamJob->GetAllLayers( $inCAM, $jobId );
	my $saExist = scalar( grep { $_->{"gROWname"} =~ /sa-(ori|made)/ } @layers );
	my $sbExist = scalar( grep { $_->{"gROWname"} =~ /sb-(ori|made)/ } @layers );

	if ( $stencilInfo{"type"} eq StnclEnums->StencilType_TOP && !$saExist ) {

		$$mess .= "Šablona je typ TOP, ale v metrixu chybí vrstva sa-ori nebo sb-made.";
		return 0;
	}
	elsif ( $stencilInfo{"type"} eq StnclEnums->StencilType_BOT && !$sbExist ) {

		$$mess .= "Šablona je typ BOT, ale v metrixu chybí vrstva sb-ori nebo sb-made.";
		return 0;

	}
	elsif ( $stencilInfo{"type"} eq StnclEnums->StencilType_TOPBOT && ( !$sbExist || !$saExist ) ) {

		$$mess .= "Šablona je typ TOP + BOT. Metrix musí obsahovat vrstvy sa-ori a sb-ori.";
		return 0;
	}
	
	# Check stencil source steps
	my @steps = StencilHelper->GetStencilSourceSteps($inCAM, $jobId);
	my $sourceJob =  scalar(grep {$_ =~ /ori_\w\d+_/} @steps);
	my $sourceCustData =  scalar(grep {$_ =~ /ori_data/} @steps);
	
	if(!$sourceJob && !$sourceCustData){
		
		$$mess .= "V jobu nejsou žádné zdrojové stepy, ze kterých lze vytvořit šablonu.\n";
		$$mess .= "- data z existujícího jobu: \"ori_<jmeno_jobu>_<jmeno_stepu>\".\n";
		$$mess .= "- data od zákazníka: \"ori_data\".\n";
		return 0;
	}
	
	if($sourceJob && $sourceCustData){
		
		$$mess .= "V jobu byly nalezeny zdrojové stepy ze dvou zdrojů (nelze):\n";
		$$mess .= "- data z existujícího jobu: \"ori_<jmeno_jobu>_<jmeno_stepu>\".\n";
		$$mess .= "- data od zákazníka: \"ori_data\".\n";
		return 0;
	}
	
	return 1;

}

sub __GetSourceDataType{
	my $jobName = shift;
	
	my @steps = StencilHelper->GetStencilSourceSteps($inCAM, $jobId);
	my $sourceJob =  scalar(grep {$_ =~ /ori_\w\d+_/} @steps);
	my $sourceCustData =  scalar(grep {$_ =~ /ori_data/} @steps);
	
	if($sourceJob){
		
		($$jobName) = $steps[0] =~ m/ori_(\w\d+)_/i;
		
		return StnclEnums->StencilSource_JOB;
	}else{
		
		return StnclEnums->StencilSource_CUSTDATA;
	}
	
}




