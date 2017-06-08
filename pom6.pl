#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

#necessary for load pall packagesff
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::Drilling::DrillChecking::LayerCheckError';
use aliased 'Packages::Drilling::DrillChecking::LayerCheckWarn';

my $inCAM = InCAM->new();
my $jobId = "f72963";
my $step  = "o+1";

# contain error messages
my $mess = "";

# Return 0 = errors, 1 = no error
my $result = LayerCheckError->CheckNCLayers( $inCAM, $jobId, "o+1", undef, \$mess );

print STDERR "Result check err is $result \n";


my $mess2 = "";

# Return 0 = errors, 1 = no error
my $result2 = LayerCheckWarn->CheckNCLayers( $inCAM, $jobId, "o+1", undef, \$mess2 );

print STDERR "Result check warn is $result2 \n";
 