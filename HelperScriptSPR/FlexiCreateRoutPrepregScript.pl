#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: Add cu to signal layer by bend area
# Author:SPR

#3th party library
use strict;
use warnings;

#loading of locale modules
use aliased 'Helpers::GeneralHelper';

#3th party library
use strict;
use warnings;

use aliased 'Enums::EnumsPaths';

use aliased 'Packages::CAMJob::FlexiLayers::FlexiBendArea';
use aliased 'Packages::InCAM::InCAM';

my $inCAM    = InCAM->new();
my $jobId    = "$ENV{JOB}";
my $stepName = "$ENV{STEP}";

my $mess = "";

my $result = FlexiBendArea->CreateRoutPrepregByBendArea( $inCAM, $jobId, $stepName );

print STDERR "Result is: $result, error message: $mess\n";
