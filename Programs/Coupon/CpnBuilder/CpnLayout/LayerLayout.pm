
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
	
	# Polarity
	$self->{"polarity"} = undef;    #	
	
	# Layer type
	$self->{"type"} = undef;    #	

	# More microstrip use layer as GND
	$self->{"shareGND"} = undef;

	return $self;

}

sub SetLayerName {
	my $self   = shift;
	my $layerName = shift;

	$self->{"layerName"} = $layerName;
}

sub GetLayerName {
	my $self = shift;

	return $self->{"layerName"};
}

sub SetType {
	my $self   = shift;
	my $type = shift;

	$self->{"type"} = $type;
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub SetPolarity {
	my $self   = shift;
	my $polar = shift;

	$self->{"polarity"} = $polar;
}

sub GetPolarity {
	my $self = shift;

	return $self->{"polarity"};
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

