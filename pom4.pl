#!/usr/bin/perl -w

use Win32::Process;
use Config;
use DateTime;
use File::Basename;

my $jobId = shift;
my $root  = shift;

my $dt   = DateTime->now;    # Stores current date and time as datetime object
my $date = $dt->ymd;         # Retrieves date as a string in 'yyyy-mm-dd' format
my $time = $dt->hms;         # Retrieves time as a string in 'hh:mm:ss' format

my $now_string = "$date $time";    # creates 'yyyy-mm-dd hh:mm:ss' string

Log("to produce");

#system("\\\\incam\\incam_server\\site_data\\scripts\\TriggerPage.pl $jobId");

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
	  || Log("Cant create process and call TriggerPage.pl ");

}

sub Log {
	my $mess = shift;

	# 3 attem to write to file

	my $logPath = "c:\\inetpub\\wwwroot\\tpv\\Log.txt";

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

		if ( scalar(@lines) > 10 ) {

			close($fh);

			@lines = splice @lines, 0, 5;
			unlink($logPath);
			my $fhDel;
			if ( open( $fhDel, '>', $logPath ) ) {
				print $fhDel @lines;
				close($fhDel);
			}
		}
	}

}
