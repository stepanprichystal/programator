
#-------------------------------------------------------------------------------------------#
# Description: Layer builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnGenerator::CpnLayers::TrackLayer;

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
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfFill';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSolidPattern';
use aliased 'CamHelpers::CamLayer';
use aliased 'Programs::Coupon::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';
use aliased 'CamHelpers::CamJob';
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
	my $layerLayout     = shift;    # layer layout

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Draw pad clearance
	foreach my $pad ( $layout->GetPads() ) {

		if ( $pad->GetType() eq Enums->Pad_GND ) {

			my $shareGNDLayers = $pad->GetShareGndLayers();

			if ( !$shareGNDLayers->{ $self->{"layerName"} } && !$layout->GetCoplanar() ) {

				my $symClearance =
				  $cpnSingleLayout->GetPadGNDShape() . ( $cpnSingleLayout->GetPadGNDSize() + 2 * $layout->GetPad2GND() );
				$self->{"drawing"}->AddPrimitive(
							PrimitivePad->new( $symClearance, $pad->GetPoint(), 0, $self->_InvertPolar( DrawEnums->Polar_NEGATIVE, $layerLayout ) ) );
			}

		}
		else {

			my $symClearance =
			  $cpnSingleLayout->GetPadTrackShape() . ( $cpnSingleLayout->GetPadTrackSize() + 2 * $layout->GetPad2GND() );
			$self->{"drawing"}->AddPrimitive(
							PrimitivePad->new( $symClearance, $pad->GetPoint(), 0, $self->_InvertPolar( DrawEnums->Polar_NEGATIVE, $layerLayout ) ) );
		}

	}

	# Draw track clearance

	foreach my $track ( $layout->GetTracks() ) {

		my @points = $track->GetPoints();

		# Draw negative clearance
		my $symNeg = "r";

		if ( $layout->GetCoplanar() ) {
			$symNeg .= ( $track->GetWidth() + 2 * $track->GetGNDDist() );
		}
		else {
			$symNeg .= ( $track->GetWidth() + 2 * $layout->GetTrackToCopper() );
		}

		if ( scalar(@points) == 2 ) {
			my $l = PrimitiveLine->new( $points[0], $points[1], $symNeg, $self->_InvertPolar( DrawEnums->Polar_NEGATIVE, $layerLayout ) );
			$self->{"drawing"}->AddPrimitive($l);

		}
		else {
			my $p = PrimitivePolyline->new( \@points, $symNeg, $self->_InvertPolar( DrawEnums->Polar_NEGATIVE, $layerLayout ) );
			$self->{"drawing"}->AddPrimitive($p);
		}

	}

	# Draw track

	foreach my $track ( $layout->GetTracks() ) {

		my @points = $track->GetPoints();

		# Draw lines

		if ( scalar(@points) == 2 ) {
			my $l =
			  PrimitiveLine->new( $points[0], $points[1], "r" . $track->GetWidth(), $self->_InvertPolar( DrawEnums->Polar_POSITIVE, $layerLayout ) );
			$self->{"drawing"}->AddPrimitive($l);

		}
		else {
			my $p = PrimitivePolyline->new( \@points, "r" . $track->GetWidth(), $self->_InvertPolar( DrawEnums->Polar_POSITIVE, $layerLayout ) );
			$self->{"drawing"}->AddPrimitive($p);
		}

	}

	# draw pads
	foreach my $pad ( $layout->GetPads() ) {

		my $symPad = undef;

		if ( $pad->GetType() eq Enums->Pad_GND ) {

			my $shareGNDLayers = $pad->GetShareGndLayers();

			if ( !$shareGNDLayers->{ $self->{"layerName"} } && !$layout->GetCoplanar() ) {
				$self->{"drawing"}->AddPrimitive(
												  PrimitivePad->new(
																	 $cpnSingleLayout->GetPadGNDSym(), $pad->GetPoint(),
																	 0, $self->_InvertPolar( DrawEnums->Polar_POSITIVE, $layerLayout )
												  )
				);

			}

			# If coplanar add GND pads
			if ( $layout->GetCoplanar() ) {

				$self->{"drawing"}->AddPrimitive(
												  PrimitivePad->new(
																	 $cpnSingleLayout->GetPadGNDSymNeg(), $pad->GetPoint(),
																	 0, $self->_InvertPolar( DrawEnums->Polar_NEGATIVE, $layerLayout )
												  )
				);
			}
		}
		else {

			$self->{"drawing"}->AddPrimitive(
											  PrimitivePad->new(
																 $cpnSingleLayout->GetPadTrackSym(), $pad->GetPoint(),
																 0, $self->_InvertPolar( DrawEnums->Polar_POSITIVE, $layerLayout )
											  )
			);
		}

	}

	# If coplanar add GND surface
	if ( $layout->GetCoplanar() ) {
		my $step = $self->{"step"};

		# add "break line" before GND filling which prevent to fill area where is place info text
		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

		if ( $cpnSingleLayout->GetCpnSingleWidth() < $lim{"xMax"} ) {
			my @coord = ();
			push( @coord, Point->new( $cpnSingleLayout->GetCpnSingleWidth(), 0 ) );
			push( @coord, Point->new( $cpnSingleLayout->GetCpnSingleWidth(), $lim{"yMax"} ) );
			push( @coord, Point->new( $lim{"xMax"},                          $lim{"yMax"} ) );
			push( @coord, Point->new( $lim{"xMax"},                          0 ) );
			push( @coord, Point->new( $cpnSingleLayout->GetCpnSingleWidth(), 0 ) );

			$self->{"drawing"}
			  ->AddPrimitive( PrimitiveSurfPoly->new( \@coord, undef, $self->_InvertPolar( DrawEnums->Polar_NEGATIVE, $layerLayout ) ) );
		}

		# add surface fill
		my $solidPattern = SurfaceSolidPattern->new( 0, 0 );

		$self->{"drawing"}
		  ->AddPrimitive( PrimitiveSurfFill->new( $solidPattern, 0, 0, 0, 0, 1, 0, $self->_InvertPolar( DrawEnums->Polar_POSITIVE, $layerLayout ) ) );
	}

	# Drav GND via holes pad
	if ( $layout->GetCoplanar() ) {
		my $shieldingLayout = $cpnSingleLayout->GetShieldingGNDViaLayout();

		if ( defined $shieldingLayout ) {
			foreach my $hole ( $layout->GetGNDViaPoints() ) {

				$self->{"drawing"}->AddPrimitive(
							PrimitivePad->new( "r" . ( 2 * $shieldingLayout->GetGNDViaHoleRing() + $shieldingLayout->GetGNDViaHoleSize() ), $hole ) );
			}
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

