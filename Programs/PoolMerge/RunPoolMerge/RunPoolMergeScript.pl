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

# set path of configuration
$main::stylePath = GeneralHelper->Root() . "\\Programs\\PoolMerge\\Config\\Config.txt";
my $appName = AppConf->GetValue("appName");

my $console = Win32::Console->new;

$console->Title( "Cmd of $appName PID:" . $$ );
Helper->ShowAbstractQueueWindow( 0, "Cmd of $appName PID:" . $$ );

my $merger = PoolMerge->new( EnumsMngr->RUNMODE_TRAY );

