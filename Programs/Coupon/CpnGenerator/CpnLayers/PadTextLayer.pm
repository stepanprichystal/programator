
#-------------------------------------------------------------------------------------------#
# Description: Layer builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::PadTextLayer;

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
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $drawPriority = 4;
	my $self  = $class->SUPER::new(@_, $drawPriority);
	bless $self;

	return $self;
}

sub Build {
	my $self            = shift;
	my $layout          = shift;    # microstrip layout
	my $cpnSingleLayout = shift;    # cpn single layout
	my $layerLayout     = shift;	# layer layout


	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $pad ( $layout->GetPads() ) {

		if ( $pad->GetType() eq Enums->Pad_TRACK ) {

			my $padText = $pad->GetPadText();

			return unless ( defined $padText );    # only multistrips has texts

			# clearance in copper (put negative square)

			my $origin = ( $layerLayout->GetMirror() ? $padText->GetNegRectPositionMirror() : $padText->GetNegRectPosition() );

			my @points = ();
			push( @points, Point->new( $origin->X(),                           $origin->Y() ) );
			push( @points, Point->new( $origin->X(),                           $origin->Y() + $padText->GetNegRectH() ) );
			push( @points, Point->new( $origin->X() + $padText->GetNegRectW(), $origin->Y() + $padText->GetNegRectH() ) );
			push( @points, Point->new( $origin->X() + $padText->GetNegRectW(), $origin->Y() ) );
			push( @points, Point->new( $origin->X(),                           $origin->Y() ) );

			my $pTextNeg = PrimitiveSurfPoly->new(
				\@points,
				undef,
				$self->_InvertPolar(DrawEnums->Polar_NEGATIVE, $layerLayout)

			);

			$self->{"drawing"}->AddPrimitive($pTextNeg);

			# Add text pad
			my $pText = PrimitiveText->new(
											$padText->GetText(),
											( $layerLayout->GetMirror() ? $padText->GetPositionMirror() : $padText->GetPosition() ),
											$padText->GetPadTextHeight() / 1000,
											$padText->GetPadTextWidth() / 1000,
											$padText->GetPadTextWeight() / 1000,
											( $layerLayout->GetMirror() ? 1 : 0 ),
											undef,
											$self->_InvertPolar(DrawEnums->Polar_POSITIVE, $layerLayout)
											
			);
			
			$pText->AddAttribute(".n_electric");

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

