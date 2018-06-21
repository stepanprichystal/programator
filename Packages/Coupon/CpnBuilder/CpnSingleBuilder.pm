
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
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Coupon::CpnBuilder::MicrostripBuilders::SEBuilder';
use aliased 'Packages::Coupon::CpnBuilder::MicrostripBuilders::DiffBuilder';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::Coupon::CpnBuilder::CpnLayout::CpnSingleLayout';
use aliased 'Packages::Coupon::CpnBuilder::CpnInfoTextBuilder';

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

	# Coupon area - depand on info text position (right/top)
	# if infot text is on the right, coupon width area is increased by info text width
	my $cpnWArea = $self->{"settings"}->GetWidth() - 2 * $self->{"settings"}->GetCouponMargin();

	# Build text info builders

	if ( $self->{"settings"}->GetInfoText() ) {

		my $textBuilder = CpnInfoTextBuilder->new( $inCAM, $jobId, $self->{"settings"}, $self->{"singleCpnVar"}, $self );

		if ( $textBuilder->Build($errMess) ) {

			my $p          = undef;
			my $textLayout = $textBuilder->GetLayout();

			if ( $textLayout->GetType() eq "right" ) {
				$cpnWArea -= $textLayout->GetWidth();

				$p = Point->new( $self->{"settings"}->GetWidth() - $self->{"settings"}->GetCouponSingleMargin() - $textLayout->GetWidth(),
								 $self->{"settings"}->GetCouponSingleMargin() );

			}
			elsif ( $textLayout->GetType() eq "top" ) {

				#compute

				$p = Point->new( $self->{"settings"}->GetCouponSingleMargin(),
						 $self->{"settings"}->GetCouponSingleMargin() + $self->__GetMicrostripsHeight() + $self->{"settings"}->GetPadsTopTextDist() );

			}

			$self->{"layout"}->SetInfoTextLayout( $textBuilder->GetLayout(), $p );

		}
		else {

			$result = 0;
		}
	}

	# Built miscrostip builers

	foreach my $poolVar ( $self->{"singleCpnVar"}->GetPools() ) {

		foreach my $stripVar ( $poolVar->GetStrips() ) {

			my $mStripBuilder = undef;

			switch ( $stripVar->GetType() ) {

				case Enums->Type_SE { $mStripBuilder = SEBuilder->new() }

				  case Enums->Type_DIFF { $mStripBuilder = DiffBuilder->new() }

				  else { die "Microstirp type: " . $stripVar->GetType() . "is not implemented"; }
			}

			$mStripBuilder->Init( $inCAM, $jobId, $self->{"settings"}, $stripVar, $self );

			# Set property common for all microstrip types

			if ( $mStripBuilder->Build($errMess) ) {

				$self->{"layout"}->AddMicrostripLayout( $mStripBuilder->GetLayout() )

			}
			else {

				$result = 0;
			}

			push( @{ $self->{"microstrips"} }, $mStripBuilder );
		}
	}

	if ($result) {
		$self->{"layout"}->SetHeight( $self->__GetHeight() );
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

sub __GetHeight {
	my $self = shift;

	#die "Coupon single was nopt build " unless ( $self->{"build"} );

	my $h = 2 * $self->{"settings"}->GetCouponSingleMargin();

	$h += $self->__GetMicrostripsHeight();

	if ( $self->{"settings"}->GetInfoText() ) {

		my $textLayout = $self->{"layout"}->GetInfoTextLayout();
		
		die "Infot text layout is not defined " unless(defined $textLayout);

		if ( $self->{"settings"}->GetInfoTextPosition() eq "top" ) {

			$h += $self->{"settings"}->GetPadsTopTextDist();
			$h += $textLayout->GetHeight();

		}
		elsif ( $self->{"settings"}->GetInfoTextPosition() eq "right" ) {

			if ( $textLayout->GetHeight() > $self->__GetMicrostripsHeight() ) {

				$h += $textLayout->GetHeight() - $self->__GetMicrostripsHeight();
			}
		}
	}

	return $h;
}

# Return origin for microstrip
# Microstrip origin is always in left down pad of microstrip
sub GetMicrostripOrigin {
	my $self         = shift;
	my $stripBuilder = shift;    # idof microstrip order

	my $stripVariant = $stripBuilder->GetStripVariant();

	# X cooredination - left down pad (trakc/GND) of microstrip
	my $x = $self->{"settings"}->GetCouponSingleMargin() + $self->{"settings"}->GetPadTrackSize() / 1000 / 2;

	# choose pool
	my $pool = $self->{"singleCpnVar"}->GetPoolByOrder( $stripVariant->Pool() );

	for ( my $i = 0 ; $i < $stripVariant->Col() ; $i++ ) {

		# all strips on current column pos
		my @stripsVar = $self->{"singleCpnVar"}->GetStripsByColumn($i);

		# get positions of pad in x direction (1 or one)

		my @pos = map { $self->__GetMicrostripBuilder( $_->Id() )->GetPadPosXCnt() } (@stripsVar);

		$x += ( max(@pos) - 1 ) * $self->{"settings"}->GetPad2PadDist() + $self->{"settings"}->GetGroupPadsDist();
	}

	# Y cooredination - left down pad (trakc/GND) of microstrip
	my $y = undef;

	# bottom pool
	if ( $pool->GetOrder() == 0 ) {

		$y = $self->{"settings"}->GetCouponSingleMargin();
		$y += $self->{"settings"}->GetPadTrackSize() / 2 / 1000;    # half of track pad size

		# space for bottom routes in whole pool strip if exist
		my @spaces = map { $_->RouteDist() } grep { $_->Route() eq Enums->Route_BELOW } $pool->GetStrips();
		if (@spaces) {
			$y += max(@spaces);
		}

	}

	# Add to y coordineate for pool order 0 "disetance" between GND and track pad
	if ( $pool->GetOrder() == 1 ) {

		$y += $self->{"settings"}->GetTracePad2GNDPad() / 1000;

	}

	return Point->new( $x, $y );
}

# Return height of microstrp area  (withiut info text)
sub __GetMicrostripsHeight {
	my $self = shift;

	my $h = undef;

	if ( $self->{"singleCpnVar"}->IsMultistrip() ) {

		my @poolsVar = $self->{"singleCpnVar"}->GetPools();

		my $padsY = 2;

		if ( scalar(@poolsVar) == 2 ) {
			$padsY = 3;
		}

		$h = ( $padsY - 1 ) * $self->{"settings"}->GetTracePad2TracePad() + $self->{"settings"}->GetPadTrackSize() / 1000;

		foreach my $poolVar (@poolsVar) {

			# check if pool "bottom" contains track route type "below"
			if ( $poolVar->GetOrder() == 0 ) {

				my @spaces = map { $_->RouteDist() } grep { $_->Route() eq Enums->Route_BELOW } $poolVar->GetStrips();
				if (@spaces) {
					$h += max(@spaces);
					$h -= $self->{"settings"}->GetPadTrackSize() / 1000 / 2;    # route is higher than pad anular ring
				}

			}

			# check if pool "top" contains track route type "above"
			elsif ( $poolVar->GetOrder() == 1 ) {

				my @spaces = map { $_->RouteDist() } grep { $_->Route() eq Enums->Route_ABOVE } $poolVar->GetStrips();
				if (@spaces) {
					$h += max(@spaces);
					$h -= $self->{"settings"}->GetPadTrackSize() / 1000 / 2;    # route is higher than pad anular ring
				}

			}

			$h = ( $padsY - 1 ) * $self->{"settings"}->GetTracePad2TracePad() + $self->{"settings"}->GetPadTrackSize() / 1000;
		}
	}

	# single strip
	else {

		my $strip = ( map { $_->GetStrips() } $self->{"singleCpnVar"}->GetPools() )[0];

		my $padsY = $self->__GetMicrostripBuilder( $strip->Id() )->GetPadPosYCnt();

		$h = ( $padsY - 1 ) * $self->{"settings"}->GetTracePad2TracePad() + $self->{"settings"}->GetPadTrackSize() / 1000;
	}

	return $h;
}

sub __GetMicrostripBuilder {
	my $self = shift;
	my $id   = shift;

	my $microstrip = ( grep { $_->GetStripVariant()->Id() eq $id } @{ $self->{"microstrips"} } )[0];

	return $microstrip;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

