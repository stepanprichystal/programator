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
use aliased 'Widgets::Forms::LoadingForm';
 
 
#my $CONSOLE=Win32::Console->new;
#$CONSOLE->Title("Loading Exporter Checker"); 

 
my $frm = LoadingForm->new(-1, "Loading Exporter Checker...");

$frm->MainLoop();

 



