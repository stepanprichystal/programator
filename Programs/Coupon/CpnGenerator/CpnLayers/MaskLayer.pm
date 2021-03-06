
#-------------------------------------------------------------------------------------------#
# Description: Layer builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::MaskLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

use Class::Interface;
&implements('Programs::Coupon::CpnGenerator::CpnLayers::ILayerBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Coupon::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePolyline';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $drawPriority = 1;
	my $self  = $class->SUPER::new(@_, $drawPriority);
	bless $self;

	return $self;
}

sub Build {
	my $self            = shift;
	my $layout          = shift;    # microstrip layout
	my $cpnSingleLayout = shift;    # cpn single layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# umask all gnd and track pads

	foreach my $pad ( $layout->GetPads() ) {

		my $symClear = undef;

		if ( $pad->GetType() eq Enums->Pad_GND ) {

			$symClear = $cpnSingleLayout->GetPadGNDShape() . ( $cpnSingleLayout->GetPadGNDSize() + $layout->GetPadClearance() );
		}
		else {

			$symClear = $cpnSingleLayout->GetPadTrackShape() . ( $cpnSingleLayout->GetPadTrackSize() + $layout->GetPadClearance() );
		}

		my $pad = PrimitivePad->new( $symClear, $pad->GetPoint() );

		$self->{"drawing"}->AddPrimitive($pad);
	}

	# Drav GND via holes pad

	if ( $layout->GetCoplanar() ) {
		my $shieldingLayout = $cpnSingleLayout->GetShieldingGNDViaLayout();

		if ( defined $shieldingLayout && $shieldingLayout->GetUnMaskGNDVia() ) {
			foreach my $hole ( $layout->GetGNDViaPoints() ) {

				$self->{"drawing"}->AddPrimitive(
					   PrimitivePad->new( "r" . ( 2 * $shieldingLayout->GetGNDViaHoleRing() + $shieldingLayout->GetGNDViaHoleSize() + 80 ), $hole ) );
			}
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

