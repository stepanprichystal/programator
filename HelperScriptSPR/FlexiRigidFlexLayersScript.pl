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

use aliased 'Packages::GuideSubs::Flex::DoPrepareRigidFlexLayers';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Managers::MessageMngr::MessageMngr';

my $inCAM    = InCAM->new();
my $jobId    = "$ENV{JOB}";
my $stepName = "$ENV{STEP}";

my $res = DoPrepareRigidFlexLayers->PrepareLayers( $inCAM, $jobId );

print STDERR "Result is: $res, error message \n";

