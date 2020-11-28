#!/usr/bin/perl
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::GuideSubs::Routing::DoCreateFsch';

my $inCAM   = InCAM->new();
my $jobName = shift;

# Return 1 if success
my $result = DoCreateFsch->CreateFsch( $inCAM, $jobName );
