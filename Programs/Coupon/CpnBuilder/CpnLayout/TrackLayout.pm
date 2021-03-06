
#-------------------------------------------------------------------------------------------#
# Description: Layout for one microstrip track
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::TrackLayout;
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

	$self->{"points"}       = shift;
	$self->{"width"}        = shift;
	$self->{"GNDDistance"}  = shift;    # specify track clearance from GND (only coplanar types)

	return $self;
}

sub AddTrackPoint {
	my $self  = shift;
	my $point = shift;

	push( @{ $self->{"points"} }, $point );

}

sub GetPoints {
	my $self = shift;

	return @{ $self->{"points"} };
}

sub GetWidth {
	my $self = shift;

	return $self->{"width"};
}

sub SetGNDDist {
	my $self    = shift;
	my $gndDist = shift;

	$self->{"GNDDistance"} = $gndDist;
}

sub GetGNDDist {
	my $self = shift;

	return $self->{"GNDDistance"};
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

