
#-------------------------------------------------------------------------------------------#
# Description: Contain inforamtion about stacku layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::Press::StackupPress;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	
	my $self = shift;
	$self = {};
	bless $self;

	#Pressing order
	$self->{"order"} 	= shift;  

	#top pressing layer name
	$self->{"top"}    = shift;  
	
	#top pressing layer number c=1, v2 = 2, etc..
	$self->{"topNumber"}    = shift;  

	#bot pressing layer name
	$self->{"bot"}    = shift;  
	
	#bot pressing layer number c=1, v2 = 2, etc..
	$self->{"botNumber"}    = shift; 
	

	return $self;  
}

sub GetPressOrder{
	my $self = shift;
	
	return $self->{"order"};
}
 
sub GetTopCopperLayer{
	my $self = shift;
	
	return $self->{"top"};
}

sub GetBotCopperLayer{
	my $self = shift;
	
	return $self->{"bot"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
