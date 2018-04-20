#!/usr/bin/perl -w

# Description: Do tracking "app" status every second
# If Condition is fulfiled, special action is launched
# Author:SPR
#-------------------------------------------------------------------------------------------#


#3th party library
use strict;
use warnings;
use File::Copy;
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use File::Basename;
use Tie::File;
use Log::Log4perl qw(get_logger :levels);
use Win32::Console;
use Win32::GuiTest qw(FindWindowLike SetWindowPos ShowWindow);


#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::AppChecker::AppChecker';
use aliased 'Programs::AppChecker::Helper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::GeneralHelper';


my $noHide = shift;

# Log for perl
__SetLogging();
my $logger = get_logger(EnumsApp->App_APPCHECKER);
 $logger->info("AppChecker launched on pc: ".$ENV{USERNAME});


# Singleton script
my @pids = ();
if ( Helper->CheckRunningInstance( "RunAppChecker", \@pids ) ) {
	if ( @pids > 1 ) {
		
		$logger->info("AppChecker already launched => exit, on pc: ".$ENV{USERNAME});
		print STDERR "App already exist\n";
		exit(0); # exit if script is already running
	}
}

# Hide app
__HideConsole() unless($noHide);
 

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
		
		return 0 if(scalar(@file) < 30); 

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

		if ( $diff > 10 ) {
			
			$logger->info(" App: ".$app->{"appName"}. " failed on PC: " .$ENV{USERNAME});
			
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



#-------------------------------------------------------------------------------------------#
#  Init app checker
#-------------------------------------------------------------------------------------------#


my $appChecker = AppChecker->new();

$appChecker->AddApp( EnumsApp->App_EXPORTUTILITY, $asyncAppCond, $asyncAppAction, "RunExportUtilityScript" );
$appChecker->AddApp( EnumsApp->App_POOLMERGE,     $asyncAppCond, $asyncAppAction, "RunPoolMergeScript" );

$appChecker->Run();




#-------------------------------------------------------------------------------------------#
#  Helper method
#-------------------------------------------------------------------------------------------#


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
 
 
 
 sub __HideConsole {
	my $self = shift;

	my $console = Win32::Console->new;
	$console->Title("RunAppChecker_!_"); #set unique title

	my @windows = FindWindowLike( 0, "RunAppChecker_!_" );
	for (@windows) {
		ShowWindow( $_, 0 );
	}

	return 0;
}
 
