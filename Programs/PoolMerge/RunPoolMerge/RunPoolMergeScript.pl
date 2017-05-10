#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: This script only run pool merger in tray mode
# Author:SPR
#-------------------------------------------------------------------------------------------#

use strict;
use warnings;
use Win32::Console;

our $stylePath = undef;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::PoolMerge::PoolMerge::PoolMerge';
use aliased 'Managers::AsyncJobMngr::Enums' => 'EnumsMngr';
use aliased 'Managers::AbstractQueue::Helper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::AbstractQueue::AppConf';
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

# set path of configuration
$main::stylePath = GeneralHelper->Root() . "\\Programs\\PoolMerge\\Config\\Config.txt";
my $appName = AppConf->GetValue("appName");

my $console = Win32::Console->new;

$console->Title( "Cmd of $appName PID:" . $$ );
Helper->ShowAbstractQueueWindow( 0, "Cmd of $appName PID:" . $$ );

Helper->CreateDirs();

if ( AppConf->GetValue("logingType") == 1 ) {
	Helper->Logging();
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

	my $appName = AppConf->GetValue("appName");
	$appName =~ s/\s//g;
	my $path = EnumsPaths->Client_INCAMTMPJOBMNGR . $appName . "\\Logs";

	print STDERR $@;

	$merger->StopAllTimers();

	my @m = (
		"Doslo k neocekavanmu padu aplikace",
		"1) Pozor dulezite!! Odesli report emailem SPR (vyfot screen cele obrazovky + logfile z adresy: $path",
		"2) zkontroluj co potrebujes a aplikace bude ukoncena.", $@
	);

	my $mngr = MessageMngr->new($appName);
	$mngr->ShowModal( -1, EnumsGeneral->MessageType_SYSTEMERROR, \@m );                                    #  Script se zastavi
}

