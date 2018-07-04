
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb POOL
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::MicrostripBuilders::SEBuilder;
use base('Programs::Coupon::CpnBuilder::MicrostripBuilders::MicrostripBuilderBase');

use Class::Interface;
&implements('Programs::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use Math::Trig;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::PadLayout';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::TrackLayout';
use aliased 'Programs::Coupon::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	# properties of constrain
	#pads, lines, coordinates
 
	return $self;
}

sub Build {
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;

	# Origin where left down strip pad shoul be start (contain position of left side on coupon. Right side is symetric)
	my $origin = $self->{"cpnSingle"}->GetMicrostripOrigin( $self->{"stripVariant"});

	# set model

	my $areaW   = $self->{"settings"}->GetCpnSingleWidth();
	my $margin  = $self->{"settings"}->GetCouponSingleMargin()/1000;
	my $p2pDist = $self->{"settings"}->GetPad2PadDist() / 1000;

	my $trackW = $self->_GetXmlConstr()->GetParamDouble("WB");    # µm

	# track and GND pads are placed horizontally => 1 positions
	if ( $self->{"cpnSingle"}->IsMultistrip() ) {

		
		my $tOrigin; # origin of track pad
		my $gOrigin; # origin of GND pad
		if ( $self->{"stripVariant"}->Pool() == 0 ) {

			$tOrigin = Point->new( $origin->X(), $origin->Y() );  
			$gOrigin = Point->new( $origin->X(), $origin->Y() + $self->{"settings"}->GetPad2PadDist() / 1000);    
		}
		elsif ( $self->{"stripVariant"}->Pool() == 1 ) {

			$tOrigin = Point->new( $origin->X(), $origin->Y() + $self->{"settings"}->GetPad2PadDist() / 1000 );  
			$gOrigin = Point->new( $origin->X(), $origin->Y() );    
		}

	
		# LEFT SIDE

		# build Track pad
		my $sTrPad = PadLayout->new( Point->new( $tOrigin->X(), $tOrigin->Y() ), Enums->Pad_TRACK, undef, $self->_GetPadText($tOrigin) );
		$self->{"layout"}->AddPad($sTrPad);

		# build GND pad
		my $sGNDPad = PadLayout->new( Point->new( $gOrigin->X(), $gOrigin->Y()), Enums->Pad_GND, $self->{"cpnSingle"}->GetShareGNDLayers($self) );
		$self->{"layout"}->AddPad($sGNDPad);

		my $eGNDPad;
		my $eTrPad;

		if ( $self->{"settings"}->GetTwoEndedDesign() ) {

			# build Track pad
			my $eTrPad = PadLayout->new( Point->new( $areaW - $tOrigin->X(), $tOrigin->Y() ), Enums->Pad_TRACK, undef,  $self->_GetPadText(Point->new( $areaW - $tOrigin->X(), $tOrigin->Y() )) );
			$self->{"layout"}->AddPad($eTrPad);

			# build GND pad
			my $eGNDPad = PadLayout->new( Point->new( $areaW - $gOrigin->X(), $gOrigin->Y() ), Enums->Pad_GND, $self->{"cpnSingle"}->GetShareGNDLayers($self) );
			$self->{"layout"}->AddPad($eGNDPad);

		}

		# build track line

		# polyline from 3 lines

		my @track = $self->_GetMultistripSETrack($tOrigin);

		my $track = TrackLayout->new( \@track, $trackW );

		$self->{"layout"}->AddTrack($track);

	}

	# track and GND pads are placed vertically => 2 positions
	else {

		my $tOrigin = Point->new( $origin->X() + $self->{"settings"}->GetPad2PadDist() / 1000, $origin->Y() );    # origin of track pad
		my $gOrigin = Point->new( $origin->X(), $origin->Y() );                                                   # origin of GND pad

		# LEFT SIDE

		# build GND pad
		my $sGNDPad = PadLayout->new( Point->new( $gOrigin->X(), $gOrigin->Y() ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($sGNDPad);

		# build Track pad
		my $sTrPad = PadLayout->new( Point->new( $tOrigin->X(), $tOrigin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($sTrPad);

		# RIGHT SIDE

		my $eGNDPad;
		my $eTrPad;

		if ( $self->{"settings"}->GetTwoEndedDesign() ) {

			# build GND pad
			$eGNDPad = PadLayout->new( Point->new( $areaW - $gOrigin->X(), $gOrigin->Y() ), Enums->Pad_GND );
			$self->{"layout"}->AddPad($eGNDPad);

			# build Track pad
			$eTrPad = PadLayout->new( Point->new( $areaW - $tOrigin->X(), $tOrigin->Y() ), Enums->Pad_TRACK );
			$self->{"layout"}->AddPad($eTrPad);
		}

		# build track line

		my @track = $self->_GetSEStraightTrack($tOrigin);
		my $track = TrackLayout->new( \@track, $trackW );

		$self->{"layout"}->AddTrack($track);

	}

	return $result;

}
#
#sub GetPadPosXCnt {
#	my $self = shift;
#
#	if ( $self->{"cpnSingle"}->IsMultistrip() ) {
#		return 1;
#	}
#	else {
#		return 2;
#	}
#
#}
#
#sub GetPadPosYCnt {
#	my $self = shift;
#
#	if ( $self->{"cpnSingle"}->IsMultistrip() ) {
#		return 2;
#	}
#	else {
#		return 1;
#	}
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

