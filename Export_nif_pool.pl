#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use utf8;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packagesff
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmpPool';



#input parameters
 

 
my $jobId    = "d235328";
 

 
 
my $poznamka = "";
my $tenting  = 1;
my $pressfit = 0;
my $tolHole = 0;
my $maska01  = 0;
my $datacode  = "";
my $ullogo  = "";
my $jumpScoring  = 0;

 

my $inCAM = InCAM->new();
my $export = NifExportTmpPool->new();

#return 1 if OK, else 0
$export->Run( $inCAM, $jobId, $poznamka, $tenting, $pressfit, $tolHole, $maska01, $datacode, $ullogo, $jumpScoring);
