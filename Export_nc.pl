#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Programs::Exporter::ExportUtility::Groups::NCExport::NCExportTmp';

 

my $inCAM  = InCAM->new();
my $export = NCExportTmp->new();

#input parameters
 
 
my $jobId = "f52457";
 
 
 

# Exportovat jednotlive vrstvy nebo vsechno
my $exportSingle = 0;

# Vrstvy k exportovani, nema vliv pokud $exportSingle == 0
my @pltLayers  = ();
my @npltLayers = ();

# Pokud se bude exportovat jednotlive po vrstvach, tak vrstvz dotahnout nejaktakhle:
#@pltLayers = CamDrilling->GetPltNCLayers( $inCAM, $jobId );
#@npltLayers = CamDrilling->GetNPltNCLayers( $inCAM, $jobId );

#return 1 if OK, else 0
$export->Run( $inCAM, $jobId, $exportSingle, \@pltLayers, \@npltLayers );

