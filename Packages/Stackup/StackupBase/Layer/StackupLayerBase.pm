
#-------------------------------------------------------------------------------------------#
# Description: Base class for stackup layer. Contain common properties for different types
# of stackup layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::Layer::StackupLayerBase;

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
	
	# Identification of material by Multicall ml.xml

	
	$self->{"id"}     = undef;  # id of material
	

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

sub GetId{
	my $self = shift;
	return $self->{"id"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

