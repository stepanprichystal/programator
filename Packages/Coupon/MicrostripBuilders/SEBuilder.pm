
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb POOL
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::MicrostripBuilders::SEBuilder;
use base('Packages::Coupon::MicrostripBuilders::MicrostripBuilderBase');

use Class::Interface;
&implements('Packages::Coupon::MicrostripBuilders::IMicrostripBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::SymbolDrawing::Point';

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
	my $self        = shift;
	my $couponSingl = shift;
	my $StipPos     = shift;    # position of micsrtostrip pads if more misrostrip on one coupon

	my %data = ();

	# compute track dimension, pads

	# All variants of pads
	# - one single on coupon => gnd pad below track pad (in vertical line)
	# - more singles on coupon => all gnd pads in one horizontal line

	

	# set model

	my $areaW   = $self->{"settings"}->GetAreaWidth();
	my $margin  = $self->{"settings"}->GetCouponSingleMargin();
	my $p2pDist = $self->{"settings"}->GetPad2PadDist();

	if ( $couponSingl->IsMultistrip() ) {

		die "multistr";

	}
	else {

		# build GND pads

		$data{"sGNDPad"} = Point->new( $self->{"origin"}->X() + $margin,          $self->{"origin"}->Y() + $margin );
		$data{"eGNDPad"} = Point->new( $self->{"origin"}->X() + $areaW - $margin, $self->{"origin"}->Y() + $margin );

		# build Track pads

		$data{"sSigPad"} = Point->new( $self->{"origin"}->X() + $margin + $p2pDist,          $self->{"origin"}->Y() + $margin );
		$data{"eSigPad"} = Point->new( $self->{"origin"}->X() + $areaW - $margin - $p2pDist, $self->{"origin"}->Y() + $margin );

		# build line
		$data{"line"}->{"s"} = $data{"sSigPad"};
		$data{"line"}->{"e"} = $data{"eSigPad"};
		my $par = ( grep { $_->{"NAME"} eq "WB" } $self->{"settingsConstr"}->findnodes('./PARAMS/IMPEDANCE_CONSTRAINT_PARAMETER') )[0];

		$data{"line"}->{"w"} = $par->getAttribute('DOUBLE_VALUE');

	}
	
	$self->{"modelBuilder"}->Build(\%data);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

