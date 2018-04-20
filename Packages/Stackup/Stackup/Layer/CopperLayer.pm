
#-------------------------------------------------------------------------------------------#
# Description: Special layer - Copper, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::Layer::CopperLayer;
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


	#only if materialType is copper
	$self->{"usage"}    = undef;  
	
	#only if materialType is copper
	$self->{"copperName"}    = undef;  
	
	# c = 1, v2 = 2, v3 = 3, v4 = 4,......, s = order of last layer
	$self->{"copperNumber"} = undef;
	
	return $self;  
}


# return name of copper. Name can be
# c, v2, v3, v4,......, s
sub GetCopperName{
	my $self = shift;
	return $self->{"copperName"};
}

# Return number from 1 to infinity, according count of cu layers
# c = 1, v2 = 2, v3 = 3, v4 = 4,......, s = order of last layer
sub GetCopperNumber{
	my $self = shift;
	return $self->{"copperNumber"};
}

sub GetUssage{
	my $self = shift;
	return $self->{"usage"};
}

# Return plating value (if no requested combination Cu + core material on stock, cores has to be plated by 25um)
sub GetPlatingExists {
	my $self = shift;

	# check if plating exist on both side
	my $plating = 0;
 
	# if Copper Id is negative it means plating 25um
	if ( $self->GetId() < 0 ) {

		$plating = 1;
	}

	return $plating;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

