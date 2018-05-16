#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: This script only run pool merger in tray mode
# Author:SPR
#-------------------------------------------------------------------------------------------#

use strict;
use warnings;
use Win32::Console;


our $configPath = undef;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::PoolMerge::PoolMerge::PoolMerge';
use aliased 'Managers::AsyncJobMngr::Enums' => 'EnumsMngr';
use aliased 'Managers::AbstractQueue::Helper';
use aliased 'Managers::AsyncJobMngr::Helper' => "AsyncJobHelber";
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Other::AppConf';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';

#use Tee;
#use Symbol;
#
#my @handles = (*STDOUT);
#my $handle;
#push( @handles, $handle = gensym() );
#open( $handle, "+>c:\\Export\\test1.txt" );
#tie *TEE, "Tee", @handles;
#select(TEE);
#*STDERR = *TEE;
#print "raw print\n";
#print STDERR "XXXX\n";

# ==========================================================
# App settings
# ==========================================================

# set path of configuration
$main::configPath = GeneralHelper->Root() . "\\Programs\\PoolMerge\\Config\\Config.txt";
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
	Helper->Logging(  EnumsPaths->Client_INCAMTMPLOGS . "poolMerge");
}
 

# Catch die, then:
# 1) show message to user;
# 2) print it to stderr;
my $merger = undef;
eval {

	$merger = PoolMerge->new( EnumsMngr->RUNMODE_TRAY );
	 
	$merger->Run();

};
if ($@) {
 
	my $path = AsyncJobHelber->GetLogDir();
 
	$merger->StopAllTimers() if(defined $merger);
	

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

	my $logConfig = GeneralHelper->Root() . "\\Programs\\PoolMerge\\Config\\Logger.conf";

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

