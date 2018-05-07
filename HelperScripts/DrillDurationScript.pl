#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: Compute duration of drilling and store results to: C:/Export/DrillDuration.txt
# Run in InCAM, put job ids separated with space as parameter
# Author:SPR
#-------------------------------------------------------------------------------------------#


#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Helpers::FileHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAMJob::Drilling::DrillDuration::DrillDuration';

my @jobs = ();
while ( my $j = shift ) {

	$j =~ s/\s//g;

	$j = lc($j);

	die "paremeter is not in job format: $j" if ( $j !~ /^\w\d+$/ );

	push( @jobs, $j );
}

print STDERR scalar(@jobs);

my $inCAM = InCAM->new();

my $res = "";

foreach my $jobId (@jobs) {

	my $wasOpened = 0;

	my $usr = "";
	if ( CamJob->IsJobOpen( $inCAM, $jobId, 1, \$usr ) ) {

		my $usrName = $ENV{USERNAME};
		if ( lc($usr) !~ /$usrName/i ) {

			print STDERR "Job: $jobId is open by  $usr\n";
			next;
		}
	}

	if ( CamJob->IsJobOpen( $inCAM, $jobId ) ) {

		$wasOpened = 1;
	}

	CamHelper->OpenJob( $inCAM, $jobId ) unless ($wasOpened);

	my $duration = DrillDuration->GetDrillDuration( $inCAM, $jobId, "panel", "m" );

	$res .= "JobId = $jobId, duration = " .  sprintf("%02d:%02d:%02d", $duration/3600, $duration/60%60, $duration%60) . "\n";

	CamJob->CloseJob( $inCAM, $jobId ) unless ($wasOpened);

}

FileHelper->WriteString( 'c:/Export/DrillDuration.txt', $res );
