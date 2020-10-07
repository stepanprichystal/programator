#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Exporter::ExportCheckerMini::ExportCheckerMini';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::InCAMHelpers::AppLauncher::Launcher';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';

# First argument shoul be jobId
my $jobId = shift;

# Second should be portt
my $port = shift;

# third should be pid of serverq
my $pid = shift;

# pid of loading form
my $pidLoadFrm = shift;

unless ($jobId) {

	$jobId = "d294504";

}

#my $unitId = UnitEnums->UnitId_PDF;
#my $unitDim = [320, 400];

my $unitId = UnitEnums->UnitId_COMM;
my $unitDim = [ 600, 400];

my $form = ExportCheckerMini->new( $jobId, $unitId, $unitDim,0);

my $launcher = Launcher->new(56753);

$form->Init($launcher);

$form->Run();

