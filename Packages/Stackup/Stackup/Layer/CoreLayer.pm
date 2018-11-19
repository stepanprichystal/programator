
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


sub GetCoreNumber{
	my $self = shift;
	return $self->{"coreNumber"};
}

sub GetQId{
	my $self = shift;
	
	return $self->{"qId"};
}

# Return plating value (if no requested combination Cu + core material on stock, cores has to be plated by 25um)
sub GetPlatingExists {
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
# Decision is basend on core thickness (less than 100µm is flex core )
sub GetCoreRigidType{
	my $self = shift;
	
	if($self->GetThick() < 100){
		
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

