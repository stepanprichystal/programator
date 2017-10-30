#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";50
#use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportUtility::Groups::StnclExport::StnclExportTmp';

my $jobId    = "f13609";
my $inCAM    = InCAM->new();


my $export = StnclExportTmp->new();
$export->Run( $inCAM, $jobId );
