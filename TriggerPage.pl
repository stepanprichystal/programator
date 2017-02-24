#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: Script launch some packages, when job goes to produce
# This script is launched by tpv-server by script c:\inetpub\wwwroot\tpv\StartTrigger.pl
# See c:\inetpub\wwwroot\tpv\Log.txt, whih jobs go to produce or for errors
# Author:SPR
#-------------------------------------------------------------------------------------------#

use strict;
use warnings;
use Try::Tiny;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::TriggerFunction::MDIFiles';

my $jobId = shift;    # job id of job, which goes to produce
$jobId = "f52456";

if ( !defined $jobId || $jobId eq "" ) {
	exit(0);
}

# 1) change some lines in MDI xml files

try {
	
	MDIFiles->AddPartsNumber($jobId);
}
catch {

	print STDERR $_;
	
}
