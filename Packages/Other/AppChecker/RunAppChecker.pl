#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use File::Copy;
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use File::Basename;
use Tie::File;
use Log::Log4perl qw(get_logger :levels);


#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::Other::AppChecker::AppChecker';
use aliased 'Packages::Other::AppChecker::Helper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsApp';

# Singleton script
my @pids = ();
if ( Helper->CheckRunningInstance( "RunAppChecker", \@pids ) ) {
	if ( @pids > 1 ) {
		exit(0); # exit if script is already running
	}
}




# Add export Utility APP

# If app is launched, but is not active more than 5 ssecond, copz logs
my $asyncAppCond = sub {
	my $appChecker = shift;
	my $app        = shift;
	my $scriptName = $app->{"appData"};

	my $result = 0;

	my $p = EnumsPaths->Client_INCAMTMPLOGS . "\\" . $app->{"appName"} . "\\LoggerAppState.txt";

	if ( Helper->CheckRunningInstance($scriptName) ) {

		# check status log (this file should be updated every second)

		my $refTime = time();
 
		tie my @file, 'Tie::File', $p
		  or die "Can't open $p: $!\n";
		my $date = $file[-1];

		unless ( $date =~ m/^(\d{4})\/(\d{2})\/(\d{2}) (\d{2}):(\d{2}):(\d{2})/ ) {
			return 0;
		}
		my $dt = DateTime->new(
								"year"      => $1,
								"month"     => $2,
								"day"       => $3,
								"hour"      => $4,
								"minute"    => $5,
								"second"    => $6,
								"time_zone" => 'Europe/Prague'
		);

		my $diff = $refTime - $dt->epoch();

		if ( $diff > 0 ) {
			$result = 1;
		}

	}

	return $result;

};

my $asyncAppAction = sub {
	my $appChecker = shift;
	my $app        = shift;

	my $path = $appChecker->CreateLogPath( $app->{"appName"} );

	#move all logs from lof dir
	my $appLog = EnumsPaths->Client_INCAMTMPLOGS . "\\" . $app->{"appName"};

	opendir( DIR, $appLog ) or die $!;

	while ( my $file = readdir(DIR) ) {

		#next unless $file =~ /^[a-z](\d+)/i;

		next if ( $file =~ /^\.$/ );
		next if ( $file =~ /^\.\.$/ );

		copy( $appLog . "\\" . $file, $path . "\\" . $file );
	}

	close(DIR);

};


# Init app checker


my $appChecker = AppChecker->new();

$appChecker->AddApp( EnumsApp->App_EXPORTUTILITY, $asyncAppCond, $asyncAppAction, "RunExportUtilityScript" );
$appChecker->AddApp( EnumsApp->App_POOLMERGE,     $asyncAppCond, $asyncAppAction, "RunPoolMergeScript" );

$appChecker->Run();

# Set logging Log4perl
sub __SetLogging {

	my $logConfig = GeneralHelper->Root() . "\\Programs\\AppChecker\\Logger.conf";

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
}
