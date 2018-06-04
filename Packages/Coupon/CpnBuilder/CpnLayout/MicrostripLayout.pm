
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::CpnLayout::MicrostripLayout;

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

	# Microstrip layout properties
	$self->{"pads"}   = [];
	$self->{"tracks"} = [];

	# Microstript model properties
	$self->{"microstripModel"} = undef;

	$self->{"trackLayer"}  = undef;
	$self->{"topRefLayer"} = undef;
	$self->{"botRefLayer"} = undef;

	return $self;
}

sub SetModel {
	my $self = shift;

	$self->{"microstripModel"} = shift;
}

sub GetModel {
	my $self = shift;

	return $self->{"microstripModel"};
}

sub SetTrackLayer {
	my $self = shift;

	$self->{"trackLayer"} = shift;
}

sub GetTrackLayer {
	my $self = shift;

	return $self->{"trackLayer"};
}

sub SetTopRefLayer {
	my $self = shift;

	$self->{"topRefLayer"} = shift;
}

sub GetTopRefLayer {
	my $self = shift;

	return $self->{"topRefLayer"};
}

sub SetBotRefLayer {
	my $self = shift;

	$self->{"botRefLayer"} = shift;
}

sub GetBotRefLayer {
	my $self = shift;

	return $self->{"botRefLayer"};
}

sub AddPad {
	my $self = shift;

	push( @{ $self->{"pads"} }, shift );
}

sub GetPads {
	my $self = shift;
	my $type = shift;

	my @pads = @{ $self->{"pads"} };

	if ($type) {

		@pads = grep { $_->GetType() eq $type } @pads;
	}

	return @pads;
}

sub AddTrack {
	my $self = shift;

	push( @{ $self->{"tracks"} }, shift );
}

sub GetTracks {
	my $self = shift;

	return @{ $self->{"tracks"} };

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

