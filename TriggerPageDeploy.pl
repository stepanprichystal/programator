#!/usr/bin/perl -w
#
#-------------------------------------------------------------------------------------------#
# Description: Script launch some packages, when job goes to produce
# This script is launched by tpv-server by script c:\inetpub\wwwroot\tpv\StartTrigger.pl
# See c:\inetpub\wwwroot\tpv\Log.txt, whih jobs go to produce or for errors
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use POSIX 'strftime';
use File::Basename;
use Try::Tiny;

#local library
use lib qw( \\\\incam\\InCAM\\server\\site_data\\scripts);
use aliased 'Packages::TriggerFunction::MDIFiles';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::TriggerFunction::NCFiles';

my $jobId     = shift;    # job for process
my $processed = 1;

# 1) change some lines in MDI xml files eval

eval {

	MDIFiles->AddPartsNumber($jobId);

};
if ($@) {

	$processed = 0;
	Log( "\n Error when processing \"MDI files\" job: $jobId.\n" . $@, 1 );
}

# 2) change drilled number in NC files
eval {

	NCFiles->ChangePcbOrderNumber($jobId);

};
if ($@) {

	$processed = 0;
	Log( "\n Error when processing \"NC files\" job: $jobId.\n" . $@, 1 );
}


# Log

if ($processed) {
	
	Log("Processed ");

}
else {
 
	Log("Processed with ERRORS ");
}

sub Log {
	my $mess = shift;
	my $err  = shift;

	my $now_string = strftime( "%Y-%m-%d %H:%M:%S", localtime );

	# 3 attem to write to file

	my $logPath = "c:\\Apache24\\htdocs\\tpv2\\Logs\\Log.txt";    #current dir

	if ($err) {
		$logPath = "c:\\Apache24\\htdocs\\tpv2\\Logs\\LogErr.txt";
	}

	ReduceLog($logPath);

	my $att = 0;
	my $fh;
	my $fileOpen = open( $fh, '>>', $logPath );

	while ( !$fileOpen && $att < 3 ) {
		$att++;
		sleep(1);
	}

	if ($fileOpen) {
		print $fh $jobId . " - " . $mess . " at $now_string \n";
		close($fh);
	}

}

sub ReduceLog {
	my $logPath = shift;

	my $fh;
	if ( open( $fh, '<', $logPath ) ) {

		my @lines = <$fh>;

		if ( scalar(@lines) > 100000 ) {

			close($fh);

			@lines = splice @lines, 200, scalar(@lines) - 1;
			unlink($logPath);
			my $fhDel;
			if ( open( $fhDel, '>', $logPath ) ) {
				print $fhDel @lines;
				close($fhDel);
			}
		}
	}

}
