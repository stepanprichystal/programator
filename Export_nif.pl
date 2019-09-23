#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packagesff
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExportTmp';



#input parameters
 
my $jobId    = "d254466";
 
my $poznamka = "";
my $tenting  = 0;
my $pressfit = 0;
my $maska01  = 0;
my $datacode  = "";
my $ullogo  = "";
my $jumpScoring  = 0;

 


my $inCAM = InCAM->new();
my $export = NifExportTmp->new();

#return 1 if OK, else 0
$export->Run( $inCAM, $jobId, $poznamka, $tenting, $pressfit, $maska01, $datacode, $ullogo, $jumpScoring);
