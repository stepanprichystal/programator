
#-------------------------------------------------------------------------------------------#
# Description: Shielding layout for one coupon group
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::ShieldingLayout;
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

	$self->{"type"} = undef;    # top/right

	# Properties for shielding type - symbol
	$self->{"symbol"}   = undef;
	$self->{"symbolDX"} = undef;
	$self->{"symbolDY"} = undef;

	$self->{"texts"} = [];

	return $self;

}

sub SetType {
	my $self = shift;
	my $type = shift;

	$self->{"type"} = $type;
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub SetSymbol {
	my $self = shift;
	my $sym  = shift;

	$self->{"symbol"} = $sym;
}

sub GetSymbol {
	my $self = shift;

	return $self->{"symbol"};
}

sub SetSymbolDX {
	my $self = shift;
	my $sym  = shift;

	$self->{"symbolDX"} = $sym;
}

sub GetSymbolDX {
	my $self = shift;

	return $self->{"symbolDX"};
}

sub SetSymbolDY {
	my $self = shift;
	my $sym  = shift;

	$self->{"symbolDY"} = $sym;
}

sub GetSymbolDY {
	my $self = shift;

	return $self->{"symbolDY"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

