#!/usr/bin/perl -w

use Win32::Process;
use Config;

my $jobId = shift;

#$jobId = "ddddddd";
 
#system("\\\\incam\\incam_server\\site_data\\scripts\\TriggerPage.pl $jobId");

open( my $fh, '>>', 'c:\\test\\test.txt' );

__TriggerPage();

sub __TriggerPage {
	my $self = shift;

	#server pid
	my $pid = $$;

	#my $processObj;
	my $perl = $Config{perlpath};
	my $processObj2;
	Win32::Process::Create( $processObj2, $perl, "perl " . "\\\\incam\\incam_server\\site_data\\scripts\\TriggerPage.pl $jobId",
							1, NORMAL_PRIORITY_CLASS, "." )
	  || print $fh  "Unable to run trigger page for: $jobId\n";

}

print $fh "Run job Id: $jobId\n";
close($fh);
