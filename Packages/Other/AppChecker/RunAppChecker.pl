#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use File::Copy;
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use File::Basename;
#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportUtility::Groups::PlotExport::PlotExportTmp';
use aliased 'Packages::Other::AppChecker::AppChecker';
use aliased 'Packages::Other::AppChecker::Helper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsApp';

my $appChecker = AppChecker->new();
 

# Add export Utility APP





# If app is launched, but is not active more than 5 ssecond, copz logs
my $exportUtilityCond = sub  {
	my $appChecker = shift;
	my $app        = shift;

	my $p = EnumsPaths->Client_INCAMTMPLOGS . "\\" . $app->{"appName"} . "\\LoggerAppState.txt";

	my $scriptName = "RunExportUtilityScript";

	if ( Helper->CheckRunningInstance($scriptName) ) {

		# check status log (this file should be updated every second)
		my $diff = ( time() - ( stat($p) )[9] );    # diff  in sec

		if ( $diff > 0 ) {

			my $path = $appChecker->CreateLogPath($app->{"appName"});

			#move all logs from lof dir
			my $appLog = EnumsPaths->Client_INCAMTMPLOGS . "\\" . $app->{"appName"};

			opendir( DIR, $appLog ) or die $!;

			while ( my $file = readdir(DIR) ) {

				#next unless $file =~ /^[a-z](\d+)/i;

				next if ( $file =~ /^\.$/ );
				next if ( $file =~ /^\.\.$/ );

				copy( $appLog."\\".$file, $path."\\".$file);
			}
		}

		close(DIR);

	}

};


$appChecker->AddApp( EnumsApp->App_EXPORTUTILITY, $exportUtilityCond);


$appChecker->Run();

 
