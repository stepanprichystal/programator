#!/usr/bin/perl-w

#3th party library
use strict;
use warnings;

use aliased 'Packages::ETesting::ExportIPC::ExportIPC';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::ETesting::BasicHelper::Helper' => 'ETHelper';

my $jobId = $ENV{JOB};
my $inCAM = InCAM->new();

my $step = "panel";

my $e = ExportIPC->new( $inCAM, $jobId, $step, 1, );

my $keepProfiles = ETHelper->KeepProfilesAllowed( $inCAM, $jobId, "panel" );

$e->Export(undef, $keepProfiles );

1;

