#!/usr/bin/perl

use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::GuideSubs::Coupons::DoZaxisCoupon';

my $inCAM   = InCAM->new();
my $jobName = "$ENV{JOB}";

# Return 1 if success
my $resZaxis = DoZaxisCoupon->GenerateZaxisCoupons($inCAM, $jobName );
