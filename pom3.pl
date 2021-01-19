#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Do final routing = 2mm with compensation left and suitable start of chain
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use utf8;
use strict;
use warnings;

use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Exporter::ExportUtility::Groups::ScoExport::ScoExportTmp';

my $jobId = "f13609";
my $inCAM = InCAM->new();
my $lName = "footdown_" . $jobId;

if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {
	$inCAM->COM( "delete_layer", "layer" => $lName );
}

$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );
 

# Draw helper scheme which clarify where should be placed woot downs

$inCAM->COM(
			 "display_layer",
			 name    => $layer,
			 display => "yes",
			 number  => 2
);

$inCAM->COM( "work_layer", name => $layer );
