#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: This script only run pool merger in tray mode
# Author:SPR
#-------------------------------------------------------------------------------------------#

use strict;
use warnings;
use Win32::Console;



#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );


use aliased 'Programs::PoolMerge::PoolMerge::PoolMerge';
use aliased 'Managers::AsyncJobMngr::Enums' => 'EnumsMngr';
use aliased 'Managers::AbstractQueue::AbstractQueue::Helper';
 


my $console = Win32::Console->new;

$console->Title( 'Cmd of PoolMerge PID:' . $$ );
Helper->ShowAbstractQueueWindow( 0, "Cmd of PoolMerge PID:" . $$ );

my $merger = PoolMerge->new( EnumsMngr->RUNMODE_TRAY );

