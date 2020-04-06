
#-------------------------------------------------------------------------------------------#
# Description: Coplanar diferential builder
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::MicrostripBuilders::CODiffBuilder;
use base('Programs::Coupon::CpnBuilder::MicrostripBuilders::DiffBuilder');

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
use aliased 'Programs::Coupon::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	# properties of constrain

	return $self;
}

sub Build {
	my $self          = shift;
	my $stripVariant  = shift;
	my $cpnSett       = shift;
	my $cpnSingleSett = shift;
	my $errMess       = shift;

	# 1) Build SE layout

	my $result = $self->SUPER::Build( $stripVariant, $cpnSett, $cpnSingleSett );

	# Add extra behaviour for conaplanar SE

	# 2) Set coplanar type
	$self->{"layout"}->SetCoplanar(1);

	# 2) Set GND to track distance

	my $coSE = $self->_GetXmlConstr()->GetParamDouble("CS");    # µm

	foreach my $t ( $self->{"layout"}->GetTracks() ) {

		$t->SetGNDDist($coSE);
	}

	# 3) Set GND via hole positions
	if ( $cpnSett->GetGNDViaShielding() ) {

		die "Only route type: streight is allowed when coplanar with GND via"
		  if ( $stripVariant->Route() ne Enums->Route_STREIGHT );

		die "Only single strip is allowed when coplanar with GND via"
		  if ( $self->{"cpnSingle"}->IsMultistrip() );

		# Via hole can start just near track pad, because coupon contains alwazs only one (diff) or two (2 x SE in two pools)
		# microstrip
		my $origin  = $self->{"cpnSingle"}->GetMicrostripOrigin($stripVariant);
		my $xPosCnt = $self->{"cpnSingle"}->GetMicrostripPosCnt( $stripVariant, "x" );
		my $p2pDist = $cpnSingleSett->GetTrackPad2TrackPad() / 1000;                     # in mm

		my $tOrigin  = PointLayout->new( $origin->X() + ( $xPosCnt - 1 ) * $p2pDist, $origin->Y() );
		 
		 

		my $viaHoleOffset =
		  ( $cpnSingleSett->GetPadTrackSize() / 2 + $coSE + $cpnSett->GetGNDViaHole2GNDDist() + $cpnSett->GetGNDViaHoleSize() / 2 ) / 1000;
		my $viaHoleArea = ( $cpnSingleSett->GetCpnSingleWidth() - 2 * $tOrigin->X() - 2 * $viaHoleOffset );

		my $viaCnt = int( $viaHoleArea / ( $cpnSett->GetGNDViaHoleDX() / 1000 ) ) + 1;
		my $areaLeft = $viaHoleArea % ( $cpnSett->GetGNDViaHoleDX() / 1000 );

		my $yPosTopVia =
		  $tOrigin->Y() + $p2pDist/2+
		  ( $stripVariant->RouteDist() * 1000 / 2 +
			$stripVariant->RouteWidth() * 1000 +
			$coSE + $cpnSett->GetGNDViaHole2GNDDist() +
			$cpnSett->GetGNDViaHoleSize() / 2 ) / 1000;
		my $yPosBotVia =
		  $tOrigin->Y() + $p2pDist/2  -
		  ( $stripVariant->RouteDist() * 1000 / 2 +
			$stripVariant->RouteWidth() * 1000 +
			$coSE + $cpnSett->GetGNDViaHole2GNDDist() +
			$cpnSett->GetGNDViaHoleSize() / 2 ) / 1000;

		my $xPosVia = $tOrigin->X() + $viaHoleOffset + $areaLeft / 2;
		for ( my $i = 0 ; $i < $viaCnt ; $i++ ) {

			$self->{"layout"}->AddGNDViaPoint( PointLayout->new( $xPosVia, $yPosTopVia ) );
			$self->{"layout"}->AddGNDViaPoint( PointLayout->new( $xPosVia, $yPosBotVia ) );

			$xPosVia += $cpnSett->GetGNDViaHoleDX() / 1000;
		}
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

