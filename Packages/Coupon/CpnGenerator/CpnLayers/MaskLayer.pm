
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnGenerator::CpnLayers::MaskLayer;

use base('Packages::Coupon::CpnGenerator::CpnLayers::LayerBase');

#use Class::Interface;
#&implements('Packages::Coupon::CpnBuilder::MicrostripBuilders::IModelBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::Coupon::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePolyline';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Draw {
	my $self   = shift;
	my $layout = shift;    # microstrip layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# umask all gnd and track pads

	foreach my $pad ( $layout->GetPads() ) {

		my $symClear = undef;

		if ( $pad->GetType() eq Enums->Pad_GND ) {

			$symClear = $self->{"settings"}->GetPadGNDShape() . ( $self->{"settings"}->GetPadGNDSize() + $self->{"settings"}->GetPadClearance() );
		}
		else {

			$symClear = $self->{"settings"}->GetPadTrackShape() . ( $self->{"settings"}->GetPadTrackSize() + $self->{"settings"}->GetPadClearance() );
		}

		my $pad = PrimitivePad->new( $symClear, $pad->GetPoint() );

		$self->{"drawing"}->AddPrimitive($pad);
	}

	# Draw to layer
	$self->_Draw();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

