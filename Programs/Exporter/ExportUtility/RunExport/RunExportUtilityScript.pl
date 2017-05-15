#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: This script only run exporter utility in tray mode
# Author:SPR
#-------------------------------------------------------------------------------------------#

our $stylePath = undef;

use strict;
use warnings;
use Win32::Console;

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
use aliased 'Managers::AsyncJobMngr::AppConf';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';

# set path of configuration
$main::stylePath = GeneralHelper->Root() . "\\Programs\\Exporter\\ExportUtility\\Config\\Config.txt";
my $appName = AppConf->GetValue("appName");

my $console = Win32::Console->new;

$console->Title( "Cmd of $appName PID:" . $$ );
Helper->ShowAbstractQueueWindow( 0, "Cmd of $appName PID:" . $$ );



# ==========================================================
# App logging
# ==========================================================

AsyncJobHelber->SetLogging();

if ( AppConf->GetValue("logingType") == 1 ) {
	Helper->Logging();
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

