#-------------------------------------------------------------------------------------------#
# Description: Helper for create plug layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::ViaFilling::PlugLayer;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Create via_plug layers based on NC via fill layers
sub CreateCopperPlugLayers {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $annularRing = shift // 75;    # annular ring for via plug is 75um

	die "Unable to create plgc; plgs layers. There are no NC via fill layers." unless ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) );

	my $plgTop = "plgc";
	my $plgBot = "plgs";

	CamMatrix->DeleteLayer( $inCAM, $jobId, $plgTop );
	CamMatrix->DeleteLayer( $inCAM, $jobId, $plgBot );

	CamMatrix->CreateLayer( $inCAM, $jobId, $plgTop, "via_plug", "positive", 1, "c", "before" );

	my $sExist = CamHelper->LayerExists( $inCAM, $jobId, "s" );
	CamMatrix->CreateLayer( $inCAM, $jobId, $plgBot, "via_plug", "positive", 1, ( $sExist ? "s" : "" ), "after" );

	foreach my $l ( CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nFillDrill ) ) {

		CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
		CamLayer->CopySelOtherLayer( $inCAM, [ $plgTop, $plgBot ], 0, 2 * $annularRing );
	}

	foreach my $l ( CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop ) ) {

		CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
		CamLayer->CopySelOtherLayer( $inCAM, [$plgTop], 0, 2 * $annularRing );
	}

	foreach my $l ( CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot ) ) {

		CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
		CamLayer->CopySelOtherLayer( $inCAM, [$plgBot], 0, 2 * $annularRing );
	}

	CamLayer->ClearLayers($inCAM);
	
	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::ViaFilling::PlugLayer';
	use aliased 'CamHelpers::CamDrilling';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d243758";

	my $mess = "";

	if ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) ) {

		my $result = PlugLayer->CreateCopperPlugLayers( $inCAM, $jobId );

	}
  
}

1;
