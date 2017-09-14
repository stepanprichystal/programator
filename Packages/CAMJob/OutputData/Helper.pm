#-------------------------------------------------------------------------------------------#
# Description: Helper function for data prepare to output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamFilter';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return affected features (cutted) by reference layer (eg. goldc, lc, gc, etc,..)
# And mas if exist and if is requested
sub FeaturesByRefLayer {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $featsL = shift;    # requested layer with features
	my $refL   = shift;    # (eg. goldc, lc, gc, etc,..)
	my $maskL  = shift;    # mask layer (often mc, ms)
	my $lim    = shift;    # area which is processed and result is only fro this area

	my $refLayer = undef;  # default reference layers is gold[m/c]

	# if exist mask too, do intersection between gold and mask layers
	if ( $maskL && CamHelper->LayerExists( $inCAM, $jobId, $maskL ) ) {

		$refLayer = CamLayer->LayerIntersection( $inCAM, $refL, $maskL, $lim );
		CamLayer->Contourize( $inCAM, $refLayer );

	}
	else {

		$refLayer = GeneralHelper->GetGUID();
		$inCAM->COM( "merge_layers", "source_layer" => $refL, "dest_layer" => $refLayer );
	}

	# Do intersection between Gold layer (tmp $goldRef) and selected goldfinegr (tmp $cuGoldFinger)
	my $resultL = CamLayer->LayerIntersection( $inCAM, $refLayer, $featsL, $lim );
	CamLayer->Contourize( $inCAM, $resultL );
	$inCAM->COM( "delete_layer", "layer" => $refLayer );

	return $resultL;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

