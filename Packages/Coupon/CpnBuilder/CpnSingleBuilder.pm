
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

			if ( $mStripBuilder->Build(  $errMess ) ) {

				$self->{"layout"}->AddMicrostripLayout( $mStripBuilder->GetLayout() )

			}
			else {

				$result = 0;
			}

			push( @{ $self->{"microstrips"} }, $mStripBuilder );
		}
	}

	if ($result) {
		$self->{"layout"}->SetHeight( $self->GetHeight() );
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

sub GetHeight {
	my $self = shift;

	die "coupon was not builded" unless ( $self->{"build"} );

	my $max = undef;

	foreach my $microstrip ( @{ $self->{"microstrips"} } ) {

		if ( !defined $max || $microstrip->GetHeight() > $max ) {
			$max = $microstrip->GetHeight();
		}

	}

	return $max;
}

# Return origin for microstrip
# Microstrip origin is always in left down pad of microstrip
sub GetMicrostripOrigin {
	my $self         = shift;
	my $stripBuilder = shift;              # idof microstrip order
	 

	my $stripVariant = $stripBuilder->GetStripVariant();

	# X cooredination - left down pad (trakc/GND) of microstrip
	my $x = $self->{"settings"}->GetCouponSingleMargin();

	# choose pool
	my $pool = $self->{"singleCpnVar"}->GetPoolByOrder( $stripVariant->Pool() );

	for ( my $i = 0 ; $i < $stripVariant->Col() ; $i++ ) {

		# all strips on current column pos
		my @stripsVar = $self->{"singleCpnVar"}->GetStripsByColumn($i);

		# get positions of pad in x direction (1 or one)

		my @pos = map { $self->__GetMicrostripById( $_->Id() )->GetPadPosXCnt() } (@stripsVar);

		$x += ( max(@pos) - 1 ) * $self->{"settings"}->GetPad2PadDist() + $self->{"settings"}->GetGroupPadsDist();
	}

	# Y cooredination - left down pad (trakc/GND) of microstrip
	my $y = undef;

	# bottom pool
	if ( $pool->GetOrder() == 0 ) {

		$y = $self->{"settings"}->GetCouponSingleMargin();
		$y += $self->{"settings"}->GetPadTrackSize() / 2 / 1000;    # half of track pad size

		# space for bottom routes in whole pool strip
		$y += max( map { $_->RouteDist() } grep { $_->Route() eq Enums->Route_BELOW } $pool->GetStrips() );

	}

	# Add to y coordineate for pool order 0 "disetance" between GND and track pad
	if ( $pool->GetOrder() == 1 ) {

		$y += $self->{"settings"}->GetTracePad2GNDPad() / 1000;

	}
 
	return Point->new( $x, $y );
}

sub __GetMicrostripById {
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

