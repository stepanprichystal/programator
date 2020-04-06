
#-------------------------------------------------------------------------------------------#
# Description: Builder of one coupon group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnSingleBuilder;

use Class::Interface;
&implements('Programs::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use Switch;
use List::Util qw[min max];

#local library
use aliased 'Programs::Coupon::Enums';
use aliased 'Enums::EnumsImp';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Coupon::Helper';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::PointLayout';

use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::CpnSingleLayout';
use aliased 'Programs::Coupon::CpnBuilder::MicrostripBuilders::SEBuilder';
use aliased 'Programs::Coupon::CpnBuilder::MicrostripBuilders::DiffBuilder';
use aliased 'Programs::Coupon::CpnBuilder::MicrostripBuilders::COSEBuilder';
use aliased 'Programs::Coupon::CpnBuilder::MicrostripBuilders::CODiffBuilder';

use aliased 'Programs::Coupon::CpnBuilder::OtherBuilders::CpnInfoTextBuilder';
use aliased 'Programs::Coupon::CpnBuilder::OtherBuilders::GuardTracksBuilder';
use aliased 'Programs::Coupon::CpnBuilder::OtherBuilders::ShieldingBuilder';
use aliased 'Programs::Coupon::CpnBuilder::OtherBuilders::ShieldingGNDViaBuilder';
use aliased 'Programs::Coupon::CpnBuilder::OtherBuilders::CpnLayerBuilder';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"layout"}       = CpnSingleLayout->new();    # Layout of one single coupon
	$self->{"build"}        = 0;                         # indicator if layout was built
	$self->{"singleCpnVar"} = undef;

	# Setting references
	$self->{"cpnSett"}       = undef;                    # global settings for generating coupon
	$self->{"cpnSingleSett"} = undef;

	# Other helper properties

	$self->{"microstrips"} = [];

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

# Build single coupon layout
# If ok return 1, else 0 + err message
sub Build {
	my $self         = shift;
	my $singleCpnVar = shift;
	my $cpnSett      = shift;    # global settings for generating coupon
	my $errMess      = shift;

	$self->{"singleCpnVar"}  = $singleCpnVar;
	$self->{"cpnSett"}       = $cpnSett;
	$self->{"cpnSingleSett"} = $singleCpnVar->GetCpnSingleSettings();

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	# Built miscrostip builers

	# Init
	foreach my $poolVar ( $self->{"singleCpnVar"}->GetPools() ) {

		foreach my $stripVar ( $poolVar->GetStrips() ) {

			my $mStripBuilder = undef;

			switch ( $stripVar->GetType() ) {

				case EnumsImp->Type_SE { $mStripBuilder = SEBuilder->new() }

				  case EnumsImp->Type_DIFF { $mStripBuilder = DiffBuilder->new() }

				  case EnumsImp->Type_COSE { $mStripBuilder = COSEBuilder->new() }

				  case EnumsImp->Type_CODIFF { $mStripBuilder = CODiffBuilder->new() }

				  else { die "Microstirp type: " . $stripVar->GetType() . "is not implemented"; }
			}

			$mStripBuilder->Init( $inCAM, $jobId, $self );

			if ( $mStripBuilder->Build( $stripVar, $self->{"cpnSett"}, $self->{"cpnSingleSett"}, $errMess ) ) {

				$self->{"layout"}->AddMicrostripLayout( $mStripBuilder->GetLayout() );
			}
			else {

				$result = 0;
			}

			#push( @{ $self->{"microstrips"} }, $mStripBuilder );
		}
	}

	# Build text info builders

	if ( $self->{"cpnSett"}->GetInfoText() ) {

		my $textBuilder = CpnInfoTextBuilder->new( $inCAM, $jobId );

		if ( $textBuilder->Build( $self->{"singleCpnVar"}, $self->{"cpnSett"}, $errMess ) ) {

			my $textLayout = $textBuilder->GetLayout();

			my $p;
			my %activeArea = $self->GetActiveArea();

			if ( $textLayout->GetType() eq "right" ) {

				my $x = $self->{"cpnSingleSett"}->GetCpnSingleWidth() + $self->{"cpnSett"}->GetInfoTextRightCpnDist() / 1000;
				my $y = $self->{"cpnSett"}->GetCouponSingleMargin() / 1000;

				# if coupon is heigher than text, center text vertically to single coupon

				if ( $activeArea{"h"} > $textLayout->GetHeight() ) {
					$y += ( $activeArea{"h"} - $textLayout->GetHeight() ) / 2;
				}
				$p = PointLayout->new( $x, $y );

			}
			elsif ( $textLayout->GetType() eq "top" ) {

				#compute
				# align text to right
				$p = PointLayout->new(
						 $self->{"cpnSingleSett"}->GetCpnSingleWidth() - $textLayout->GetWidth() - $self->{"cpnSett"}->GetCouponSingleMargin() / 1000,
						 $self->{"cpnSett"}->GetCouponSingleMargin() / 1000 + $activeArea{"h"} + $self->{"cpnSett"}->GetPadsTopTextDist() / 1000 );
			}

			$textLayout->SetPosition($p);
			$self->{"layout"}->SetInfoTextLayout($textLayout);

		}
		else {

			$result = 0;
		}
	}

	# Build guard tracks
	if ( $self->{"cpnSett"}->GetGuardTracks() ) {

		my $gtBuilder = GuardTracksBuilder->new( $inCAM, $jobId, $self );
		if ( $gtBuilder->Build( $self->{"singleCpnVar"}, $self->{"cpnSett"}, $errMess ) ) {

			$self->{"layout"}->SetGuardTracksLayout( $gtBuilder->GetLayout() );
		}
		else {

			$result = 0;
		}

	}

	# Build shielding
	if ( $self->{"cpnSett"}->GetShielding() ) {

		my $sBuilder = ShieldingBuilder->new( $inCAM, $jobId );
		if ( $sBuilder->Build( $self->{"singleCpnVar"}, $self->{"cpnSett"}, $errMess ) ) {

			$self->{"layout"}->SetShieldingLayout( $sBuilder->GetLayout() );
		}
		else {

			$result = 0;
		}

	}

	# Build shielding GND Via for coplanar types
	if ( $self->{"cpnSett"}->GetGNDViaShielding() ) {

		my $sBuilder = ShieldingGNDViaBuilder->new( $inCAM, $jobId );
		if ( $sBuilder->Build( $self->{"singleCpnVar"}, $self->{"cpnSett"}, $errMess ) ) {

			$self->{"layout"}->SetShieldingGNDViaLayout( $sBuilder->GetLayout() );
		}
		else {

			$result = 0;
		}

	}

	# Build other parameters
	if ($result) {

		# set width of strip line (include pads + cpn single margins)
		$self->{"layout"}->SetCpnSingleWidth( $self->{"cpnSingleSett"}->GetCpnSingleWidth() );

		# build info about pad shapes and dimensions
		$self->{"layout"}->SetPadGNDSymNeg( $self->{"cpnSingleSett"}->GetPadGNDSymNeg() );
		$self->{"layout"}->SetPadTrackSize( $self->{"cpnSingleSett"}->GetPadTrackSize() );
		$self->{"layout"}->SetPadTrackSym( $self->{"cpnSingleSett"}->GetPadTrackSym() );
		$self->{"layout"}->SetPadGNDShape( $self->{"cpnSingleSett"}->GetPadGNDShape() );
		$self->{"layout"}->SetPadGNDSize( $self->{"cpnSingleSett"}->GetPadGNDSize() );
		$self->{"layout"}->SetPadGNDSym( $self->{"cpnSingleSett"}->GetPadGNDSym() );
		$self->{"layout"}->SetPadTrackShape( $self->{"cpnSingleSett"}->GetPadTrackShape() );
		$self->{"layout"}->SetPadDrillSize( $self->{"cpnSingleSett"}->GetPadDrillSize() );

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
	my $stripBuilder = shift;         # idof microstrip order
	my $secondPos    = shift // 0;    # iff strip is diff and func is called by pad in "second column (pad on right)"

	my $stripVariant = $stripBuilder->GetStripVariant();

	my @strips = $self->{"singleCpnVar"}->GetStripsByColumn( $stripVariant->Col() );

	my @gndLayers = ();               # layers where has to by GND pad (on specific column position)

	foreach my $s (@strips) {

		my $topGnd = $s->Data()->{"xmlConstraint"}->GetTopRefLayer();
		my $botGnd = $s->Data()->{"xmlConstraint"}->GetBotRefLayer();
		my $track  = $s->Data()->{"xmlConstraint"}->GetTrackLayer();

		push( @gndLayers, Helper->GetInCAMLayer( $topGnd, $self->{"layerCnt"} ) ) if ( defined $topGnd && $topGnd =~ /l\d+/i );
		push( @gndLayers, Helper->GetInCAMLayer( $botGnd, $self->{"layerCnt"} ) ) if ( defined $botGnd && $botGnd =~ /l\d+/i );
		push( @gndLayers, Helper->GetInCAMLayer( $track,  $self->{"layerCnt"} ) )
		  if ( $s->GetType() eq EnumsImp->Type_COSE || $s->GetType() eq EnumsImp->Type_CODIFF );
	}

	my %layers;
	@layers{ Helper->GetAllLayerNames( $self->{"layerCnt"} ) } = ();

	$layers{$_} = 0 foreach keys %layers;
	$layers{$_} = 1 foreach @gndLayers;

	if ( scalar(@strips) > 1 ) {

		# stirp in same column
		my $s2 = ( grep { $_->Id() ne $stripVariant->Id() } @strips )[0];
		if ( $secondPos && ( $s2->GetType() eq EnumsImp->Type_SE || $s2->GetType() eq EnumsImp->Type_COSE ) ) {
			$layers{$_} = 0 foreach keys %layers;
		}
	}

	return \%layers;
}

# Return origin for microstrip
# Microstrip origin is always in left down pad of microstrip
sub GetMicrostripOrigin {
	my $self         = shift;
	my $stripVariant = shift;

	# X cooredination - left down pad (trakc/GND) of microstrip
	my $x = $self->{"cpnSett"}->GetCouponSingleMargin() / 1000 + $self->{"cpnSingleSett"}->GetPadTrackSize() / 1000 / 2;

	# choose pool
	my $pool = $self->{"singleCpnVar"}->GetPoolByOrder( $stripVariant->Pool() );

	for ( my $i = 0 ; $i < $stripVariant->Col() ; $i++ ) {

		# all strips on current column pos
		my @stripsVar = $self->{"singleCpnVar"}->GetStripsByColumn($i);

		# get positions of pad in x direction (1 or one)

		my @pos = map { $self->GetMicrostripPosCnt( $_, "x" ) } (@stripsVar);

		$x += ( max(@pos) - 1 ) * $self->{"cpnSingleSett"}->GetPad2PadDist() / 1000 + $self->{"cpnSingleSett"}->GetGroupPadsDist() / 1000;
	}

	# Y cooredination - left down pad (trakc/GND) of microstrip
	my $y = undef;

	# bottom pool

	$y = $self->{"cpnSett"}->GetCouponSingleMargin() / 1000;
	$y += $self->{"cpnSingleSett"}->GetPadTrackSize() / 2 / 1000;    # half of track pad size

	# space for bottom routes in whole pool strip if exist
	my $botPool = $self->{"singleCpnVar"}->GetPoolByOrder(0);
	my @spaces = map { $_->RouteDist() + $_->RouteWidth() / 2 } grep { $_->Route() eq Enums->Route_BELOW } $botPool->GetStrips();
	if (@spaces) {
		$y -= $self->{"cpnSingleSett"}->GetPadTrackSize() / 2 / 1000;
		$y += max(@spaces);
	}

	# top pool

	if ( $pool->GetOrder() == 1 ) {

		$y += $self->{"cpnSingleSett"}->GetTrackPad2GNDPad() / 1000;

	}

	return PointLayout->new( $x, $y );
}

# return height including title text height
sub GetCpnSingleArea {
	my $self = shift;

	my %areaInfo = ( "pos" => undef, "w" => undef, "h" => undef );

	my %stripArea = $self->GetActiveArea();

	# compute position
	$areaInfo{"pos"} = PointLayout->new( $self->{"cpnSett"}->GetCouponMargin() / 1000, $self->{"cpnSett"}->GetCouponMargin() / 1000 );

	# compute width
	my $w = 2 * $self->{"cpnSett"}->GetCouponSingleMargin() / 1000 + $stripArea{"w"};

	# consider right text
	if ( $self->{"cpnSett"}->GetInfoText() ) {

		my $textLayout = $self->{"layout"}->GetInfoTextLayout();

		die "Infot text layout is not defined " unless ( defined $textLayout );

		if ( $self->{"cpnSett"}->GetInfoTextPosition() eq "right" ) {
			$w += $self->{"cpnSett"}->GetInfoTextRightCpnDist() / 1000 + $textLayout->GetWidth();
		}
	}

	$areaInfo{"w"} = $w;

	# compute height
	my $h = 2 * $self->{"cpnSett"}->GetCouponSingleMargin() / 1000 + $stripArea{"h"};

	# consider top texts
	if ( $self->{"cpnSett"}->GetInfoText() ) {

		my $textLayout = $self->{"layout"}->GetInfoTextLayout();

		die "Infot text layout is not defined " unless ( defined $textLayout );

		if ( $self->{"cpnSett"}->GetInfoTextPosition() eq "top" ) {

			$h += $self->{"cpnSett"}->GetPadsTopTextDist() / 1000;
			$h += $textLayout->GetHeight();

		}
		elsif ( $self->{"cpnSett"}->GetInfoTextPosition() eq "right" ) {

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
	$areaInfo{"pos"} = PointLayout->new( $self->{"cpnSett"}->GetCouponSingleMargin() / 1000, $self->{"cpnSett"}->GetCouponSingleMargin() / 1000 );

	# compute width
	$areaInfo{"w"} = $self->{"cpnSingleSett"}->GetCpnSingleWidth() - 2 * $self->{"cpnSett"}->GetCouponSingleMargin() / 1000;

	# compute height
	my $h = undef;

	if ( $self->{"singleCpnVar"}->IsMultistrip() ) {

		my @poolsVar = $self->{"singleCpnVar"}->GetPools();

		my $padsY = 2;

		if ( scalar(@poolsVar) == 2 ) {
			$padsY = 3;
		}

		$h = ( $padsY - 1 ) * $self->{"cpnSingleSett"}->GetTrackPad2TrackPad() / 1000 + $self->{"cpnSingleSett"}->GetPadTrackSize() / 1000;

		foreach my $poolVar (@poolsVar) {

			# check if pool "bottom" contains track route type "below"
			if ( $poolVar->GetOrder() == 0 ) {

				my @spaces = map { $_->RouteDist() + $_->RouteWidth() / 2 } grep { $_->Route() eq Enums->Route_BELOW } $poolVar->GetStrips();
				if (@spaces) {
					$h += max(@spaces);
					$h -= $self->{"cpnSingleSett"}->GetPadTrackSize() / 1000 / 2;    # route is higher than pad anular ring
				}

			}

			# check if pool "top" contains track route type "above"
			elsif ( $poolVar->GetOrder() == 1 ) {

				my @spaces = map { $_->RouteDist() + $_->RouteWidth() / 2 } grep { $_->Route() eq Enums->Route_ABOVE } $poolVar->GetStrips();
				if (@spaces) {
					$h += max(@spaces);
					$h -= $self->{"cpnSingleSett"}->GetPadTrackSize() / 1000 / 2;    # route is higher than pad anular ring
				}

			}

		}
	}

	# single strip
	else {

		my $strip = ( map { $_->GetStrips() } $self->{"singleCpnVar"}->GetPools() )[0];

		my $padsY = $self->GetMicrostripPosCnt( $strip, "y" );

		$h = ( $padsY - 1 ) * $self->{"cpnSingleSett"}->GetTrackPad2TrackPad() / 1000 + $self->{"cpnSingleSett"}->GetPadTrackSize() / 1000;
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
	$multiStrip{ EnumsImp->Type_SE }{"x"}     = 1;
	$multiStrip{ EnumsImp->Type_SE }{"y"}     = 2;
	$multiStrip{ EnumsImp->Type_DIFF }{"x"}   = 2;
	$multiStrip{ EnumsImp->Type_DIFF }{"y"}   = 2;
	$multiStrip{ EnumsImp->Type_COSE }{"x"}   = 1;
	$multiStrip{ EnumsImp->Type_COSE }{"y"}   = 2;
	$multiStrip{ EnumsImp->Type_CODIFF }{"x"} = 2;
	$multiStrip{ EnumsImp->Type_CODIFF }{"y"} = 2;

	my %singleStrip = ();
	$singleStrip{ EnumsImp->Type_SE }{"x"}     = 2;
	$singleStrip{ EnumsImp->Type_SE }{"y"}     = 1;
	$singleStrip{ EnumsImp->Type_DIFF }{"x"}   = 2;
	$singleStrip{ EnumsImp->Type_DIFF }{"y"}   = 2;
	$singleStrip{ EnumsImp->Type_COSE }{"x"}   = 2;
	$singleStrip{ EnumsImp->Type_COSE }{"y"}   = 1;
	$singleStrip{ EnumsImp->Type_CODIFF }{"x"} = 2;
	$singleStrip{ EnumsImp->Type_CODIFF }{"y"} = 2;

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

