
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::GNDLayer;

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
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfFill';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSolidPattern';
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
	my $self            = shift;
	my $layout          = shift;    # microstrip layout
	my $cpnSingleLayout = shift;    # cpn single layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# add "break line" before GND filling which prevent to fill area where is place info text
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	if ( $layout->GetCpnSingleWidth() < $lim{"xMax"} ) {
		my @coord = ();
		push( @coord, Point->new( $layout->GetCpnSingleWidth(), 0 ) );
		push( @coord, Point->new( $layout->GetCpnSingleWidth(), $lim{"yMax"} ) );
		push( @coord, Point->new( $lim{"xMax"},                             $lim{"yMax"} ) );
		push( @coord, Point->new( $lim{"xMax"},                             0 ) );

		$self->{"drawing"}->AddPrimitive( PrimitiveSurfPoly->new( \@coord, undef, DrawEnums->Polar_NEGATIVE ) );
	}

	# add surface fill
	my $solidPattern = SurfaceSolidPattern->new( 0, 0 );

	$self->{"drawing"}->AddPrimitive( PrimitiveSurfFill->new( $solidPattern, 0, 0, 0, 0, 1, 0, DrawEnums->Polar_POSITIVE ) );

	# drav GND  pads
	foreach my $pad ( grep { $_->GetType() eq Enums->Pad_GND } $layout->GetPads() ) {

		$self->{"drawing"}
		  ->AddPrimitive( PrimitivePad->new( $cpnSingleLayout->GetPadGNDSymNeg(), $pad->GetPoint(), 0, DrawEnums->Polar_NEGATIVE ) );
	}

	# drav track pads
	foreach my $pad ( grep { $_->GetType() eq Enums->Pad_TRACK } $layout->GetPads() ) {

		my $symClearance =
		  $cpnSingleLayout->GetPadTrackShape() . ( $cpnSingleLayout->GetPadTrackSize() + $layout->GetPad2GND() );
		$self->{"drawing"}->AddPrimitive( PrimitivePad->new( $symClearance, $pad->GetPoint(), 0, DrawEnums->Polar_NEGATIVE ) );

		if ( $self->{"layerName"} !~ /v\d+/ ) {
			$self->{"drawing"}
			  ->AddPrimitive( PrimitivePad->new( $cpnSingleLayout->GetPadTrackSym(), $pad->GetPoint(), 0, DrawEnums->Polar_POSITIVE ) );
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

