#!/usr/bin/perl-w
#################################

use warnings;
use strict;

my $jobName = shift;

open (WRITE,">>//incam/incam_server/site_data/scripts/ReportTest.txt");
			print WRITE $jobName , "\n";
close WRITE;