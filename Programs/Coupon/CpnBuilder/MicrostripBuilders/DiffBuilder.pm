
#-------------------------------------------------------------------------------------------#
# Description: # Description: Differential builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::MicrostripBuilders::DiffBuilder;
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
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::PointLayout';
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
	my $self          = shift;
	my $stripVariant  = shift;
	my $cpnSett       = shift;
	my $cpnSingleSett = shift;
	my $errMess       = shift;

	my $cpnStripSett = $stripVariant->GetCpnStripSettings();

	$self->SUPER::Build( $stripVariant, $cpnSett, $cpnSingleSett );

	my $result = 1;

	# Origin where strip pad shoul be start (contain position of left side on coupon. Right side is symetric)
	my $origin = $self->{"cpnSingle"}->GetMicrostripOrigin( $self->{"stripVariant"} );

	# compute track dimension, pads

	# All variants of pads
	# - one single on coupon => gnd pad below track pad (in vertical line)
	# - more singles on coupon => all gnd pads in one horizontal line

	# set model

	my $areaW   = $self->{"cpnSingleSett"}->GetCpnSingleWidth();
	my $margin  = $self->{"cpnSett"}->GetCouponSingleMargin() / 1000;
	my $p2pDist = $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000;    # mm

	my $w = $self->_GetXmlConstr()->GetParamDouble("WB");               # width ?m

	# track and GND pads are placed horizontally => 1 positions
	if ( $self->{"cpnSingle"}->IsMultistrip() ) {

		# Build track outer ---------------------------------

		my $tOutOrigin;                                                 # origin of track pad
		my $gOutOrigin;                                                 # origin of GND pad
		if ( $self->{"stripVariant"}->Pool() == 0 ) {

			$tOutOrigin = PointLayout->new( $origin->X(), $origin->Y() );
			$gOutOrigin = PointLayout->new( $origin->X(), $origin->Y() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000 );
		}
		elsif ( $self->{"stripVariant"}->Pool() == 1 ) {

			$tOutOrigin = PointLayout->new( $origin->X(), $origin->Y() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000 );
			$gOutOrigin = PointLayout->new( $origin->X(), $origin->Y() );
		}

		# build GND pad
		$self->{"layout"}->AddPad(
				 PadLayout->new( PointLayout->new( $gOutOrigin->X(), $gOutOrigin->Y() ), Enums->Pad_GND, $self->{"cpnSingle"}->GetShareGNDLayers($self) ) );

		# build Track pad
		$self->{"layout"}
		  ->AddPad( PadLayout->new( PointLayout->new( $tOutOrigin->X(), $tOutOrigin->Y() ), Enums->Pad_TRACK, undef, $self->_GetPadText($tOutOrigin) ) );

		if ( $self->{"cpnSett"}->GetTwoEndedDesign() ) {

			# build GND pad
			$self->{"layout"}->AddPad(
									   PadLayout->new(
													   PointLayout->new( $areaW - $gOutOrigin->X(), $gOutOrigin->Y() ), Enums->Pad_GND,
													   $self->{"cpnSingle"}->GetShareGNDLayers($self)
									   )
			);

			# build Track pad
			$self->{"layout"}->AddPad(
							  PadLayout->new(
											  PointLayout->new( $areaW - $tOutOrigin->X(), $tOutOrigin->Y() ),
											  Enums->Pad_TRACK, undef, $self->_GetPadText( PointLayout->new( $areaW - $tOutOrigin->X(), $tOutOrigin->Y() ) )
							  )
			);

		}

		# build track line
		my @trackOuter = $self->_GetMultistripDIFFTrackOuter($tOutOrigin);
		$self->{"layout"}->AddTrack( TrackLayout->new( \@trackOuter, $w ) );

		# Build track inner ---------------------------------

		my $tInOrigin;    # origin of track pad
		my $gInOrigin;    # origin of GND pad
		if ( $self->{"stripVariant"}->Pool() == 0 ) {

			$tInOrigin = PointLayout->new( $origin->X() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000, $origin->Y() );
			$gInOrigin = PointLayout->new( $origin->X() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000,
									 $origin->Y() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000 );
		}
		elsif ( $self->{"stripVariant"}->Pool() == 1 ) {

			$tInOrigin = PointLayout->new( $origin->X() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000,
									 $origin->Y() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000 );
			$gInOrigin = PointLayout->new( $origin->X() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000, $origin->Y() );
		}

		# build GND pad
		$self->{"layout"}->AddPad(
			  PadLayout->new( PointLayout->new( $gInOrigin->X(), $gInOrigin->Y() ), Enums->Pad_GND, $self->{"cpnSingle"}->GetShareGNDLayers( $self, 1 ) ) );

		# build Track pad
		$self->{"layout"}
		  ->AddPad( PadLayout->new( PointLayout->new( $tInOrigin->X(), $tInOrigin->Y() ), Enums->Pad_TRACK, undef, $self->_GetPadText($tInOrigin) ) );

		if ( $self->{"cpnSett"}->GetTwoEndedDesign() ) {

			# build GND pad
			$self->{"layout"}->AddPad(
									   PadLayout->new(
													   PointLayout->new( $areaW - $gInOrigin->X(), $gInOrigin->Y() ), Enums->Pad_GND,
													   $self->{"cpnSingle"}->GetShareGNDLayers($self)
									   )
			);

			# build Track pad
			$self->{"layout"}->AddPad(
								PadLayout->new(
												PointLayout->new( $areaW - $tInOrigin->X(), $tInOrigin->Y() ),
												Enums->Pad_TRACK, undef, $self->_GetPadText( PointLayout->new( $areaW - $tInOrigin->X(), $tInOrigin->Y() ) )
								)
			);
		}

		# build track line
		my @trackInner = $self->_GetMultistripDIFFTrackInner($tInOrigin);
		$self->{"layout"}->AddTrack( TrackLayout->new( \@trackInner, $w ) );

	}

	# track and GND pads are placed vertically => 2 positions
	else {

		# Build track upper ---------------------------------
		my $tUpperOrigin = PointLayout->new( $origin->X() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000,
									   $origin->Y() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000 );
		my $gUpperOrigin = PointLayout->new( $origin->X(), $origin->Y() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000 );

		# build GND pad
		my $sGNDPadL1 = PadLayout->new( PointLayout->new( $gUpperOrigin->X(), $gUpperOrigin->Y() ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($sGNDPadL1);

		# build Track pad
		my $sTrPadL1 = PadLayout->new( PointLayout->new( $tUpperOrigin->X(), $tUpperOrigin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($sTrPadL1);

		if ( $self->{"cpnSett"}->GetTwoEndedDesign() ) {

			# build GND pad
			my $eGNDPadL1 = PadLayout->new( PointLayout->new( $areaW - $gUpperOrigin->X(), $gUpperOrigin->Y() ), Enums->Pad_GND );
			$self->{"layout"}->AddPad($eGNDPadL1);

			# build Track pad
			my $eTrPadL1 = PadLayout->new( PointLayout->new( $areaW - $tUpperOrigin->X(), $tUpperOrigin->Y() ), Enums->Pad_TRACK );
			$self->{"layout"}->AddPad($eTrPadL1);

		}

		# build track line
		my @trackTop = $self->_GetSingleDIFFTrack( $tUpperOrigin, "upper" );
		$self->{"layout"}->AddTrack( TrackLayout->new( \@trackTop, $w ) );

		# Build track 2 lower ---------------------------------
		my $tLowerOrigin = PointLayout->new( $origin->X() + $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000, $origin->Y() );
		my $gLowerOrigin = PointLayout->new( $origin->X(), $origin->Y() );

		# build GND pad
		my $sGNDPadL2 = PadLayout->new( PointLayout->new( $gLowerOrigin->X(), $gLowerOrigin->Y() ), Enums->Pad_GND );
		$self->{"layout"}->AddPad($sGNDPadL2);

		# build Track pad
		my $sTrPadL2 = PadLayout->new( PointLayout->new( $tLowerOrigin->X(), $tLowerOrigin->Y() ), Enums->Pad_TRACK );
		$self->{"layout"}->AddPad($sTrPadL2);

		if ( $self->{"cpnSett"}->GetTwoEndedDesign() ) {

			# build GND pad
			my $eGNDPadL2 = PadLayout->new( PointLayout->new( $areaW - $gLowerOrigin->X(), $gLowerOrigin->Y() ), Enums->Pad_GND );
			$self->{"layout"}->AddPad($eGNDPadL2);

			# build Track pad
			my $eTrPadL2 = PadLayout->new( PointLayout->new( $areaW - $tLowerOrigin->X(), $tLowerOrigin->Y() ), Enums->Pad_TRACK );
			$self->{"layout"}->AddPad($eTrPadL2);

		}

		# build track line
		my @trackBot = $self->_GetSingleDIFFTrack( $tLowerOrigin, "lower" );
		$self->{"layout"}->AddTrack( TrackLayout->new( \@trackBot, $w ) );

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

