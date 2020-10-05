#!/usr/bin/perl -w

use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Exporter::ExportCheckerMini::RunExport::RunExporterCheckerMini';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

my $jobId   = $ENV{"JOB"};
my $unitId  = UnitEnums->UnitId_COMM;
my $unitDim = [ 600, 400 ];

my $form = RunExporterCheckerMini->new( $jobId, $unitId, $unitDim );
$form->LaunchViaAppLauncher();

