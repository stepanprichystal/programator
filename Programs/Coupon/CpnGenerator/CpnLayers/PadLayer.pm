
#-------------------------------------------------------------------------------------------#
# Description: Layer builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::PadLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

use Class::Interface;
&implements('Programs::Coupon::CpnGenerator::CpnLayers::ILayerBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePolyline';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';

use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Coupon::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $drawPriority = 8;
	my $self  = $class->SUPER::new(@_, $drawPriority);
	bless $self;

	return $self;
}

sub Build {
	my $self            = shift;
	my $layout          = shift;    # microstrip layout
	my $cpnSingleLayout = shift;    # cpn single layout
	my $layerLayout     = shift;    # layer layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# drav GND and track pads
	foreach my $pad ( $layout->GetPads() ) {
		if ( $pad->GetType() eq Enums->Pad_GND ) {

			my $shareGNDLayers = $pad->GetShareGndLayers();

			if ( !$shareGNDLayers->{ $self->{"layerName"} } ) {

				my $symClearance =
				  $cpnSingleLayout->GetPadGNDShape() . ( $cpnSingleLayout->GetPadGNDSize() + 2 * $layout->GetPad2GND() );
				my $symPad = $cpnSingleLayout->GetPadGNDSym();
				$self->{"drawing"}->AddPrimitive(
							PrimitivePad->new( $symClearance, $pad->GetPoint(), 0, $self->_InvertPolar( DrawEnums->Polar_NEGATIVE, $layerLayout ) ) );
				$self->{"drawing"}
				  ->AddPrimitive( PrimitivePad->new( $symPad, $pad->GetPoint(), 0, $self->_InvertPolar( DrawEnums->Polar_POSITIVE, $layerLayout ) ) );
			}
		}
		else {

			my $symClearance =
			  $cpnSingleLayout->GetPadTrackShape() . ( $cpnSingleLayout->GetPadTrackSize() + 2 * $layout->GetPad2GND() );
			my $symPad = $cpnSingleLayout->GetPadTrackSym();
			$self->{"drawing"}->AddPrimitive(
							PrimitivePad->new( $symClearance, $pad->GetPoint(), 0, $self->_InvertPolar( DrawEnums->Polar_NEGATIVE, $layerLayout ) ) );
			$self->{"drawing"}
			  ->AddPrimitive( PrimitivePad->new( $symPad, $pad->GetPoint(), 0, $self->_InvertPolar( DrawEnums->Polar_POSITIVE, $layerLayout ) ) );
		}

	}

	 
 

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

