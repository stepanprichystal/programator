
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb POOL
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnGenerator::ModelBuilders::Uncoated;
use base('Packages::Coupon::CpnGenerator::ModelBuilders::Coated');

use Class::Interface;
&implements('Packages::Coupon::CpnGenerator::ModelBuilders::IModelBuilder');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Coupon::CpnGenerator::CpnLayers::TrackMaskLayer';
use aliased 'Packages::Coupon::Helper';
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
	my $self         = shift;
	my $layout       = shift;
	my $layersLayout = shift;
	my $inCAM        = $self->{"inCAM"};
	my $jobId        = $self->{"jobId"};

	# 1) Build Coated microstrip
	$self->SUPER::Build( $layout, $layersLayout );

	# 2) Buil special behaviour

	# Info from constrain XML
	my $trackL = $layout->GetTrackLayer();
	my $gndL   = $layout->GetBotRefLayer();

	my $layerCnt = scalar( grep { $_ =~ /[csv]\d*/i } keys %{$layersLayout} );

	# process: mc
	if ( Helper->GetLayerNum( $trackL, $layerCnt ) == 2 )
	{
		$self->_AddLayer( TrackMaskLayer->new("mc") );

		if ( CamHelper->LayerExists( $inCAM, $jobId, "mc" ) ) {

			if ( $trackL eq "c" ) {
				$self->_AddLayer( TrackMaskLayer->new("mc") );
			}
		}
	}

	# process: ms
	if ( Helper->GetLayerNum( $trackL, $layerCnt ) == $layerCnt - 1 ) {
		$self->_AddLayer( TrackMaskLayer->new("ms") );

		if ( CamHelper->LayerExists( $inCAM, $jobId, "ms" ) ) {

			if ( $trackL eq "s" ) {
				$self->_AddLayer( TrackMaskLayer->new("ms") );
			}
		}
	}

	$self->_Build( $layout, $layersLayout );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

