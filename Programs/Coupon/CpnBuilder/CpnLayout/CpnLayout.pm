
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::CpnLayout;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::CpnSingleLayout';

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
	$self->{"titleLayout"} = undef;
	$self->{"couponsSingle"} = [];
	
	$self->{"globalSett"} = undef;

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


sub SetTitleLayout {
	my $self = shift;

	$self->{"titleLayout"} = shift;

}

sub GetTitleLayout {
	my $self = shift;

	return $self->{"titleLayout"};

}

sub SetGlobalSett {
	my $self = shift;
 
	$self->{"globalSett"} = shift;

}

sub GetGlobalSett {
	my $self = shift;

	return $self->{"globalSett"};

}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

