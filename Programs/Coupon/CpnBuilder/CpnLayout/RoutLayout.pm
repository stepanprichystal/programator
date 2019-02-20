
#-------------------------------------------------------------------------------------------#
# Description: Outline rout layout for whole coupon
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::RoutLayout;
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

	$self->{"outlineRout"}     = undef;                                                   # 0/1
	$self->{"bridges"}     = undef;                                                   # 0/1
	$self->{"bridgesX"}     = undef;                                                   # do bridges on horiyontal edges 0/1
	$self->{"bridgesY"}     = undef;                                                   # do bridges on vertical edges 0/1
	$self->{"bridgesWidth"} = undef;                                                   # Width of bridges gap
	$self->{"__CLASS__"}   = "Programs::Coupon::CpnBuilder::CpnLayout::RoutLayout";

	return $self;

}

sub SetOutlineRout {
	my $self   = shift;
	my $outline = shift;

	$self->{"outlineRout"} = $outline;
}

sub GetOutlineRout {
	my $self = shift;

	return $self->{"outlineRout"};
}

sub SetBridges {
	my $self   = shift;
	my $bridges = shift;

	$self->{"bridges"} = $bridges;
}

sub GetBridges {
	my $self = shift;

	return $self->{"bridges"};
}

sub SetBridgesX {
	my $self   = shift;
	my $bridges = shift;

	$self->{"bridgesX"} = $bridges;
}

sub GetBridgesX {
	my $self = shift;

	return $self->{"bridgesX"};
}

sub SetBridgesY {
	my $self   = shift;
	my $bridges = shift;

	$self->{"bridgesY"} = $bridges;
}

sub GetBridgesY {
	my $self = shift;

	return $self->{"bridgesY"};
}

sub SetBridgesWidth {
	my $self   = shift;
	my $bridges = shift;

	$self->{"bridgesWidth"} = $bridges;
}

sub GetBridgesWidth {
	my $self = shift;

	return $self->{"bridgesWidth"};
}
 
sub TO_JSON { return { %{ shift() } }; }

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

