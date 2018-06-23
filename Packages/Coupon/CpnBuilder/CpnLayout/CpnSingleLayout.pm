
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

	$self->{"h"}             = undef;    # dynamic heght of single coupon
	$self->{"stripsLayouts"} = [];
	$self->{"infoTextLayout"} = undef;
	 

	return $self;
}

sub SetInfoTextLayout{
	my $self = shift;
	my $textLayout = shift;
 
	$self->{"infoTextLayout"} = $textLayout;
	 
}

sub SetHeight {
	my $self = shift;

	$self->{"h"} = shift;
}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};
}

sub AddMicrostripLayout {
	my $self = shift;

	push( @{ $self->{"stripsLayouts"} }, shift );
}

sub GetMicrostripLayouts {
	my $self = shift;

	return @{ $self->{"stripsLayouts"} };

}

sub GetInfoTextLayout{
	my $self = shift;
	
	return $self->{"infoTextLayout"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

