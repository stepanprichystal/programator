
#-------------------------------------------------------------------------------------------#
# Description: Stripline model builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::ModelBuilders::Stripline;
use base('Programs::Coupon::CpnGenerator::ModelBuilders::ModelBuilderBase');

use Class::Interface;
&implements('Programs::Coupon::CpnGenerator::ModelBuilders::IModelBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::MaskLayer';
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::TrackLayer';
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

	# translate InStack layer name to InCAM layer name

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	# Info from constrain XML
	my $trackL  = $layout->GetTrackLayer();
	my $gndTopL = $layout->GetTopRefLayer();
	my $gndBotL = $layout->GetBotRefLayer();

	# Build coupon layers

	# process: mc
	if ( CamHelper->LayerExists( $inCAM, $jobId, "mc" ) ) {

		$self->_AddLayer( MaskLayer->new("mc") );
		$self->_AddLayer( PadTextMaskLayer->new("mc") );
	}

	# process: c
	$self->_AddLayer( PadTextLayer->new("c") );

	if ( $gndTopL eq "c" || $gndBotL eq "c" ) {

		$self->_AddLayer( GNDLayer->new("c") );

	}
	else {

		$self->_AddLayer( PadLayer->new("c") );
	}

	for ( my $i = 0 ; $i < scalar( $layerCnt - 2 ) ; $i++ ) {

		my $inLayer = "v" . ( $i + 2 );

		if ( $trackL eq $inLayer ) {

			$self->_AddLayer( PadTextLayer->new($inLayer) );
			$self->_AddLayer( TrackLayer->new($inLayer) );
		}
		elsif ( $gndTopL eq $inLayer || $gndBotL eq $inLayer ) {

			$self->_AddLayer( GNDLayer->new($inLayer) );
		}
		else {
			$self->_AddLayer( PadNegLayer->new($inLayer) );
		}

	}

	# process: s
	$self->_AddLayer( PadTextLayer->new("s") );

	if ( $gndTopL eq "s" || $gndBotL eq "s" ) {

		$self->_AddLayer( GNDLayer->new("s") );
	}
	else {

		$self->_AddLayer( PadLayer->new("s") );

	}

	# process: ms
	if ( CamHelper->LayerExists( $inCAM, $jobId, "ms" ) ) {

		$self->_AddLayer( MaskLayer->new("ms") );
		$self->_AddLayer( PadTextMaskLayer->new("ms") );
	}

	# process: m
	$self->_AddLayer( PthDrillLayer->new("m") );

	$self->_Build( $layout, $cpnSingleLayout, $layersLayout );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

