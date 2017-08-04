#!/usr/bin/perl -w

use strict;
use warnings;
use Win32::Process;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Packages::Reorder::ReorderApp::ReorderApp';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsIS';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';

my $inCAM = InCAM->new();
my $jobId = $ENV{"JOB"};
 
eval {

	if(!defined $jobId || $jobId eq "") {
	 	die "Run script in editor with open job!\n";
	 }

	# 1) Check if exist order in step "zpracovani-rucni"
	 my @orders = HegMethods->GetPcbReorders($jobId);
	 @orders = grep { $_->{"aktualni_krok"} eq EnumsIS->CurStep_ZPRACOVANIMAN } @orders;    # filter only order zpracovani-rucni
	 unless(scalar(@orders)){
	 	die "No reorders for pcbid: $jobId where \"Aktualni krok\" = \"zpracovani-rucni\"!\n";
	 }

	# 2) Check if job is open
	unless(CamJob->IsJobOpen($inCAM, $jobId)){
		die "Job $jobId is not open";
	}
 

	my $form = ReorderApp->new( $inCAM, $jobId);

};
if ($@) {

	my $messMngr = MessageMngr->new($jobId);

	my @mess1 = ( "Reorder app fail:  " . $@ . "\n" );
	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@mess1 );
 
}

