
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::CpnSingleBuilder;

use Class::Interface;
&implements('Packages::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use Switch;
use List::Util qw[min max];

#local library
use aliased 'Packages::Coupon::Enums';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Coupon::CpnBuilder::MicrostripBuilders::SEBuilder';
use aliased 'Packages::Coupon::CpnBuilder::MicrostripBuilders::DiffBuilder';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::Coupon::CpnBuilder::CpnLayout::CpnSingleLayout';
use aliased 'Packages::Coupon::CpnBuilder::OtherBuilders::CpnInfoTextBuilder';
use aliased 'Packages::Coupon::CpnBuilder::OtherBuilders::GuardTracksBuilder';
use aliased 'Packages::Coupon::Helper';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"settings"}     = shift;    # global settings for generating coupon
	                                    #$self->{"constraints"} = shift;    # list of constrain object (based on instack Job xml)
	                                    #$cpnVarinat
	$self->{"singleCpnVar"} = shift;

	$self->{"layout"} = CpnSingleLayout->new();    # Layout of one single coupon

	$self->{"microstrips"} = [];

	$self->{"build"} = 0;                          # indicator if layout was built

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

# Build single coupon layout
# If ok return 1, else 0 + err message
sub Build {
	my $self    = shift;
	my $errMess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	# Built miscrostip builers

	# Init
	foreach my $poolVar ( $self->{"singleCpnVar"}->GetPools() ) {

		foreach my $stripVar ( $poolVar->GetStrips() ) {

			my $mStripBuilder = undef;

			switch ( $stripVar->GetType() ) {

				case Enums->Type_SE { $mStripBuilder = SEBuilder->new() }

				  case Enums->Type_DIFF { $mStripBuilder = DiffBuilder->new() }

				  else { die "Microstirp type: " . $stripVar->GetType() . "is not implemented"; }
			}

			$mStripBuilder->Init( $inCAM, $jobId, $self->{"settings"}, $stripVar, $self );

			if ( $mStripBuilder->Build($errMess) ) {

				$self->{"layout"}->AddMicrostripLayout( $mStripBuilder->GetLayout() );
			}
			else {

				$result = 0;
			}

			#push( @{ $self->{"microstrips"} }, $mStripBuilder );
		}
	}

	#	# Built
	#	foreach my $mStripBuilder ( @{ $self->{"microstrips"} } ) {
	#
	#		# Set property common for all microstrip types
	#
	#		if ( $mStripBuilder->Build($errMess) ) {
	#
	#			$self->{"layout"}->AddMicrostripLayout( $mStripBuilder->GetLayout() );
	#		}
	#		else {
	#
	#			$result = 0;
	#		}
	#	}

	# Build text info builders

	if ( $self->{"settings"}->GetInfoText() ) {

		my $textBuilder = CpnInfoTextBuilder->new( $inCAM, $jobId, $self->{"settings"}, $self->{"singleCpnVar"}, $self );

		if ( $textBuilder->Build($errMess) ) {

			my $textLayout = $textBuilder->GetLayout();

			my $p;
			my %activeArea = $self->GetActiveArea();

			if ( $textLayout->GetType() eq "right" ) {

				my $x = $self->{"settings"}->GetCpnSingleWidth() + $self->{"settings"}->GetInfoTextRightCpnDist();
				my $y = $self->{"settings"}->GetCouponSingleMargin();

				# if coupon is heigher than text, center text vertically to single coupon

				if ( $activeArea{"h"} > $textLayout->GetHeight() ) {
					$y += ( $activeArea{"h"} - $textLayout->GetHeight() ) / 2;
				}
				$p = Point->new( $x, $y );

			}
			elsif ( $textLayout->GetType() eq "top" ) {

				#compute
				# align text to right
				$p = Point->new( $self->{"settings"}->GetCpnSingleWidth() - $textLayout->GetWidth() - $self->{"settings"}->GetCouponSingleMargin(),
								 $self->{"settings"}->GetCouponSingleMargin() + $activeArea{"h"} + $self->{"settings"}->GetPadsTopTextDist() );
			}

			$textLayout->SetPosition($p);
			$self->{"layout"}->SetInfoTextLayout($textLayout);

		}
		else {

			$result = 0;
		}
	}

	# Build guard tracks
	if ( $self->{"settings"}->GetGuardTracks() ) {

		my $gtBuilder = GuardTracksBuilder->new( $inCAM, $jobId, $self->{"settings"}, $self->{"singleCpnVar"}, $self );
		if ( $gtBuilder->Build($errMess) ) {

			$self->{"layout"}->SetGuardTracksLayout( $gtBuilder->GetLayout() );
		}
		else {

			$result = 0;
		}

	}

	# Specify which layer has to contains ground negative pads in for each microstrip gnd pads
	# Consider onlz pads which has to bz connected to ground

	if ($result) {

		# Set height of whole coupon
		my %cpnArea = $self->GetCpnSingleArea();

		$self->{"layout"}->SetHeight( $cpnArea{"h"} );
		$self->{"layout"}->SetWidth( $cpnArea{"w"} );

		$self->{"build"} = 1;
	}

	return $result;
}

sub GetLayout {
	my $self = shift;

	return $self->{"layout"};
}

sub IsMultistrip {
	my $self = shift;

	return $self->{"singleCpnVar"}->IsMultistrip();
}

sub GetShareGNDLayers {
	my $self         = shift;
	my $stripBuilder = shift;    # idof microstrip order

	my $stripVariant = $stripBuilder->GetStripVariant();

	my @strips = $self->{"singleCpnVar"}->GetStripsByColumn( $stripVariant->Col() );

	my @test = map { ( $_->Data()->{"xmlConstraint"}->GetTopRefLayer(), $_->Data()->{"xmlConstraint"}->GetBotRefLayer() ) } @strips;

	my @gndLayers =
	  map { Helper->GetInCAMLayer( $_, $self->{"layerCnt"} ) }
	  grep { defined $_ && $_ =~ /l\d+/i }
	  map { ( $_->Data()->{"xmlConstraint"}->GetTopRefLayer(), $_->Data()->{"xmlConstraint"}->GetBotRefLayer() ) } @strips;

	my %layers;
	@layers{ Helper->GetAllLayerNames( $self->{"layerCnt"} ) } = ();

	$layers{$_} = 0 foreach keys %layers;
	$layers{$_} = 1 foreach @gndLayers;

	return \%layers;
}

# Return origin for microstrip
# Microstrip origin is always in left down pad of microstrip
sub GetMicrostripOrigin {
	my $self         = shift;
	my $stripVariant = shift;

	# X cooredination - left down pad (trakc/GND) of microstrip
	my $x = $self->{"settings"}->GetCouponSingleMargin() + $self->{"settings"}->GetPadTrackSize() / 1000 / 2;

	# choose pool
	my $pool = $self->{"singleCpnVar"}->GetPoolByOrder( $stripVariant->Pool() );

	for ( my $i = 0 ; $i < $stripVariant->Col() ; $i++ ) {

		# all strips on current column pos
		my @stripsVar = $self->{"singleCpnVar"}->GetStripsByColumn($i);

		# get positions of pad in x direction (1 or one)

		my @pos = map { $self->GetMicrostripPosCnt( $_, "x" ) } (@stripsVar);

		$x += ( max(@pos) - 1 ) * $self->{"settings"}->GetPad2PadDist() / 1000 + $self->{"settings"}->GetGroupPadsDist();
	}

	# Y cooredination - left down pad (trakc/GND) of microstrip
	my $y = undef;

	# bottom pool

	$y = $self->{"settings"}->GetCouponSingleMargin();
	$y += $self->{"settings"}->GetPadTrackSize() / 2 / 1000;    # half of track pad size

	# space for bottom routes in whole pool strip if exist
	my $botPool = $self->{"singleCpnVar"}->GetPoolByOrder(0);
	my @spaces = map { $_->RouteDist() + $_->RouteWidth() / 2 } grep { $_->Route() eq Enums->Route_BELOW } $botPool->GetStrips();
	if (@spaces) {
		$y -= $self->{"settings"}->GetPadTrackSize() / 2 / 1000;
		$y += max(@spaces);
	}

	# top pool

	if ( $pool->GetOrder() == 1 ) {

		$y += $self->{"settings"}->GetTracePad2GNDPad() / 1000;

	}

	return Point->new( $x, $y );
}

# return height including title text height
sub GetCpnSingleArea {
	my $self = shift;

	my %areaInfo = ( "pos" => undef, "w" => undef, "h" => undef );

	my %stripArea = $self->GetActiveArea();

	# compute position
	$areaInfo{"pos"} = Point->new( $self->{"settings"}->GetCouponMargin(), $self->{"settings"}->GetCouponMargin() );

	# compute width
	my $w = 2 * $self->{"settings"}->GetCouponSingleMargin() + $stripArea{"w"};

	# consider right text
	if ( $self->{"settings"}->GetInfoText() ) {

		my $textLayout = $self->{"layout"}->GetInfoTextLayout();

		die "Infot text layout is not defined " unless ( defined $textLayout );

		if ( $self->{"settings"}->GetInfoTextPosition() eq "right" ) {
			$w += $self->{"settings"}->GetInfoTextRightCpnDist() + $textLayout->GetWidth();
		}
	}

	$areaInfo{"w"} = $w;

	# compute height
	my $h = 2 * $self->{"settings"}->GetCouponSingleMargin() + $stripArea{"h"};

	# consider top texts
	if ( $self->{"settings"}->GetInfoText() ) {

		my $textLayout = $self->{"layout"}->GetInfoTextLayout();

		die "Infot text layout is not defined " unless ( defined $textLayout );

		if ( $self->{"settings"}->GetInfoTextPosition() eq "top" ) {

			$h += $self->{"settings"}->GetPadsTopTextDist();
			$h += $textLayout->GetHeight();

		}
		elsif ( $self->{"settings"}->GetInfoTextPosition() eq "right" ) {

			if ( $textLayout->GetHeight() > $stripArea{"h"} ) {

				$h += $textLayout->GetHeight() - $stripArea{"h"};
			}
		}
	}

	$areaInfo{"h"} = $h;

	return %areaInfo;
}

# Return active area of microstrips
# Active area means border of area wherea are placed all pads and tracks (no texts)
# Return hash:
# - pos- Points struture - origin of active area in single coupon
# - w - width of active area
# - h - height of active area
sub GetActiveArea {
	my $self = shift;

	my %areaInfo = ( "pos" => undef, "w" => undef, "h" => undef );

	# compute position
	$areaInfo{"pos"} = Point->new( $self->{"settings"}->GetCouponSingleMargin(), $self->{"settings"}->GetCouponSingleMargin() );

	# compute width
	$areaInfo{"w"} = $self->{"settings"}->GetCpnSingleWidth() - 2 * $self->{"settings"}->GetCouponSingleMargin();

	# compute height
	my $h = undef;

	if ( $self->{"singleCpnVar"}->IsMultistrip() ) {

		my @poolsVar = $self->{"singleCpnVar"}->GetPools();

		my $padsY = 2;

		if ( scalar(@poolsVar) == 2 ) {
			$padsY = 3;
		}

		$h = ( $padsY - 1 ) * $self->{"settings"}->GetTrackPad2TrackPad() / 1000 + $self->{"settings"}->GetPadTrackSize() / 1000;

		foreach my $poolVar (@poolsVar) {

			# check if pool "bottom" contains track route type "below"
			if ( $poolVar->GetOrder() == 0 ) {

				my @spaces = map { $_->RouteDist() + $_->RouteWidth() / 2 } grep { $_->Route() eq Enums->Route_BELOW } $poolVar->GetStrips();
				if (@spaces) {
					$h += max(@spaces);
					$h -= $self->{"settings"}->GetPadTrackSize() / 1000 / 2;    # route is higher than pad anular ring
				}

			}

			# check if pool "top" contains track route type "above"
			elsif ( $poolVar->GetOrder() == 1 ) {

				my @spaces = map { $_->RouteDist() + $_->RouteWidth() / 2 } grep { $_->Route() eq Enums->Route_ABOVE } $poolVar->GetStrips();
				if (@spaces) {
					$h += max(@spaces);
					$h -= $self->{"settings"}->GetPadTrackSize() / 1000 / 2;    # route is higher than pad anular ring
				}

			}

		}
	}

	# single strip
	else {

		my $strip = ( map { $_->GetStrips() } $self->{"singleCpnVar"}->GetPools() )[0];

		my $padsY = $self->GetMicrostripPosCnt( $strip, "y" );

		$h = ( $padsY - 1 ) * $self->{"settings"}->GetTrackPad2TrackPad() / 1000 + $self->{"settings"}->GetPadTrackSize() / 1000;
	}

	$areaInfo{"h"} = $h;

	return %areaInfo;
}

#sub __GetMicrostripBuilder {
#	my $self = shift;
#	my $id   = shift;
#
#	my $microstrip = ( grep { $_->GetStripVariant()->Id() eq $id } @{ $self->{"microstrips"} } )[0];
#
#	return $microstrip;
#
#}

sub GetMicrostripPosCnt {
	my $self      = shift;
	my $stripVar  = shift;
	my $direction = shift;    # x or y direction

	my %multiStrip = ();
	$multiStrip{ Enums->Type_SE }{"x"}     = 1;
	$multiStrip{ Enums->Type_SE }{"y"}     = 2;
	$multiStrip{ Enums->Type_DIFF }{"x"}   = 2;
	$multiStrip{ Enums->Type_DIFF }{"y"}   = 2;
	$multiStrip{ Enums->Type_COSE }{"x"}   = 1;
	$multiStrip{ Enums->Type_COSE }{"y"}   = 2;
	$multiStrip{ Enums->Type_CODIFF }{"x"} = 2;
	$multiStrip{ Enums->Type_CODIFF }{"y"} = 2;

	my %singleStrip = ();
	$singleStrip{ Enums->Type_SE }{"x"}     = 2;
	$singleStrip{ Enums->Type_SE }{"y"}     = 1;
	$singleStrip{ Enums->Type_DIFF }{"x"}   = 2;
	$singleStrip{ Enums->Type_DIFF }{"y"}   = 2;
	$singleStrip{ Enums->Type_COSE }{"x"}   = 2;
	$singleStrip{ Enums->Type_COSE }{"y"}   = 1;
	$singleStrip{ Enums->Type_CODIFF }{"x"} = 2;
	$singleStrip{ Enums->Type_CODIFF }{"y"} = 2;

	if ( $self->IsMultistrip() ) {

		return $multiStrip{ $stripVar->GetType() }{$direction};
	}
	else {

		return $singleStrip{ $stripVar->GetType() }{$direction};
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

