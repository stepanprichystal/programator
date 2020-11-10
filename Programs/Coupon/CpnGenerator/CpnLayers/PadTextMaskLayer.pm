
#-------------------------------------------------------------------------------------------#
# Description: Layer builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::PadTextMaskLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

use Class::Interface;
&implements('Programs::Coupon::CpnGenerator::CpnLayers::ILayerBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Coupon::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $drawPriority = 2;
	my $self  = $class->SUPER::new(@_, $drawPriority);
	bless $self;

	return $self;
}

sub Build {
	my $self            = shift;
	my $layout          = shift;    # microstrip layout
	my $cpnSingleLayout = shift;    # cpn single layout
	my $layerLayout     = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

 
	foreach my $pad ( $layout->GetPads() ) {

		if ( $pad->GetType() eq Enums->Pad_TRACK) {

			my $padText = $pad->GetPadText();

			next unless ( defined $padText );    # only multistrips has texts

			next unless($padText->GetPadTextUnmask());

			my $pText = PrimitiveText->new(
											$padText->GetText(),
											( $layerLayout->GetMirror() ? $padText->GetPositionMirror() : $padText->GetPosition() ),
											$padText->GetPadTextHeight() / 1000,
											$padText->GetPadTextWidth() / 1000,
											$padText->GetPadTextWeight() / 1000,
											( $layerLayout->GetMirror() ? 1 : 0 )
			);

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

