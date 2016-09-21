
#-------------------------------------------------------------------------------------------#
# Description: Base class for stackup layer. Contain common properties for different types
# of stackup layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::Layer::StackupLayer;

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

	#Enums->MaterialType
	$self->{"type"} 	= undef;  
	
	#thick of layer, if prepreg thick of prepreg. 
	#If more prepregs together, thick of all prepregs
	$self->{"thick"}    = undef;  
	
	#phzsic name of core, preprags.. e.g Prepreg 1080
	$self->{"text"}     = undef; 
	 
	# type of material eg FR4, IS410 
	$self->{"typetext"} = undef;
	

	return $self;  
}

# return type of layer
# MaterialType_COPPER => "copper",
# MaterialType_PREPREG => "prepreg",
# MaterialType_CORE => "core",
sub GetType{
	my $self = shift;
	return $self->{"type"};
}

#return thick of layer
sub GetThick{
	my $self = shift;
	return $self->{"thick"};
}

 
sub GetText{
	my $self = shift;
	return $self->{"text"};
}

sub GetTextType{
	my $self = shift;
	return $self->{"typetext"};
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

