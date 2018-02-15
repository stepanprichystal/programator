#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

#local library

use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::InCAM::InCAM';

my $jobId = shift;

my $inCAM = InCAM->new();

my $messMngr = MessageMngr->new("test");


 

# 1) Test jestli job existuje
my @jobList = CamJob->GetJobList($inCAM);

unless ( scalar( grep { $_ =~ /^$jobId$/i } @jobList ) ) {

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Job neexistuje, naimportuj ho!"] );    #  Script se zastavi
}

# 2) Test jestli se zavrel
if ( CamJob->IsJobOpen( $inCAM, $jobId ) ) {

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Job je stale otevreny. Zavri otevri a zavri job znovu!"] );
}
else {

	if ( CamJob->IsJobOpen( $inCAM, $jobId, 1 ) ) {

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Job je stale otevreny. Zavri otevri a zavri job znovu!"] );
	}
}

