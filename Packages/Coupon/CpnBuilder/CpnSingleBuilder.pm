
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

	$self->{"settings"}    = shift;    # global settings for generating coupon
	$self->{"constraints"} = shift;    # list of constrain object (based on instack Job xml)

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

	for ( my $i = 0 ; $i < scalar( @{ $self->{"constraints"} } ) ; $i++ ) {

		my $constr = $self->{"constraints"}->[$i];

		my $mStripBuilder = undef;

		switch ( $constr->GetType() ) {

			case Enums->Type_SE { $mStripBuilder = SEBuilder->new() }

			  case Enums->Type_DIFF { $mStripBuilder = DiffBuilder->new() }

			  else { die "Microstirp type: " . $constr->GetType() . "is not implemented"; }
		}

		$mStripBuilder->Init( $inCAM, $jobId, $self->{"settings"}, $constr );

		# Set property common for all microstrip types

		if ( $mStripBuilder->Build( $self, $errMess ) ) {

			$self->{"layout"}->AddMicrostripLayout( $mStripBuilder->GetLayout() )

		}
		else {

			$result = 0;
		}

		push( @{ $self->{"microstrips"} }, $mStripBuilder );

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

	return scalar( @{ $self->{"constraints"} } ) > 1 ? 1 : 0;
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

sub GetMicrostripOrigin {
	my $self = shift;
	my $id   = shift;    # idof microstrip order

	if ( $id > scalar( @{ $self->{"microstrips"} } ) ) {

		die "Unable to compute origin for Microstirp order id:" . $id;
	}

	my $x = $self->{"settings"}->GetCouponSingleMargin();

	for ( my $i = 0 ; $i < $id ; $i++ ) {

		my $strip = $self->{"microstrips"}->[$i];

		$x += ( $strip->GetPadPositionsCnt() - 1 ) * $self->{"settings"}->GetPad2PadDist() + $self->{"settings"}->GetGroupPadsDist();
	}

	my $y = $self->{"settings"}->GetCouponSingleMargin();

	return Point->new( $x, $y );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

