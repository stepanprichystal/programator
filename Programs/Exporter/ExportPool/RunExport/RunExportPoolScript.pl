#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: This script only run exporter utility in tray mode
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


use aliased 'Programs::Exporter::ExportPool::ExportPool::ExportPool';
use aliased 'Managers::AsyncJobMngr::Enums' => 'EnumsMngr';
use aliased 'Managers::AbstractQueue::AbstractQueue::Helper';
 


my $console = Win32::Console->new;

$console->Title( 'Cmd of ExporterUtility PID:' . $$ );
Helper->ShowExportWindow( 0, "Cmd of ExporterUtility PID:" . $$ );

my $exporter = ExportPool->new( EnumsMngr->RUNMODE_TRAY );

