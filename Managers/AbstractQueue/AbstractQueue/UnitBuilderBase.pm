
#-------------------------------------------------------------------------------------------#
# Description: Base class, responsible for initialiyation "worker unit", which are processed
# by worker class in child thread
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::AbstractQueue::UnitBuilderBase;
 

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
	
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"jobStrData"} = shift; # serialized task data necessary for task procession

	return $self;
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 

}

1;

