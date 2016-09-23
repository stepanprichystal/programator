#!/usr/bin/perl -w


#-------------------------------------------------------------------------------------------#
# Description: This script only run exporter utility in tray mode
# Author:SPR
#-------------------------------------------------------------------------------------------#

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Exporter::ExportUtility::ExportUtility::ExportUtility';
use aliased 'Managers::AsyncJobMngr::Enums'           => 'EnumsMngr';
#use aliased 'Programs::Exporter::ExportChecker::Server::Client';



my $exporter = ExportUtility->new(EnumsMngr->RUNMODE_TRAY);

 
#Win32::OLE->new
 
 




