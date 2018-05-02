#!/usr/bin/perl -w

use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Exporter::ExportUtility::ExportUtility::ExportUtility';
use aliased 'Managers::AsyncJobMngr::Enums'           => 'EnumsMngr';
use aliased 'Packages::InCAM::InCAM';
#use aliased 'Programs::Exporter::ExportChecker::Server::Client';



my $exporter = ExportUtility->new(EnumsMngr->RUNMODE_TRAY);
$exporter->Run();
 
#Win32::OLE->new
 
 




