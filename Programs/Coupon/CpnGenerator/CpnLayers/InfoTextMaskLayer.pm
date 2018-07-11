
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::InfoTextMaskLayer;

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
	my $layout = shift;    # info text layout
	my $cpnSingleLayout = shift;    # cpn single layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	return if (!$layout->GetInfoTextUnmask());

	my $origin = $layout->GetPosition();

	# draw clearance
 
 
	foreach my $text ( $layout->GetTexts() ) {

		my $p = Point->new( $text->{"point"}->X() + $origin->X(), $text->{"point"}->Y() + $origin->Y() );
		my $pText = PrimitiveText->new( $text->{"val"}, $p,
										$layout->GetInfoTextHeight()/1000,
										$layout->GetInfoTextWidth()/1000,
										$layout->GetInfoTextWeight()/1000 + 0.1,
										0,0, DrawEnums->Polar_POSITIVE);

		$self->{"drawing"}->AddPrimitive($pText);

	}

	# Draw to layer
 

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

