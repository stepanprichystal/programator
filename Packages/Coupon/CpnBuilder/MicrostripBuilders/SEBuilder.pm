
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb POOL
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::MicrostripBuilders::SEBuilder;
use base('Packages::Coupon::CpnBuilder::MicrostripBuilders::MicrostripBuilderBase');

use Class::Interface;
&implements('Packages::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;

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
 
	$self->{"padPosXCnt"} = 1;     # track and GND pads are placed vertically => it takes 1 position
	$self->{"padPosYCnt"} = 2;     # track and GND pads are placed vertically => it takes 1 position

	return $self;
}

sub Build {
	my $self      = shift;
	my $errMess   = shift;

	my $result = 1;
 
	# Origin where strip pad shoul be start (contain position of left side on coupon. Right side is symetric)
	my $origin =  $self->{"cpnSingle"}->GetMicrostripOrigin();    

	# set model
	
	my $areaW   = $self->{"settings"}->GetAreaWidth();
	my $margin  = $self->{"settings"}->GetCouponSingleMargin();
	my $p2pDist = $self->{"settings"}->GetPad2PadDist();

	my $trackW = $self->{"constrain"}->GetParamDouble("WB") / 1000; # µm

	# track and GND pads are placed horizontally => 1 positions
	if ( $self->{"cpnSingle"}->IsMultistrip() ) {

		# build Track pads
		my $sTrPad = PadLayout->new( Point->new( $origin->X(), $origin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($sTrPad);

		my $eTrPad = PadLayout->new( Point->new( $areaW - $origin->X(), $origin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($eTrPad);

		# build GND pads
		my $sGNDPad = PadLayout->new( Point->new( $origin->X(), $origin->Y() + $p2pDist ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($sGNDPad);

		my $eGNDPad = PadLayout->new( Point->new( $areaW - $origin->X(), $origin->Y() + $p2pDist ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($eGNDPad);

		# build track line

		# polyline from 3 lines
		# 1 from start pad
		my $p1 = $sTrPad->GetPoint();
		my $p2 = Point->new( $origin->X() + $p2pDist / 2, $origin->Y() + $p2pDist / 2 );
		my $p3 = Point->new( $areaW - $origin->X() - $p2pDist / 2, $origin->Y() + $p2pDist / 2 );
		my $p4 = $eTrPad->GetPoint();

		my $track = TrackLayout->new( [ $p1, $p2, $p3, $p4 ], $trackW );

		$self->{"layout"}->AddTrack($track);

	}

	# track and GND pads are placed vertically => 2 positions
	else {
 

		# build GND pads
		my $sGNDPad = PadLayout->new( Point->new( $origin->X(), $origin->Y() ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($sGNDPad);

		my $eGNDPad = PadLayout->new( Point->new( $areaW - $origin->X(), $origin->Y() ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($eGNDPad);

		# build Track pads
		my $sTrPad = PadLayout->new( Point->new( $origin->X() + $p2pDist, $origin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($sTrPad);

		my $eTrPad = PadLayout->new( Point->new( $areaW - $origin->X() - $p2pDist, $origin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($eTrPad);

		# build track line

		my $track = TrackLayout->new( [ $sTrPad->GetPoint(), $eTrPad->GetPoint() ], $trackW );

		$self->{"layout"}->AddTrack($track);

	}

	return $result;

}

sub GetPadPosXCnt {
	my $self = shift;

	if($self->{"cpnSingle"}->IsMultistrip()){
		return 1;
	}else{
		return 2;
	}
 
}

sub GetPadPosYCnt {
	my $self = shift;

	if($self->{"cpnSingle"}->IsMultistrip()){
		return 2;
	}else{
		return 1;
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

