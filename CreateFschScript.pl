#!/usr/bin/perl -w

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::GuideSubs::Routing::DoCreateFsch';
use aliased 'Packages::InCAM::InCAM';

my $jobId = $ENV{"JOB"};
my $inCAM = InCAM->new();

# Return 1 if success
my $result = DoCreateFsch->CreateFsch( $inCAM, $jobId );

