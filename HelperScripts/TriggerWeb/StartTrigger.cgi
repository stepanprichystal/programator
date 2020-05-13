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
use Log::Log4perl qw(get_logger :levels);

#local library
#use lib qw( \\\\incam\\InCAM\\server\\site_data\\scripts);

my $logger = __SetLogging();

# all do in try/catch, errors put in ErrLog
eval {

	my $query = new CGI;
	print $query->header("text/html");

	my $jobId    = $query->param("jobid");
	my $taskType = $query->param("request");
	my $loginId  = $query->param("userid");
	my $extraId  = $query->param("extraid");

	my $wholeRequest = $query->url() . $ENV{'QUERY_STRING'} . "\n\n";
	$logger->debug( "complete request: " . $wholeRequest );
	if ( !defined $taskType || $taskType eq "" ) {
		$taskType = 'not_defined';
	}

	if ( !defined $extraId || $extraId eq "" ) {
		$extraId = 0;
	}
	
	# 1) Log before call TrigerPage.pl
	$logger->info("Params of request: jobId = $jobId, task = $taskType, extraId = $extraId");

	# 2) Run TrigerPage.pl
	my $result = __TriggerPage( $jobId, $taskType, $loginId, $extraId );

	# 3) Tell to helios, all ists ok
	print $result;

};
if ($@) {
	$logger->error( "Error when launch TriggerPage.pl " . $@, );

}

# Run script triggerPage in new window indipendently on this web
sub __TriggerPage {
	my $jobId    = shift;
	my $taskType = shift;
	my $loginId  = shift;
	my $extraId  = shift;

	my $result = "OK";

	my $path = "\\\\incam\\incam_server\\site_data\\scripts\\TriggerPage.pl";

	#my $path = 'c:\Perl\site\lib\TpvScripts\Scripts\TriggerPage.pl';

	unless ( -e $path ) {
		my $err =
		  "Nepodarilo se spustit script \"$path\", ktery je volan Heliosem pri zadani dps do vyroby pomoci URL:" . CGI->new()->url() . " Volej TPV.";
		$logger->error($err);

		$result = $err;
	}

	#server pid
	my $pid = $$;

	my $perl = $Config{perlpath};
	my $processObj2;
	Win32::Process::Create( $processObj2, $perl, "perl -w " . $path . " " . $jobId . " " . $taskType . " " . $loginId." ".$extraId,
							0, NORMAL_PRIORITY_CLASS | CREATE_NEW_CONSOLE, "." )
	  || $logger->error("Error when launch TriggerPage.pl");

	return $result;

}

sub __SetLogging {

	my $logConfig = "c:\\Apache24\\htdocs\\tpv\\Logger.conf";

	# create log dirs for all application
	my @dirs = ();
	if ( open( my $f, "<", $logConfig ) ) {

		while (<$f>) {
			if ( my ($logFile) = $_ =~ /.filename\s*=\s*(.*)/ ) {

				my ( $dir, $f ) = $logFile =~ /^(.+)\\([^\\]+)$/;
				unless ( -e $dir ) {
					mkdir($dir) or die "Can't create dir: " . $dir . $_;
				}
			}
		}
		close($logConfig);
	}

	Log::Log4perl->init($logConfig);

	return get_logger("trigger");

}

