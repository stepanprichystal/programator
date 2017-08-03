#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::CheckInfo;

#3th party library
use strict;
use warnings;
 

#local library
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

 	$self->{"description"} = shift;
 	$self->{"key"} = shift;
 	$self->{"mess"} = shift;
 
	return $self;
}


sub GetDesc{
	my $self = shift;
	
	return $self->{"description"};
}

sub GetKey{
	my $self = shift;
	
	return $self->{"key"};
}


sub GetMessage{
	my $self = shift;
	
	return $self->{"mess"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

