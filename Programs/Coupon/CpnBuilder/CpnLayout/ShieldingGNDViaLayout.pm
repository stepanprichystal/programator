
#-------------------------------------------------------------------------------------------#
# Description: Shielding layout for coplanar misrostrips
# Contain ground via definition
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::ShieldingGNDViaLayout;
use base qw(Programs::Coupon::CpnBuilder::CpnLayout::CpnLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	# Via definition
	$self->{"viaHoleSize"}     = undef;
	$self->{"viaHoleRing"}     = undef;
	$self->{"viaHoleDX"}       = undef;
	$self->{"viaHole2GNDDist"} = undef;
	$self->{"unMaskGNDVia"}     = undef;
	$self->{"filledGNDVia"}     = undef;
	

	return $self;

}

sub SetGNDViaHoleSize {
	my $self = shift;
	my $sym  = shift;

	$self->{"viaHoleSize"} = $sym;
}

sub GetGNDViaHoleSize {
	my $self = shift;

	return $self->{"viaHoleSize"};
}

sub SetGNDViaHoleRing {
	my $self = shift;
	my $val  = shift;

	$self->{"viaHoleRing"} = $val;
}

sub GetGNDViaHoleRing {
	my $self = shift;

	return $self->{"viaHoleRing"};
}

sub SetGNDViaHoleDX {
	my $self = shift;
	my $val  = shift;

	$self->{"viaHoleDX"} = $val;
}

sub GetGNDViaHoleDX {
	my $self = shift;

	return $self->{"viaHoleDX"};
}

sub SetGNDViaHole2GNDDist {
	my $self = shift;
	my $val  = shift;

	$self->{"viaHole2GNDDist"} = $val;
}

sub GetGNDViaHole2GNDDist {
	my $self = shift;

	return $self->{"viaHole2GNDDist"};
}


sub SetUnMaskGNDVia {
	my $self = shift;
	my $val  = shift;

	$self->{"unMaskGNDVia"} = $val;
}

sub GetUnMaskGNDVia {
	my $self = shift;

	return $self->{"unMaskGNDVia"};
}


sub SetFilledGNDVia {
	my $self = shift;
	my $val  = shift;

	$self->{"filledGNDVia"} = $val;
}

sub GetFilledGNDVia {
	my $self = shift;

	return $self->{"filledGNDVia"};
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

