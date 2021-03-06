
#-------------------------------------------------------------------------------------------#
# Description: Layer builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::InfoTextLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

use Class::Interface;
&implements('Programs::Coupon::CpnGenerator::CpnLayers::ILayerBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';

use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Coupon::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $drawPriority = 15;
	my $self  = $class->SUPER::new(@_, $drawPriority);
	bless $self;

	return $self;
}

sub Build {
	my $self   = shift;
	my $layout = shift;    # info text layout
	my $cpnSingleLayout = shift;    # cpn single layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $origin = $layout->GetPosition();

	# draw clearance
	my $textH = $layout->GetHeight();
	my $textW = $layout->GetWidth();

	my @points = ();
	push( @points, Point->new( $origin->X() - 0.2,          $origin->Y() - 0.2 ) );
	push( @points, Point->new( $origin->X() - 0.2,          $origin->Y() + $textH + 0.2 ) );
	push( @points, Point->new( $origin->X() + 0.2 + $textW, $origin->Y() + $textH + 0.2 ) );
	push( @points, Point->new( $origin->X() + 0.2 + $textW, $origin->Y() - 0.2 ) );
	push( @points, Point->new( $origin->X() - 0.2,          $origin->Y() - 0.2 ) );

	my $pTextNeg = PrimitiveSurfPoly->new(
		\@points,
		undef,
		DrawEnums->Polar_NEGATIVE

	);

	$self->{"drawing"}->AddPrimitive($pTextNeg);

	# draw texts

	foreach my $text ( $layout->GetTexts() ) {

		my $p = Point->new( $text->{"point"}->X() + $origin->X(), $text->{"point"}->Y() + $origin->Y() );
		my $pText = PrimitiveText->new( $text->{"val"}, $p,
										$layout->GetInfoTextHeight()/1000,
										$layout->GetInfoTextWidth()/1000,
										$layout->GetInfoTextWeight()/1000 );

		$pText->AddAttribute(".n_electric");

		$self->{"drawing"}->AddPrimitive($pText);

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

