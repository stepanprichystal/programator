
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::InfoTextLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

#use Class::Interface;
#&implements('Programs::Coupon::CpnBuilder::MicrostripBuilders::IModelBuilder');

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
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {
	my $self   = shift;
	my $layout = shift;    # microstrip layout

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
										$self->{"settings"}->GetInfoTextHeight()/1000,
										$self->{"settings"}->GetInfoTextWidth()/1000,
										$self->{"settings"}->GetInfoTextWeight()/1000 );

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

