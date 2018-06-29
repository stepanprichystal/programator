
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnGenerator::CpnLayers::PadTextMaskLayer;

use base('Packages::Coupon::CpnGenerator::CpnLayers::LayerBase');

#use Class::Interface;
#&implements('Packages::Coupon::CpnBuilder::MicrostripBuilders::IModelBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::Coupon::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';

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

 
	return if (!$self->{"settings"}->GetPadTextUnmask);

	foreach my $pad ( $layout->GetPads() ) {

		if ( $pad->GetType() eq Enums->Pad_TRACK && $self->{"settings"}->GetPadText() ) {

			my $padText = $pad->GetPadText();

			my $mirror = $self->{"layerName"} eq "mc" ? 0 : 1;

			my $pText = PrimitiveText->new( $padText->GetText(), ($self->{"layerName"} eq "mc" ? $padText->GetPosition() : $padText->GetPositionMirror()),
											$self->{"settings"}->GetPadTextHeight()/1000,
											$self->{"settings"}->GetPadTextWidth()/1000,
											$self->{"settings"}->GetPadTextWeight()/1000 , ($self->{"layerName"} eq "mc" ? 0 : 1) );
 
			$self->{"drawing"}->AddPrimitive($pText);
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

