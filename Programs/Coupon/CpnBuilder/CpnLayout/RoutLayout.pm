
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

	$self->{"countourMech"}        = undef;                                                   # 0/1
	$self->{"countourTypeX"}       = undef;                                                   # none/rout/score
	$self->{"countourBridgesCntX"} = undef;                                                   # number of bridges on horizontal edge
	$self->{"countourTypeY"}       = undef;                                                   # none/rout/score
	$self->{"countourBridgesCntY"} = undef;                                                   # number of bridges on vertical edge
	$self->{"bridgesWidth"}        = undef;                                                   # Width of bridges gap
	$self->{"__CLASS__"}           = "Programs::Coupon::CpnBuilder::CpnLayout::RoutLayout";

	return $self;

}

sub SetCountourMech {
	my $self    = shift;
	my $outline = shift;

	$self->{"countourMech"} = $outline;
}

sub GetCountourMech {
	my $self = shift;

	return $self->{"countourMech"};
}

sub SetCountourTypeX {
	my $self = shift;
	my $type = shift;

	$self->{"countourTypeX"} = $type;
}

sub GetCountourTypeX {
	my $self = shift;

	return $self->{"countourTypeX"};
}

sub SetCountourBridgesCntX {
	my $self       = shift;
	my $bridgesCnt = shift;

	$self->{"countourBridgesCntX"} = $bridgesCnt;
}

sub GetCountourBridgesCntX {
	my $self = shift;

	return $self->{"countourBridgesCntX"};
}

sub SetCountourTypeY {
	my $self = shift;
	my $type = shift;

	$self->{"countourTypeY"} = $type;
}

sub GetCountourTypeY {
	my $self = shift;

	return $self->{"countourTypeY"};
}

sub SetCountourBridgesCntY {
	my $self       = shift;
	my $bridgesCnt = shift;

	$self->{"countourBridgesCntY"} = $bridgesCnt;
}

sub GetCountourBridgesCntY {
	my $self = shift;

	return $self->{"countourBridgesCntY"};
}

sub SetBridgesWidth {
	my $self    = shift;
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

