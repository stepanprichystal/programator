
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::CpnLayout::PadLayout;

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
	
	$self->{"point"} = shift;
 	$self->{"type"} = shift;
	$self->{"shareGNDLayers"} = shift; # Tell which layer has to contain GND pads (connected to ground in this layer)
  	$self->{"padText"} = shift;
	return $self;

}

sub GetPoint{
	my $self = shift;
	
	return $self->{"point"};
}

sub GetType{
	my $self = shift;
	
	return $self->{"type"};
}



sub GetShareGndLayers{
	my $self = shift;
	
	return $self->{"shareGNDLayers"};
}

sub GetPadText{
	my $self = shift;
	
	return $self->{"padText"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

