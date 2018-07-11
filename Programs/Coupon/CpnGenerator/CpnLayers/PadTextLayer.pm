
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::PadTextLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

#use Class::Interface;
#&implements('Programs::Coupon::CpnBuilder::MicrostripBuilders::IModelBuilder');

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
	my $self  = $class->SUPER::new(@_);
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

			my $pTextNeg = PrimitiveSurfPoly->new(
				\@points,
				undef,
				DrawEnums->Polar_NEGATIVE

			);

			$self->{"drawing"}->AddPrimitive($pTextNeg);

			# Add text pad
			my $pText = PrimitiveText->new(
											$padText->GetText(),
											( $layerLayout->GetMirror() ? $padText->GetPositionMirror() : $padText->GetPosition() ),
											$layout->GetPadTextHeight() / 1000,
											$layout->GetPadTextWidth() / 1000,
											$layout->GetPadTextWeight() / 1000,
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

