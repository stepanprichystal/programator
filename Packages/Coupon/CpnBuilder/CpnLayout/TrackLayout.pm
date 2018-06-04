
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::CpnLayout::TrackLayout;

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
 
	$self->{"points"} = shift;
 	$self->{"width"} = shift;
 
	return $self;
 
}
 
sub AddTrackPoint{
	my $self  = shift;
	my $point = shift;
	
	push(@{$self->{"points"}}, $point);
	
} 

sub GetPoints{
	my $self  = shift;
	
	return @{$self->{"points"}};
}
 
sub GetWidth{
	my $self  = shift;
	
	return $self->{"width"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

