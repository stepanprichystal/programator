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
use aliased 'Programs::Exporter::ExportUtility::Groups::PlotExport::PlotExportTmp';
use aliased 'Packages::Export::PreExport::FakeLayers';
 
my $jobId    = "d296630";
 
 
my $inCAM    = InCAM->new();


FakeLayers->CreateFakeLayers( $inCAM, $jobId, "panel", 0 );

#GET INPUT NIF INFORMATION
 

my $export = PlotExportTmp->new();
$export->Run( $inCAM, $jobId );
