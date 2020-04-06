
#-------------------------------------------------------------------------------------------#
# Description: Layer builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::GNDViaShieldingLayer;

use base('Programs::Coupon::CpnGenerator::CpnLayers::LayerBase');

use Class::Interface;
&implements('Programs::Coupon::CpnGenerator::CpnLayers::ILayerBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePolyline';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';


use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Coupon::Enums';
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

sub Build {
	my $self   = shift;
	my $layout = shift;    # microstrip layout
	my $cpnSingleLayout = shift;    # cpn single layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# drav GND via holes
	my $shieldingLayout = $cpnSingleLayout->GetShieldingGNDViaLayout();
	 
	
	foreach my $hole ( $layout->GetGNDViaPoints() ) {

 		$self->{"drawing"}->AddPrimitive(PrimitivePad->new( "r".$shieldingLayout->GetGNDViaHoleSize(), $hole ));
	}
 
  
 	 

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

