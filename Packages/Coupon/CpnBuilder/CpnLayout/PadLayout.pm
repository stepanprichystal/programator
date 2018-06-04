
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
 	$self->{"symbol"} = shift;
	
  
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

sub GetSymbol{
	my $self = shift;
	
	return $self->{"symbol"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

