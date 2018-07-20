
#-------------------------------------------------------------------------------------------#
# Description: Uncoated microstrip builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::ModelBuilders::UncoatedMicrostrip;
use base('Programs::Coupon::CpnGenerator::ModelBuilders::CoatedMicrostrip');

use Class::Interface;
&implements('Programs::Coupon::CpnGenerator::ModelBuilders::IModelBuilder');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Programs::Coupon::CpnGenerator::CpnLayers::TrackMaskLayer';
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

	# Info from constrain XML
	my $trackL = $layout->GetTrackLayer();
	my $gndL   = $layout->GetBotRefLayer();

	my $layerCnt = scalar( grep { $_ =~ /[csv]\d*/i } keys %{$layersLayout} );

	# Track layer can has index 1,2 or layer cnt, layer cnt -1
	# (standard microstrip and embedded upper/lower)
	my $layerNum = Helper->GetLayerNum( $trackL, $layerCnt );

	# process: mc
	if ( $layerNum == 1 ) {
		$self->_AddLayer( TrackMaskLayer->new("mc") );

		if ( CamHelper->LayerExists( $inCAM, $jobId, "mc" ) ) {

			if ( $trackL eq "c" ) {
				$self->_AddLayer( TrackMaskLayer->new("mc") );
			}
		}
	}

	# process: ms
	if ( $layerNum == $layerCnt ) {
		$self->_AddLayer( TrackMaskLayer->new("ms") );

		if ( CamHelper->LayerExists( $inCAM, $jobId, "ms" ) ) {

			if ( $trackL eq "s" ) {
				$self->_AddLayer( TrackMaskLayer->new("ms") );
			}
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

