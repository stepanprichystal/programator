
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::GuardTracksLayout;

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

	$self->{"layer"} = shift;

 	$self->{"type"} = undef; #  
  
  	# poperties for type "single"
  	$self->{"lines"} = [];
  	
  	# poperties for type "full"
  	$self->{"areas"} = []; # areas defined as rectangle by four points
 
	return $self;
 
}
 
sub SetType{
	my $self  = shift;
	my $type = shift;
	
	$self->{"type"} = $type;
} 
 
sub GetType{
	my $self  = shift;
	
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

sub GetLayer{
	my $self  = shift;
	
	return $self->{"layer"};
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

