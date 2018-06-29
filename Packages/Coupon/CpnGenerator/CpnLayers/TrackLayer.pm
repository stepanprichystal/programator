
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnGenerator::CpnLayers::TrackLayer;

use base('Packages::Coupon::CpnGenerator::CpnLayers::LayerBase');

#use Class::Interface;
#&implements('Packages::Coupon::CpnBuilder::MicrostripBuilders::IModelBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePolyline';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfFill';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSolidPattern';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::Coupon::Enums';
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

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Draw pad clearance
	foreach my $pad ( $layout->GetPads() ) {

		if ( $pad->GetType() eq Enums->Pad_GND ) {

			my $shareGNDLayers = $pad->GetShareGndLayers();

			if ( !$shareGNDLayers->{ $self->{"layerName"} } ) {

				my $symClearance =
				  $self->{"settings"}->GetPadGNDShape() . ( $self->{"settings"}->GetPadGNDSize() + $self->{"settings"}->GetPad2GNDClearance() );
				$self->{"drawing"}->AddPrimitive( PrimitivePad->new( $symClearance, $pad->GetPoint(), 0, DrawEnums->Polar_NEGATIVE ) );
			}

		}
		else {

			my $symClearance =
			  $self->{"settings"}->GetPadTrackShape() . ( $self->{"settings"}->GetPadTrackSize() + $self->{"settings"}->GetPad2GNDClearance() );
			$self->{"drawing"}->AddPrimitive( PrimitivePad->new( $symClearance, $pad->GetPoint(), 0, DrawEnums->Polar_NEGATIVE ) );
		}

	}

	# Draw track clearance

	foreach my $track ( $layout->GetTracks() ) {

		my @points = $track->GetPoints();

		# Draw negative clearance
		my $symNeg = "r";

		if ( $layout->GetCoplanar() ) {
			$symNeg .= ( $track->GetWidth() + $track->GetGNDDist() );
		}
		else {
			$symNeg .= ( $track->GetWidth() + $self->{"settings"}->GetTrackToCopper() );
		}

		if ( scalar(@points) == 2 ) {
			my $l = PrimitiveLine->new( $points[0], $points[1], $symNeg, DrawEnums->Polar_NEGATIVE );
			$self->{"drawing"}->AddPrimitive($l);

		}
		else {
			my $p = PrimitivePolyline->new( \@points, $symNeg, DrawEnums->Polar_NEGATIVE );
			$self->{"drawing"}->AddPrimitive($p);
		}

	}

	# Draw track

	foreach my $track ( $layout->GetTracks() ) {

		my @points = $track->GetPoints();

		# Draw lines

		if ( scalar(@points) == 2 ) {
			my $l = PrimitiveLine->new( $points[0], $points[1], "r" . $track->GetWidth() );
			$self->{"drawing"}->AddPrimitive($l);

		}
		else {
			my $p = PrimitivePolyline->new( \@points, "r" . $track->GetWidth() );
			$self->{"drawing"}->AddPrimitive($p);
		}

	}

	# draw pads
	foreach my $pad ( $layout->GetPads() ) {

		my $symPad = undef;

		if ( $pad->GetType() eq Enums->Pad_GND ) {

			my $shareGNDLayers = $pad->GetShareGndLayers();

			if ( !$shareGNDLayers->{ $self->{"layerName"} } ) {
				$self->{"drawing"}
				  ->AddPrimitive( PrimitivePad->new( $self->{"settings"}->GetPadGNDSym(), $pad->GetPoint(), 0, DrawEnums->Polar_POSITIVE ) );

			}

			# If coplanar add GND pads
			if ( $layout->GetCoplanar() ) {

				$self->{"drawing"}
				  ->AddPrimitive( PrimitivePad->new( $self->{"settings"}->GetPadGNDSymNeg(), $pad->GetPoint(), 0, DrawEnums->Polar_NEGATIVE ) );
			}
		}
		else {

			$self->{"drawing"}
			  ->AddPrimitive( PrimitivePad->new( $self->{"settings"}->GetPadTrackSym(), $pad->GetPoint(), 0, DrawEnums->Polar_POSITIVE ) );
		}

	}

	# If coplanar add GND surface
	if ( $layout->GetCoplanar() ) {
		my $step = $self->{"step"};

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
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

