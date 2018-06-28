
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnGenerator::CpnLayers::ShieldingLayer;

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
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {
	my $self   = shift;
	my $layout = shift;    # microstrip layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# add "break line" before shieldning filling which prevent to fill area where is place info text
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	if ( $self->{"settings"}->GetCpnSingleWidth() < $lim{"xMax"} ) {
		my @coord = ();
		push( @coord, Point->new( $self->{"settings"}->GetCpnSingleWidth(), 0 ) );
		push( @coord, Point->new( $self->{"settings"}->GetCpnSingleWidth(), $lim{"yMax"} ) );
		push( @coord, Point->new( $lim{"xMax"},                             $lim{"yMax"} ) );
		push( @coord, Point->new( $lim{"xMax"},                             0 ) );

		$self->{"drawing"}->AddPrimitive( PrimitiveSurfPoly->new( \@coord, undef, DrawEnums->Polar_NEGATIVE ) );
	}

	# add surface fill
	if ( $layout->GetType() eq "solid" ) {

		my $solidPattern = SurfaceSolidPattern->new( 0, 0 );

		$self->{"drawing"}->AddPrimitive( PrimitiveSurfFill->new( $solidPattern, 0, 0, 0, 0, 1, 0, DrawEnums->Polar_POSITIVE ) );

	}elsif($layout->GetType() eq "symbol"){
		
 
		my $symbolPattern = SurfaceSymbolPattern->new( 0, 0, 0, $layout->GetSymbol(), $layout->GetSymbolDX(), $layout->GetSymbolDY() );

		$self->{"drawing"}->AddPrimitive( PrimitiveSurfFill->new( $symbolPattern, 0, 0, 0, 0, 1, 0, DrawEnums->Polar_POSITIVE ) );
		
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

