
#-------------------------------------------------------------------------------------------#
# Description: Layer layout for one layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::LayerLayout;
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

	$self->{"layerName"} = shift;

	# Mirror set by job stackup
	$self->{"mirror"} = undef;    #

	# More microstrip use layer as GND
	$self->{"shareGND"} = undef;

	return $self;

}

sub SetMirror {
	my $self   = shift;
	my $mirror = shift;

	$self->{"mirror"} = $mirror;
}

sub GetMirror {
	my $self = shift;

	return $self->{"mirror"};
}

sub SetShareGND {
	my $self   = shift;
	my $mirror = shift;

	$self->{"shareGND"} = $mirror;
}

sub GetShareGND {
	my $self = shift;

	die "share GND is not implemented";

	return $self->{"shareGND"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

