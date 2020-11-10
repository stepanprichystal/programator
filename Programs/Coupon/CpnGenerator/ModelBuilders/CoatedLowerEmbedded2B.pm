
#-------------------------------------------------------------------------------------------#
# Description: Coated upper embedded builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::ModelBuilders::CoatedLowerEmbedded2B;
use base('Programs::Coupon::CpnGenerator::ModelBuilders::CoatedLowerEmbedded');

use Class::Interface;
&implements('Programs::Coupon::CpnGenerator::ModelBuilders::IModelBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::MaskLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::TrackLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::TrackClearanceLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::GNDLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::PadLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::PadNegLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::PthDrillLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::PadTextLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::PadTextMaskLayer';
use aliased 'Programs::Coupon::Helper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {
	my $self            = shift;
	my $layout          = shift;
	my $cpnSingleLayout = shift;
	my $layersLayout    = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Build Coated microstrip
	$self->SUPER::Build( $layout, $cpnSingleLayout, $layersLayout );

	# 2) Buil special behaviour

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	my $extraTrackL = $layout->GetExtraTrackLayer();

	for ( my $i = 0 ; $i < scalar( $layerCnt - 2 ) ; $i++ ) {

		my $inLayer = "v" . ( $i + 2 );

		if ( $extraTrackL eq $inLayer ) {

			$self->_AddLayer( TrackClearanceLayer->new($inLayer) );
		}
	}

	$self->_Build( $layout, $cpnSingleLayout, $layersLayout );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

