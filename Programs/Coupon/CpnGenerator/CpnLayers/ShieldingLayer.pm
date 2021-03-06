
#-------------------------------------------------------------------------------------------#
# Description: Layer builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::ShieldingLayer;

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

use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfFill';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSolidPattern';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSymbolPattern';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $drawPriority = 13;
	my $self  = $class->SUPER::new(@_, $drawPriority);
	bless $self;

	return $self;
}

sub Build {
	my $self   = shift;
	my $layout = shift;    # microstrip layout
	my $cpnSingleLayout = shift;    # cpn single layout
	my $layerLayout     = shift;	# layer layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# add "break line" before shieldning filling which prevent to fill area where is place info text
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	if ( $cpnSingleLayout->GetCpnSingleWidth() < $lim{"xMax"} ) {
		my @coord = ();
		push( @coord, Point->new( $cpnSingleLayout->GetCpnSingleWidth(), 0 ) );
		push( @coord, Point->new( $cpnSingleLayout->GetCpnSingleWidth(), $lim{"yMax"} ) );
		push( @coord, Point->new( $lim{"xMax"},                             $lim{"yMax"} ) );
		push( @coord, Point->new( $lim{"xMax"},                             0 ) );
		push( @coord, Point->new( $cpnSingleLayout->GetCpnSingleWidth(), 0 ) );

		$self->{"drawing"}->AddPrimitive( PrimitiveSurfPoly->new( \@coord, undef, $self->_InvertPolar(DrawEnums->Polar_NEGATIVE, $layerLayout) ) );
	}

	# add surface fill
	if ( $layout->GetType() eq "solid" ) {

		my $solidPattern = SurfaceSolidPattern->new( 0, 0 );

		$self->{"drawing"}->AddPrimitive( PrimitiveSurfFill->new( $solidPattern, 0, 0, 0, 0, 1, 0, $self->_InvertPolar(DrawEnums->Polar_POSITIVE, $layerLayout) ) );

	}elsif($layout->GetType() eq "symbol"){
		
 
		my $symbolPattern = SurfaceSymbolPattern->new( 0, 0, 0, $layout->GetSymbol(), $layout->GetSymbolDX(), $layout->GetSymbolDY() );

		$self->{"drawing"}->AddPrimitive( PrimitiveSurfFill->new( $symbolPattern, 0, 0, 0, 0, 1, 0, $self->_InvertPolar(DrawEnums->Polar_POSITIVE, $layerLayout) ) );
		
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

