
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::PadNegLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

#use Class::Interface;
#&implements('Programs::Coupon::CpnBuilder::MicrostripBuilders::IModelBuilder');

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
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {
	my $self   = shift;
	my $layout = shift;    # microstrip layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# drav GND and track pads
	foreach my $pad ( $layout->GetPads() ) {

		my $symClearance = undef;

		if ( $pad->GetType() eq Enums->Pad_GND ) {

			my $shareGNDLayers = $pad->GetShareGndLayers();

			if ( !$shareGNDLayers->{ $self->{"layerName"} } ) {

				$symClearance =
				  $self->{"settings"}->GetPadGNDShape() . ( $self->{"settings"}->GetPadGNDSize() + $self->{"settings"}->GetPad2GNDClearance() );
				$self->{"drawing"}->AddPrimitive( PrimitivePad->new( $symClearance, $pad->GetPoint(), 0, DrawEnums->Polar_NEGATIVE ) );

			}
		}
		else {

			$symClearance =
			  $self->{"settings"}->GetPadTrackShape() . ( $self->{"settings"}->GetPadTrackSize() + $self->{"settings"}->GetPad2GNDClearance() );
			$self->{"drawing"}->AddPrimitive( PrimitivePad->new( $symClearance, $pad->GetPoint(), 0, DrawEnums->Polar_NEGATIVE ) );
		}

	}

	# Draw to layer
	#$self->_Draw();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

