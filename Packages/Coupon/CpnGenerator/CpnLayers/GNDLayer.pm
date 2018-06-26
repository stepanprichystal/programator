
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnGenerator::CpnLayers::GNDLayer;

use base('Packages::Coupon::CpnGenerator::CpnLayers::LayerBase');

#use Class::Interface;
#&implements('Packages::Coupon::CpnBuilder::MicrostripBuilders::IModelBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::Coupon::Enums';
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
	my $self   = shift;
	my $layout = shift;    # microstrip layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# add "break line" before GND filling which prevent to fill area where is place info text
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
	my $solidPattern = SurfaceSolidPattern->new( 0, 0 );

	$self->{"drawing"}->AddPrimitive( PrimitiveSurfFill->new( $solidPattern, 0, 0, 0, 0, 1, 0, DrawEnums->Polar_POSITIVE ) );

	#		my $pattern  = shift;
	#	my $marginX  = shift;
	#	my $marginY  = shift;
	#	my $srMarginX = shift;
	#	my $srMarginY = shift;
	#	my $considerFeat  = shift;
	#	my $featMargin  = shift;
	#	my $polarity = shift;    #
	#
	#	$inCAM->COM(
	#				 "sr_fill",
	#				 "type"          => "solid",
	#				 "solid_type"    => "surface",
	#				 "step_margin_x" => "0",
	#				 "step_margin_y" => "0",
	#				 "consider_feat" => "yes",
	#				 "feat_margin"   => "0",
	#				 "dest"          => "layer_name",
	#				 "layer"         => $self->{"layerName"}
	#	);

	# drav GND  pads
	foreach my $pad ( grep { $_->GetType() eq Enums->Pad_GND } $layout->GetPads() ) {

		$self->{"drawing"}
		  ->AddPrimitive( PrimitivePad->new( $self->{"settings"}->GetPadGNDSymNeg(), $pad->GetPoint(), 0, DrawEnums->Polar_NEGATIVE ) );
	}

	# drav track pads
	foreach my $pad ( grep { $_->GetType() eq Enums->Pad_TRACK } $layout->GetPads() ) {

		my $symClearance =
		  $self->{"settings"}->GetPadTrackShape() . ( $self->{"settings"}->GetPadTrackSize() + $self->{"settings"}->GetPad2GNDClearance() );
		$self->{"drawing"}->AddPrimitive( PrimitivePad->new( $symClearance, $pad->GetPoint(), 0, DrawEnums->Polar_NEGATIVE ) );

		if ( $self->{"layerName"} !~ /v\d+/ ) {
			$self->{"drawing"}
			  ->AddPrimitive( PrimitivePad->new( $self->{"settings"}->GetPadTrackSym(), $pad->GetPoint(), 0, DrawEnums->Polar_POSITIVE ) );
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

