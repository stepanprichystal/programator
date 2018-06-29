
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::CpnLayout::CpnLayout;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Coupon::CpnBuilder::CpnLayout::CpnSingleLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"stepName"} = undef;
	$self->{"w"}        = undef;
	$self->{"h"}        = undef;


	$self->{"couponsSingle"} = [];

	return $self;

}

sub SetWidth {
	my $self = shift;

	$self->{"w"} = shift;

}

sub SetHeight {
	my $self = shift;

	$self->{"h"} = shift;

}

sub GetWidth {
	my $self = shift;

	return $self->{"w"};

}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};

}

sub SetStepName {
	my $self = shift;

	$self->{"stepName"} = shift;

}

sub GetStepName {
	my $self = shift;

	return $self->{"stepName"};

}

sub AddCouponSingle {
	my $self = shift;

	push( @{ $self->{"couponsSingle"} }, shift );
}

sub GetCouponsSingle {
	my $self = shift;

	return @{ $self->{"couponsSingle"} };

}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

