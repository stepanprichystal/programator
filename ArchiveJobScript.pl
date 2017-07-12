#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamDrilling';

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Services::TpvService::ServiceApps::ArchiveJobsApp::ArchiveJobsApp' => "App";
 
 

my $jobId = shift;

unless(defined $jobId){
	
	die "V parametrech nebyl zadan job\n";
}

my $app = App->new();

my $inCAM    = InCAM->new();

$inCAM->SupressToolkitException(1);

$app->{"inCAM"} = $inCAM;

$app->__RunJob($jobId);

print "Job archived";