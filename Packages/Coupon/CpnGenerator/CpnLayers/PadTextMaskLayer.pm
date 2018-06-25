
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

sub Draw {
	my $self   = shift;
	my $layout = shift;    # microstrip layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( $self->{"layerName"} ne "c" && $self->{"layerName"} ne "s" ) {
		die "Track pad text can be put only to layer c,s";
	}
	
	return if (!$self->{"settings"}->GetPadTextUnmask);

	foreach my $pad ( $layout->GetPads() ) {

		if ( $pad->GetType() eq Enums->Pad_TRACK && $self->{"settings"}->GetPadText() ) {

			my $padText = $pad->GetPadText();

			my $mirror = $self->{"layerName"} eq "c" ? 0 : 1;

			my $pText = PrimitiveText->new( $padText->GetText(), ($self->{"layerName"} eq "c" ? $padText->GetPosition() : $padText->GetPositionMirror()),
											$self->{"settings"}->GetPadTextHeight(),
											$self->{"settings"}->GetPadTextWidth(),
											$self->{"settings"}->GetPadTextWeight()+ $self->{"settings"}->GetPadTextClearance()*2/1000, ($self->{"layerName"} eq "c" ? 0 : 1) );
 
			$self->{"drawing"}->AddPrimitive($pText);
		}
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

