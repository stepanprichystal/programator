#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Exporter::ExportUtility::ExportUtility::ExportUtility';
use aliased 'Managers::AsyncJobMngr::Enums' => 'EnumsMngr';
use aliased 'Packages::InCAM::InCAM';

#use aliased 'Programs::Exporter::ExportChecker::Server::Client';
use aliased 'Programs::PoolMerge::UnitEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();

# Debug variable
$main::DEBUG = 1;

# ----------------------------------------------
# Debug options
# ----------------------------------------------

NotCreateServer();

# ----------------------------------------------

if ( $inCAM->IsConnected() ) {
	$inCAM->ClientFinish();
}

my $exporter = ExportUtility->new( EnumsMngr->RUNMODE_TRAY );
$exporter->Run();


# PoolMerger conenct to server on port 56753
sub NotCreateServer {

	$main::debugPortServer = 56753;
}

