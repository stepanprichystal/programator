
#-------------------------------------------------------------------------------------------#
# Description: Uncoated  upper embedded microstrip builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::ModelBuilders::UncoatedUpperEmbedded;
use base('Programs::Coupon::CpnGenerator::ModelBuilders::CoatedUpperEmbedded');

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

	# process: mc
	if ( Helper->GetLayerNum( $trackL, $layerCnt ) == 2 ) {
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

	$self->_Build( $layout, $cpnSingleLayout, $layersLayout );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

