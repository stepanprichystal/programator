
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
	my $cpnSingle = shift;
	my $errMess   = shift;

	my $result = 1;
 
	# Origin where strip pad shoul be start (contain position of left side on coupon. Right side is symetric)
	my $origin =  $cpnSingle->GetMicrostripOrigin();   

	# compute track dimension, pads

	# All variants of pads
	# - one single on coupon => gnd pad below track pad (in vertical line)
	# - more singles on coupon => all gnd pads in one horizontal line

	# set model

	my $areaW   = $self->{"settings"}->GetAreaWidth();
	my $margin  = $self->{"settings"}->GetCouponSingleMargin();
	my $p2pDist = $self->{"settings"}->GetPad2PadDist();

	# space between track 1 and 2
	my $s = $self->{"constrain"}->GetParamDouble("S")/1000;    # space mm
	my $w = $self->{"constrain"}->GetParamDouble("WB")/1000;    # width mm

	# track and GND pads are placed horizontally => 1 positions
	if ( $cpnSingle->IsMultistrip() ) {

		# Build track 1

		# width of track 1

		# build GND pads
		$self->{"layout"}->AddPad(PadLayout->new( Point->new( $origin->X(), $origin->Y() + $p2pDist ), Enums->Pad_GND ));

		$self->{"layout"}->AddPad(PadLayout->new( Point->new( $areaW - $origin->X(), $origin->Y() + $p2pDist ), Enums->Pad_GND ));

		# build Track pads
		$self->{"layout"}->AddPad(PadLayout->new( Point->new( $origin->X(), $origin->Y() ), Enums->Pad_TRACK ));

		$self->{"layout"}->AddPad(PadLayout->new( Point->new( $areaW - $origin->X(), $origin->Y() ), Enums->Pad_TRACK ));

		# build track line

		# polyline from 3 lines
		my $p1L1 = Point->new( $origin->X(), $origin->Y() );
		my $p2L1 = Point->new( $origin->X() 		 + abs($p2pDist/2  + $s / 2 + $w/2)*tan( deg2rad(45)), $origin->Y() + $p2pDist/2  + $s / 2 + $w/2 );
		my $p3L1 = Point->new( $areaW - $origin->X() - abs($p2pDist/2  + $s / 2 + $w/2)*tan( deg2rad(45)), $origin->Y() + $p2pDist/2  + $s / 2 + $w/2);
		my $p4L1 = Point->new( $areaW - $origin->X(), $origin->Y() );

		$self->{"layout"}->AddTrack( TrackLayout->new( [ $p1L1, $p2L1, $p3L1, $p4L1 ], $w*1000 ) );

		# Build track 2

		# build GND pads
		$self->{"layout"}->AddPad(PadLayout->new( Point->new( $origin->X() + $p2pDist, $origin->Y() + $p2pDist ), Enums->Pad_GND ));

		$self->{"layout"}->AddPad(PadLayout->new( Point->new( $areaW - $origin->X() - $p2pDist, $origin->Y() + $p2pDist ), Enums->Pad_GND ));

		# build Track pads
		$self->{"layout"}->AddPad(PadLayout->new( Point->new( $origin->X() + $p2pDist, $origin->Y() ), Enums->Pad_TRACK ));

		$self->{"layout"}->AddPad(PadLayout->new( Point->new( $areaW - $origin->X() - $p2pDist, $origin->Y() ), Enums->Pad_TRACK ));

		# build track line
		# polyline from 3 lines
		my $p1L2 = Point->new( $origin->X() + $p2pDist, $origin->Y() );
		my $p2L2 = Point->new( $origin->X() + $p2pDist	+ abs($p2pDist/2  - $s / 2 - $w/2)*tan( deg2rad(45)), $origin->Y() + $p2pDist / 2 - $s / 2 - $w/2 );
		my $p3L2 = Point->new( $areaW - $origin->X() - $p2pDist - abs($p2pDist/2  - $s / 2- $w/2)*tan( deg2rad(45)), $origin->Y() + $p2pDist / 2 - $s / 2 - $w/2 );
		my $p4L2 = Point->new( $areaW - $origin->X() - $p2pDist, $origin->Y() );

		$self->{"layout"}->AddTrack( TrackLayout->new( [ $p1L2, $p2L2, $p3L2, $p4L2 ], $w*1000 ) );

	}

	# track and GND pads are placed vertically => 2 positions
	else {

		# Build track 1

		# width of track 1 - lower

		# build GND pads
		my $sGNDPadL1 = PadLayout->new( Point->new( $origin->X(), $origin->Y() ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($sGNDPadL1);

		my $eGNDPadL1 = PadLayout->new( Point->new( $areaW - $origin->X(), $origin->Y() ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($eGNDPadL1);

		# build Track pads
		my $sTrPadL1 = PadLayout->new( Point->new( $origin->X() + $p2pDist, $origin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($sTrPadL1);

		my $eTrPadL1 = PadLayout->new( Point->new( $areaW - $origin->X() - $p2pDist, $origin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($eTrPadL1);

		# build track line

		# polyline from 3 lines
		my $p1L1 = $sTrPadL1->GetPoint();
		my $p2L1 = Point->new( $origin->X() + $p2pDist + $p2pDist / 2, $origin->Y() + $p2pDist / 2 - $s / 2 );
		my $p3L1 = Point->new( $areaW - $origin->X() - $p2pDist - $p2pDist / 2, $origin->Y() + $p2pDist / 2 - $s / 2 );
		my $p4L1 = $eTrPadL1->GetPoint();

		$self->{"layout"}->AddTrack( TrackLayout->new( [ $p1L1, $p2L1, $p3L1, $p4L1 ], $w ) );

		# Build track 2

		# build GND pads
		my $sGNDPadL2 = PadLayout->new( Point->new( $origin->X(), $origin->Y() + $p2pDist ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($sGNDPadL2);

		my $eGNDPadL2 = PadLayout->new( Point->new( $areaW - $origin->X(), $origin->Y() + $p2pDist ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($eGNDPadL2);

		# build Track pads
		my $sTrPadL2 = PadLayout->new( Point->new( $origin->X() + $p2pDist, $origin->Y() + $p2pDist ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($sTrPadL2);

		my $eTrPadL2 = PadLayout->new( Point->new( $areaW - $origin->X() - $p2pDist, $origin->Y() + $p2pDist ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($eTrPadL2);

		# build track line
		# polyline from 3 lines
		my $p1L2 = $sTrPadL2->GetPoint();
		my $p2L2 = Point->new( $origin->X() + $p2pDist + $p2pDist / 2, $origin->Y() + $p2pDist - $p2pDist / 2 + $s / 2 );
		my $p3L2 = Point->new( $areaW - $origin->X() - $p2pDist - $p2pDist / 2, $origin->Y() + $p2pDist - $p2pDist / 2 + $s / 2 );
		my $p4L2 = $eTrPadL2->GetPoint();

		$self->{"layout"}->AddTrack( TrackLayout->new( [ $p1L2, $p2L2, $p3L2, $p4L2 ], $w ) );

	}

	 
	return $result;
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

