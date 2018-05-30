#-------------------------------------------------------------------------------------------#
# Description: Helper function for data prepare to output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Stackup::Stackup';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub GetLayerName {
	my $self         = shift;
	my $inStackLayer = shift;
	my $xmlParser    = shift;

	my $layerCnt = scalar( $xmlParser->findnodes('/document/interfacelist/JOB/COPPER_LAYERS/COPPER_LAYER') );

	# load copper layers
	my $l = ( grep { $_->{"NAME"} =~ /$inStackLayer/ } $xmlParser->findnodes('/document/interfacelist/JOB/COPPER_LAYERS/COPPER_LAYER') )[0];

	my $lCam = undef;
	if ( $l->{"LAYER_INDEX"} == 1 ) {

		$lCam = "c";

	}
	elsif ( $l->{"LAYER_INDEX"} == $layerCnt ) {

		$lCam = "s";

	}
	else {

		$lCam = "v" . $l->{"LAYER_INDEX"};
	}

	return $lCam;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

