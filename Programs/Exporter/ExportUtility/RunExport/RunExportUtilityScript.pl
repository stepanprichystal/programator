#!/usr/bin/perl -w


#-------------------------------------------------------------------------------------------#
# Description: This script only run exporter utility in tray mode
# Author:SPR
#-------------------------------------------------------------------------------------------#

use strict;
use warnings;
use Win32::Console;


use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Exporter::ExportUtility::ExportUtility::ExportUtility';
use aliased 'Managers::AsyncJobMngr::Enums'           => 'EnumsMngr';
use aliased 'Programs::Exporter::ExportUtility::Helper';

 
 
my $CONSOLE=Win32::Console->new;
$CONSOLE->Title('Cmd of ExporterUtility PID:'.$$); 

Helper->ShowExportWindow(1,"Cmd of ExporterUtility PID:".$$);
 
my $exporter = ExportUtility->new(EnumsMngr->RUNMODE_TRAY);

 



