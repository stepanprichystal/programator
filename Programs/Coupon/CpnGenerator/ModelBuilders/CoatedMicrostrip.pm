
#-------------------------------------------------------------------------------------------#
# Description: Coated microstrip builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::ModelBuilders::CoatedMicrostrip;
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
use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::GNDViaShieldingLayer';
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
	my $trackL = $layout->GetTrackLayer();
	my $gndL   = $layout->GetBotRefLayer();

	# Build coupon layers

	# process: mc
	if ( CamHelper->LayerExists( $inCAM, $jobId, "mc" ) ) {

		$self->_AddLayer( MaskLayer->new("mc") );
		$self->_AddLayer( PadTextMaskLayer->new("mc") );
	}

	# process: c
	$self->_AddLayer( PadTextLayer->new("c") );

	if ( $trackL eq "c" ) {

		$self->_AddLayer( TrackLayer->new("c") );
	}
	else {

		$self->_AddLayer( PadLayer->new("c") );
	}

	for ( my $i = 0 ; $i < scalar( $layerCnt - 2 ) ; $i++ ) {

		my $inLayer = "v" . ( $i + 2 );

		if ( $gndL eq $inLayer ) {

			$self->_AddLayer( GNDLayer->new($inLayer) );
		}
		else {
			$self->_AddLayer( PadNegLayer->new($inLayer) );
		}

	}

	# process: s

	$self->_AddLayer( PadTextLayer->new("s") );
	if ( $trackL eq "s" ) {

		$self->_AddLayer( TrackLayer->new("s") );
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

	# Process coplanar via hole (drill hole + annular ring)
	if ( $layout->GetCoplanar() ) {

		my $shieldingGNDVia = $cpnSingleLayout->GetShieldingGNDViaLayout();
		if ( defined $shieldingGNDVia ) {

			# Drill hole
			if ( $shieldingGNDVia->GetFilledGNDVia() ) {
				$self->_AddLayer( GNDViaShieldingLayer->new("mfill") );
			}
			else {
				$self->_AddLayer( GNDViaShieldingLayer->new("m") );
			}

			# Anunular ring
			$self->_AddLayer( GNDViaShieldingLayer->new("c") );
			$self->_AddLayer( GNDViaShieldingLayer->new("s") );

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

