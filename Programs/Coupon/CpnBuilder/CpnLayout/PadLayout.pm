
#-------------------------------------------------------------------------------------------#
# Description: Layout for one microstrip pad
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::PadLayout;
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

	$self->{"point"}          = shift;
	$self->{"type"}           = shift;
	$self->{"shareGNDLayers"} = shift;    # Tell which layer has to contain GND pads (connected to ground in this layer)
	$self->{"padText"}        = shift;
	return $self;

}

sub GetPoint {
	my $self = shift;

	return $self->{"point"};
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub GetShareGndLayers {
	my $self = shift;

	return $self->{"shareGNDLayers"};
}

sub GetPadText {
	my $self = shift;

	return $self->{"padText"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

