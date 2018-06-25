
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

sub Draw {
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
		my $symNeg = "r" . ( $track->GetWidth() + $self->{"settings"}->GetTrackToCopper() );
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
		}
		else {

			$self->{"drawing"}
			  ->AddPrimitive( PrimitivePad->new( $self->{"settings"}->GetPadTrackSym(), $pad->GetPoint(), 0, DrawEnums->Polar_POSITIVE ) );
		}

	}

	# Draw to layer
	$self->_Draw();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

