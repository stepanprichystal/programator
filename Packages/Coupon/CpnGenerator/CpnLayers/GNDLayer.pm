
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnGenerator::CpnLayers::GNDLayer;

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

sub Draw {
	my $self   = shift;
	my $layout = shift;    # microstrip layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$inCAM->COM(
				 "sr_fill",
				 "type"          => "solid",
				 "solid_type"    => "surface",
				 "step_margin_x" => "0",
				 "step_margin_y" => "0",
				 "consider_feat" => "yes",
				 "feat_margin"   => "0",
				 "dest"          => "layer_name",
				 "layer"         => $self->{"layerName"}
	);

	# drav GND  pads
	foreach my $pad ( grep { $_->GetType() eq Enums->Pad_GND } $layout->GetPads() ) {

		$self->{"drawing"}
		  ->AddPrimitive( PrimitivePad->new( $self->{"settings"}->GetPadGNDSymNeg(), $pad->GetPoint(), 0, DrawEnums->Polar_NEGATIVE ) );
	}

	# drav track pads
	foreach my $pad ( grep { $_->GetType() eq Enums->Pad_TRACK } $layout->GetPads() ) {

		my $symClearance =
		  $self->{"settings"}->GetPadTrackShape() . ( $self->{"settings"}->GetPadTrackSize() + $self->{"settings"}->GetPad2GNDClearance() );
		$self->{"drawing"}->AddPrimitive( PrimitivePad->new( $symClearance, $pad->GetPoint(), 0, DrawEnums->Polar_NEGATIVE ) );
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

