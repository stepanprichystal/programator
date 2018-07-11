
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::MaskLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

#use Class::Interface;
#&implements('Programs::Coupon::CpnBuilder::MicrostripBuilders::IModelBuilder');

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
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {
	my $self   = shift;
	my $layout = shift;    # microstrip layout
	my $cpnSingleLayout = shift;    # cpn single layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# umask all gnd and track pads

	foreach my $pad ( $layout->GetPads() ) {

		my $symClear = undef;

		if ( $pad->GetType() eq Enums->Pad_GND ) {

			$symClear = $cpnSingleLayout->GetPadGNDShape() . ( $cpnSingleLayout->GetPadGNDSize() + $self->{"settings"}->GetPadClearance() );
		}
		else {

			$symClear = $cpnSingleLayout->GetPadTrackShape() . ( $cpnSingleLayout->GetPadTrackSize() + $self->{"settings"}->GetPadClearance() );
		}

		my $pad = PrimitivePad->new( $symClear, $pad->GetPoint() );

		$self->{"drawing"}->AddPrimitive($pad);
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

