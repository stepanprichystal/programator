
#-------------------------------------------------------------------------------------------#
# Description: Special layer - core, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::Layer::CoreLayer;
use base('Packages::Stackup::Stackup::Layer::StackupLayer');


#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	#tell order of core in stackup (most top is 1, then 2, ...)
	$self->{"coreNumber"}    = undef;  
	
	# reference of top copper layer
	$self->{"topCopperLayer"}    = undef; 
	
	# reference of bot copper layer
	$self->{"botCopperLayer"}    = undef;  
	
	return $self;  
}

sub GetTopCopperLayer{
	my $self = shift;
	
	return $self->{"topCopperLayer"};
}

sub GetBotCopperLayer{
	my $self = shift;
	
	return $self->{"botCopperLayer"};
}


sub GetCoreNumber{
	my $self = shift;
	return $self->{"coreNumber"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

