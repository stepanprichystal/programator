#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::PoolMerge::PoolMerge::PoolMerge';
use aliased 'Managers::AsyncJobMngr::Enums'           => 'EnumsMngr';
use aliased 'Packages::InCAM::InCAM';
#use aliased 'Programs::Exporter::ExportChecker::Server::Client';



my $poolMerger = PoolMerge->new(EnumsMngr->RUNMODE_TRAY);

 
#Win32::OLE->new
 
 




