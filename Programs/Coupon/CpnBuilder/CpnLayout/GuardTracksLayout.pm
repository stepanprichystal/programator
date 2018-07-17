
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::GuardTracksLayout;
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

	$self->{"layer"} = shift;

	$self->{"type"} = undef;    #

	# poperties for type "single"
	$self->{"lines"} = [];

	# poperties for type "full"
	$self->{"areas"} = [];      # areas defined as rectangle by four points
	
	$self->{"guardTrackWidth"} = undef;

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

sub AddLine {
	my $self = shift;

	push( @{ $self->{"lines"} }, shift );
}

sub GetLines {
	my $self = shift;

	return @{ $self->{"lines"} };
}

sub AddArea {
	my $self = shift;

	push( @{ $self->{"areas"} }, shift );
}

sub GetAreas {
	my $self = shift;

	return @{ $self->{"areas"} };
}

sub GetLayer {
	my $self = shift;

	return $self->{"layer"};
}

sub SetGuardTrackWidth {
	my $self = shift;
	my $val  = shift;

	$self->{"guardTrackWidth"} = $val;
}

sub GetGuardTrackWidth {
	my $self = shift;

	return $self->{"guardTrackWidth"};
}

sub SetGuardTrack2Shielding {
	my $self = shift;
	my $val  = shift;

	$self->{"guardTrack2Shielding"} = $val;
}

sub GetGuardTrack2Shielding {
	my $self = shift;

	return $self->{"guardTrack2Shielding"};
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

