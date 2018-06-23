
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
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;

	# Origin where strip pad shoul be start (contain position of left side on coupon. Right side is symetric)
	my $origin = $self->{"cpnSingle"}->GetMicrostripOrigin($self);

	# compute track dimension, pads

	# All variants of pads
	# - one single on coupon => gnd pad below track pad (in vertical line)
	# - more singles on coupon => all gnd pads in one horizontal line

	# set model

	my $areaW   = $self->{"cpnWArea"};
	my $margin  = $self->{"settings"}->GetCouponSingleMargin();
	my $p2pDist = $self->{"settings"}->GetPad2PadDist() / 1000;    # mm

	my $w = $self->_GetXmlConstr()->GetParamDouble("WB");          # width µm

	# track and GND pads are placed horizontally => 1 positions
	if ( $self->{"cpnSingle"}->IsMultistrip() ) {

		# Build track outer ---------------------------------

		my $tOutOrigin;                                               # origin of track pad
		my $gOutOrigin;                                               # origin of GND pad
		if ( $self->{"stripVariant"}->Pool() == 0 ) {

			$tOutOrigin = Point->new( $origin->X(), $origin->Y() );
			$gOutOrigin = Point->new( $origin->X(), $origin->Y() + $self->{"settings"}->GetPad2PadDist() / 1000 );
		}
		elsif ( $self->{"stripVariant"}->Pool() == 1 ) {

			$tOutOrigin = Point->new( $origin->X(), $origin->Y() + $self->{"settings"}->GetPad2PadDist() / 1000 );
			$gOutOrigin = Point->new( $origin->X(), $origin->Y() );
		}

		# build GND pad
		$self->{"layout"}->AddPad( PadLayout->new( Point->new( $gOutOrigin->X(), $gOutOrigin->Y()  ), Enums->Pad_GND ) );

		# build Track pad
		$self->{"layout"}->AddPad( PadLayout->new( Point->new( $tOutOrigin->X(), $tOutOrigin->Y() ), Enums->Pad_TRACK ) );

		if ( $self->{"settings"}->GetTwoEndedDesign() ) {

			# build GND pad
			$self->{"layout"}->AddPad( PadLayout->new( Point->new( $areaW - $gOutOrigin->X(), $gOutOrigin->Y() ), Enums->Pad_GND ) );

			# build Track pad
			$self->{"layout"}->AddPad( PadLayout->new( Point->new( $areaW - $tOutOrigin->X(), $tOutOrigin->Y() ), Enums->Pad_TRACK ) );

		}

		# build track line
		my @trackOuter = $self->_GetMultistripDIFFTrackOuter($tOutOrigin);
		$self->{"layout"}->AddTrack( TrackLayout->new( \@trackOuter, $w ) );

		# Build track inner ---------------------------------
					
		my $tInOrigin;                                               # origin of track pad
		my $gInOrigin;                                               # origin of GND pad
		if ( $self->{"stripVariant"}->Pool() == 0 ) {

			$tInOrigin = Point->new( $origin->X() + $self->{"settings"}->GetPad2PadDist()/1000, $origin->Y() );
			$gInOrigin = Point->new( $origin->X() + $self->{"settings"}->GetPad2PadDist()/1000, $origin->Y() + $self->{"settings"}->GetPad2PadDist() / 1000 );
		}
		elsif ( $self->{"stripVariant"}->Pool() == 1 ) {

			$tInOrigin = Point->new( $origin->X() + $self->{"settings"}->GetPad2PadDist()/1000, $origin->Y() + $self->{"settings"}->GetPad2PadDist() / 1000 );
			$gInOrigin = Point->new( $origin->X() + $self->{"settings"}->GetPad2PadDist()/1000, $origin->Y() );
		}

		# build GND pad
		$self->{"layout"}->AddPad( PadLayout->new( Point->new( $gInOrigin->X(), $gInOrigin->Y()), Enums->Pad_GND ) );

		# build Track pad
		$self->{"layout"}->AddPad( PadLayout->new( Point->new( $tInOrigin->X() , $tInOrigin->Y() ), Enums->Pad_TRACK ) );

		if ( $self->{"settings"}->GetTwoEndedDesign() ) {

			# build GND pad
			$self->{"layout"}->AddPad( PadLayout->new( Point->new( $areaW - $gInOrigin->X(), $gInOrigin->Y() ), Enums->Pad_GND ) );

			# build Track pad
			$self->{"layout"}->AddPad( PadLayout->new( Point->new( $areaW - $tInOrigin->X(), $tInOrigin->Y() ), Enums->Pad_TRACK ) );
		}

		# build track line
		my @trackInner = $self->_GetMultistripDIFFTrackInner($tInOrigin);
		$self->{"layout"}->AddTrack( TrackLayout->new( \@trackInner, $w ) );

	}

	# track and GND pads are placed vertically => 2 positions
	else {


		# Build track upper ---------------------------------
 		my $tUpperOrigin = Point->new( $origin->X() + $self->{"settings"}->GetPad2PadDist() / 1000, $origin->Y() + $self->{"settings"}->GetPad2PadDist() / 1000 );
		my $gUpperOrigin = Point->new( $origin->X(), $origin->Y() + $self->{"settings"}->GetPad2PadDist() / 1000 );
 

		# build GND pad
		my $sGNDPadL1 = PadLayout->new( Point->new( $gUpperOrigin->X(), $gUpperOrigin->Y() ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($sGNDPadL1);

		# build Track pad
		my $sTrPadL1 = PadLayout->new( Point->new( $tUpperOrigin->X(), $tUpperOrigin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($sTrPadL1);

		if ( $self->{"settings"}->GetTwoEndedDesign() ) {

			# build GND pad
			my $eGNDPadL1 = PadLayout->new( Point->new( $areaW - $gUpperOrigin->X(), $gUpperOrigin->Y() ), Enums->Pad_GND );
			$self->{"layout"}->AddPad($eGNDPadL1);

			# build Track pad
			my $eTrPadL1 = PadLayout->new( Point->new( $areaW - $tUpperOrigin->X(), $tUpperOrigin->Y() ), Enums->Pad_TRACK );
			$self->{"layout"}->AddPad($eTrPadL1);

		}

		# build track line
		my @trackTop = $self->_GetSingleDIFFTrack( $tUpperOrigin, "upper" );
		$self->{"layout"}->AddTrack( TrackLayout->new( \@trackTop, $w ) );


		# Build track 2 lower ---------------------------------
		my $tLowerOrigin = Point->new( $origin->X() + $self->{"settings"}->GetPad2PadDist() / 1000, $origin->Y() );
		my $gLowerOrigin = Point->new( $origin->X(), $origin->Y() );

		# build GND pad
		my $sGNDPadL2 = PadLayout->new( Point->new( $gLowerOrigin->X(), $gLowerOrigin->Y() ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($sGNDPadL2);

		# build Track pad
		my $sTrPadL2 = PadLayout->new( Point->new( $tLowerOrigin->X(), $tLowerOrigin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($sTrPadL2);

		if ( $self->{"settings"}->GetTwoEndedDesign() ) {

			# build GND pad
			my $eGNDPadL2 = PadLayout->new( Point->new( $areaW - $gLowerOrigin->X(), $gLowerOrigin->Y()), Enums->Pad_GND );
			$self->{"layout"}->AddPad($eGNDPadL2);

			# build Track pad
			my $eTrPadL2 = PadLayout->new( Point->new( $areaW - $tLowerOrigin->X(), $tLowerOrigin->Y() ), Enums->Pad_TRACK );
			$self->{"layout"}->AddPad($eTrPadL2);

		}

		# build track line
		my @trackBot = $self->_GetSingleDIFFTrack( $tLowerOrigin, "lower" );
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

