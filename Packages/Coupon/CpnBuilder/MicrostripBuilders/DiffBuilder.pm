
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb POOL
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::MicrostripBuilders::DiffBuilder;
use base('Packages::Coupon::CpnBuilder::MicrostripBuilders::MicrostripBuilderBase');

use Class::Interface;
&implements('Packages::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::Coupon::CpnBuilder::CpnLayout::PadLayout';
use aliased 'Packages::Coupon::CpnBuilder::CpnLayout::TrackLayout';
use aliased 'Packages::Coupon::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	# properties of constrain
	#pads, lines, coordinates

	$self->{"height"}    = 7.5;
	$self->{"padPosCnt"} = 2;     #

	return $self;
}

sub Build {
	my $self      = shift;
	my $errMess   = shift;

	my $result = 1;

	# Origin where strip pad shoul be start (contain position of left side on coupon. Right side is symetric)
	my $origin = $self->{"cpnSingle"}->GetMicrostripOrigin();

	# compute track dimension, pads

	# All variants of pads
	# - one single on coupon => gnd pad below track pad (in vertical line)
	# - more singles on coupon => all gnd pads in one horizontal line

	# set model

	my $areaW   = $self->{"settings"}->GetAreaWidth();
	my $margin  = $self->{"settings"}->GetCouponSingleMargin();
	my $p2pDist = $self->{"settings"}->GetPad2PadDist();

	# space between track 1 and 2
	my $s = $self->_GetXmlConstr()->GetParamDouble("S") / 1000;     # space mm
	my $w = $self->_GetXmlConstr()->GetParamDouble("WB") / 1000;    # width mm

	# track and GND pads are placed horizontally => 1 positions
	if ( $self->{"cpnSingle"}->IsMultistrip() ) {

		# Build track outer ---------------------------------

		# build GND pad
		$self->{"layout"}->AddPad( PadLayout->new( Point->new( $origin->X(), $origin->Y() + $p2pDist ), Enums->Pad_GND ) );
		# build Track pad
		$self->{"layout"}->AddPad( PadLayout->new( Point->new( $origin->X(), $origin->Y() ), Enums->Pad_TRACK ) );

		if ( $self->{"settings"}->GetTwoEndedDesign() ) {

			# build GND pad
			$self->{"layout"}->AddPad( PadLayout->new( Point->new( $areaW - $origin->X(), $origin->Y() + $p2pDist ), Enums->Pad_GND ) );
			# build Track pad
			$self->{"layout"}->AddPad( PadLayout->new( Point->new( $areaW - $origin->X(), $origin->Y() ), Enums->Pad_TRACK ) );

		}

		# build track line
		my @trackOuter = $self->_GetMultistripDIFFTrackOuter($origin);
		$self->{"layout"}->AddTrack( TrackLayout->new( \@trackOuter, $w ) );

		# Build track outer ---------------------------------

		# build GND pad
		$self->{"layout"}->AddPad( PadLayout->new( Point->new( $origin->X() + $p2pDist, $origin->Y() + $p2pDist ), Enums->Pad_GND ) );
		# build Track pad
		$self->{"layout"}->AddPad( PadLayout->new( Point->new( $origin->X() + $p2pDist, $origin->Y() ), Enums->Pad_TRACK ) );

		if ( $self->{"settings"}->GetTwoEndedDesign() ) {

			# build GND pad
			$self->{"layout"}->AddPad( PadLayout->new( Point->new( $areaW - $origin->X() - $p2pDist, $origin->Y() + $p2pDist ), Enums->Pad_GND ) );
			# build Track pad
			$self->{"layout"}->AddPad( PadLayout->new( Point->new( $areaW - $origin->X() - $p2pDist, $origin->Y() ), Enums->Pad_TRACK ) );
		}
		
		# build track line
		my @trackInner = $self->_GetMultistripDIFFTrackInner($origin);
		$self->{"layout"}->AddTrack( TrackLayout->new( \@trackInner, $w ) );

	}

	# track and GND pads are placed vertically => 2 positions
	else {

		# Build track upper ---------------------------------

		# build GND pad
		my $sGNDPadL1 = PadLayout->new( Point->new( $origin->X(), $origin->Y() ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($sGNDPadL1);
		# build Track pad
		my $sTrPadL1 = PadLayout->new( Point->new( $origin->X() + $p2pDist, $origin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($sTrPadL1);

		if ( $self->{"settings"}->GetTwoEndedDesign() ) {

			# build GND pad
			my $eGNDPadL1 = PadLayout->new( Point->new( $areaW - $origin->X(), $origin->Y() ), Enums->Pad_GND );
			$self->{"layout"}->AddPad($eGNDPadL1);
			# build Track pad
			my $eTrPadL1 = PadLayout->new( Point->new( $areaW - $origin->X() - $p2pDist, $origin->Y() ), Enums->Pad_TRACK );
			$self->{"layout"}->AddPad($eTrPadL1);

		}

		# build track line

		my @trackTop = $self->_GetSingleDIFFTrack( $origin, "top" );
		$self->{"layout"}->AddTrack( TrackLayout->new( \@trackTop, $w ) );

		# Build track 2 lower ---------------------------------

		# build GND pad
		my $sGNDPadL2 = PadLayout->new( Point->new( $origin->X(), $origin->Y() + $p2pDist ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($sGNDPadL2);

		# build Track pad
		my $sTrPadL2 = PadLayout->new( Point->new( $origin->X() + $p2pDist, $origin->Y() + $p2pDist ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($sTrPadL2);

		if ( $self->{"settings"}->GetTwoEndedDesign() ) {

			# build GND pad
			my $eGNDPadL2 = PadLayout->new( Point->new( $areaW - $origin->X(), $origin->Y() + $p2pDist ), Enums->Pad_GND );
			$self->{"layout"}->AddPad($eGNDPadL2);

			# build Track pad
			my $eTrPadL2 = PadLayout->new( Point->new( $areaW - $origin->X() - $p2pDist, $origin->Y() + $p2pDist ), Enums->Pad_TRACK );
			$self->{"layout"}->AddPad($eTrPadL2);

		}

		# build track line
		my @trackBot = $self->_GetSingleDIFFTrack( $origin, "bot" );
		$self->{"layout"}->AddTrack( TrackLayout->new( \@trackBot, $w ) );

	}

	return $result;
}

sub GetPadPosXCnt {
	my $self = shift;

	return 2;

}

sub GetPadPosYCnt {
	my $self = shift;

	return 2;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

