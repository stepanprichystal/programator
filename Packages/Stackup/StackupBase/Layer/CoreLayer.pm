
#-------------------------------------------------------------------------------------------#
# Description: Special layer - core, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::Layer::CoreLayer;
use base('Packages::Stackup::StackupBase::Layer::StackupLayerBase');

use Class::Interface;
&implements('Packages::Stackup::StackupBase::Layer::IStackupLayer');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Stackup::Enums';

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
	
	# Identification of material by Multicall ml.xml
		
	$self->{"qId"}     = undef;  # quality of material
		
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

# Start with 1
sub GetCoreNumber{
	my $self = shift;
	return $self->{"coreNumber"};
}

sub GetQId{
	my $self = shift;
	
	return $self->{"qId"};
}

# Return plating value (if no requested combination Cu + core material on stock, cores has to be plated by 25um)
sub GetCoreExtraPlating {
	my $self = shift;

	# check if plating exist on both side
	my $plating = 0;
 
	# if Copper Id is negative it means plating 25um
	if ( $self->{"topCopperLayer"}->GetId() < 0 ) {

		$plating = 1;
	}

	return $plating;

}

# Return if core is rigid or flex
# Decision is basend on core thickness (less than 90µm is flex core )
# TODO - read core type from HEG core specificatiopn (rigid and flex core can have same thickness)
sub GetCoreRigidType{
	my $self = shift;
	
	if($self->GetThick() < 90){
		
		return Enums->CoreType_FLEX;
	
	}else{
		
		return Enums->CoreType_RIGID;
	}
	
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

