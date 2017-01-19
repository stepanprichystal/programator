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
use aliased 'Programs::Exporter::ExportUtility::Groups::ScoExport::ScoExportTmp';

my $jobId    = "f60487";
my $inCAM    = InCAM->new();


#GET INPUT NIF INFORMATION
 

my $export = ScoExportTmp->new();
$export->Run( $inCAM, $jobId );
