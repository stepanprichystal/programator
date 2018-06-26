
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::CpnLayout::CpnSingleLayout;

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
	bless $self;

	$self->{"h"}              = undef;    # dynamic heght of single coupon
	$self->{"w"}              = undef;    # dynamic width of single coupo (active area width + text on rights)
	$self->{"stripsLayouts"}  = [];
	$self->{"infoTextLayout"} = undef;
	$self->{"guardTracksLayout"} = undef;

	return $self;
}



sub SetHeight {
	my $self = shift;

	$self->{"h"} = shift;
}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};
}

sub SetWidth {
	my $self  = shift;
	my $width = shift;

	$self->{"w"} = $width;

}

sub GetWidth {
	my $self = shift;

	return $self->{"w"};
}

sub AddMicrostripLayout {
	my $self = shift;

	push( @{ $self->{"stripsLayouts"} }, shift );
}

sub GetMicrostripLayouts {
	my $self = shift;

	return @{ $self->{"stripsLayouts"} };

}

sub SetInfoTextLayout {
	my $self       = shift;
	my $textLayout = shift;

	$self->{"infoTextLayout"} = $textLayout;

}

sub GetInfoTextLayout {
	my $self = shift;

	return $self->{"infoTextLayout"};
}

sub SetGuardTracksLayout {
	my $self       = shift;
	my $layouts = shift;

	$self->{"guardTracksLayout"} = $layouts

}

sub GetGuardTracksLayout {
	my $self = shift;

	return $self->{"guardTracksLayout"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

