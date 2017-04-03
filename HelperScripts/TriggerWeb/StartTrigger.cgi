#!C:\perl\bin\perl.exe

#-------------------------------------------------------------------------------------------#
# Description: Perl cgi script, which run TriggerPage.pl which is respnse for
# launching packages, necessary after dps go to produce
# 1) Web log record before TriggerPage.pl is launched (log is placed at c:\Apache24\htdocs\tpv\Log.txt)
# 2) TriggerPage.pl log pcb was processed
# 3) TriggerPage.pl log if some packages reise error (c:\Apache24\htdocs\tpv\LogError.txt)
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use strict;
use CGI;
use Win32::Process;
use Config;
use POSIX 'strftime';
use File::Basename;

#local library


# all do in try/catch, errors put in ErrLog
eval {
	
	my $query = new CGI;
	print $query->header("text/html");
 
	my $jobId = $query->param("jobid");
	 
 
	# 1) Log before call TrigerPage.pl
	Log("To produce");

	
	# 2) Run TrigerPage.pl
	__TriggerPage();


	# 3) Tell to helios, all ists ok
	print "OK";
 


	# Run script triggerPage in new window indipendently on this web
	sub __TriggerPage {
		my $self = shift;

		my $path = "\\\\incam\\incam_server\\site_data\\scripts\\TriggerPage.pl ";

		#server pid
		my $pid = $$;
 
		my $perl = $Config{perlpath};
		my $processObj2;
		Win32::Process::Create( $processObj2, $perl,
							   "perl -w " . $path.$jobId,
							   0, NORMAL_PRIORITY_CLASS | CREATE_NEW_CONSOLE, "." )
		  || Log("Error when launch TriggerPage.pl");
 

	}

	sub Log {
		my $mess = shift;

		my $now_string = strftime( "%Y-%m-%d %H:%M:%S", localtime );

		# 3 attem to write to file

 
		my $logPath = ( fileparse($0) )[1]."\\Logs\\Log.txt";    #current dir
 

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

};
if ($@) {

	 Log("Error when launch TriggerPage.pl ".$@, );

}
