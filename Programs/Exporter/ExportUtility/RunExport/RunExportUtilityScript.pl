#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: This script only run exporter utility in tray mode
# Export utility can be "server" version. If exist envirmental var TPV_ExportServerVersion = 1
# Author:SPR
#-------------------------------------------------------------------------------------------#

our $configPath = undef;

use strict;
use warnings;
use Win32::Console;
use Log::Log4perl qw(get_logger :levels);

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Exporter::ExportUtility::ExportUtility::ExportUtility';
use aliased 'Managers::AsyncJobMngr::Enums' => 'EnumsMngr';
use aliased 'Managers::AbstractQueue::Helper';
use aliased 'Managers::AsyncJobMngr::Helper' => "AsyncJobHelber";
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Other::AppConf';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';

# set path of configuration
$main::configPath = GeneralHelper->Root() . "\\Programs\\Exporter\\ExportUtility\\Config\\Config.txt";
my $appName = AppConf->GetValue("appName");

my $console = Win32::Console->new;

$console->Title( "Cmd of $appName PID:" . $$ );
Helper->ShowAbstractQueueWindow( 0, "Cmd of $appName PID:" . $$ );



# ==========================================================
# App logging
# ==========================================================
 


# Loging new with Log4perl
__SetLogging();
 
# Logging which redirest STDOUT + STDERR to file
if ( AppConf->GetValue("logingType") == 1 ) {
	Helper->Logging(EnumsPaths->Client_INCAMTMPLOGS . "exportUtility");
}
 


 
 

# Catch die, then:
# 1) show message to user;
# 2) print it to stderr;

my $exporter = undef;

eval {

	$exporter = ExportUtility->new( EnumsMngr->RUNMODE_TRAY );
	$exporter->Run();

};
if ($@) {

	my $appName = AppConf->GetValue("appName");
	$appName =~ s/\s//g;
	my $path = EnumsPaths->Client_INCAMTMPJOBMNGR . $appName . "\\";

	print STDERR $@;

	$exporter->StopAllTimers();

	my @m = (
		"Doslo k neocekavanmu padu aplikace",
		"1) Pozor dulezite!! Odesli report emailem SPR (vyfot screen cele obrazovky + zabal vsechny soubory z adresy: $path )",
		"2) zkontroluj co potrebujes a aplikace bude ukoncena.", $@
	);

	my $mngr = MessageMngr->new($appName);
	$mngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@m );    #  Script se zastavi
}


# Set logging Log4perl
sub __SetLogging {

	my $logConfig = GeneralHelper->Root() . "\\Programs\\Exporter\\ExportUtility\\Config\\Logger.conf";

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


