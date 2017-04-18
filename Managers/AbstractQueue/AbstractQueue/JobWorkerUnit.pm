#-------------------------------------------------------------------------------------------#
# Description: Base class for unit task classes.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::AbstractQueue::JobWorkerUnit;

#3th party library
use strict;
use warnings;

use aliased 'Packages::Events::Event';
use aliased 'Managers::AbstractQueue::Enums' => "EnumsAbstrQ";
 
#-------------------------------------------------------------------------------------------#
#  NC task, all layers, all machines..
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};

	# PROPERTIES

	$self->{"unitId"} = shift;
	
	$self->{"taskMngr"} = shift; # Class responsible for process specific "task group"

	# Approximate count of tasked items 
	# (because computing progressbar value)
	$self->{"itemsCount"}          = 0;  
	
	$self->{"processedItemsCount"} = 0;

	$self->{"inCAM"}      = undef;
	$self->{"jobId"}      = undef;
	
	# Contains data  necessary for process task
	$self->{"taskData"} = undef;
 

	# EVENTS

	$self->{"onItemResult"} = Event->new();
	$self->{"onStatusResult"} = Event->new();

	bless $self;
	return $self;
}

# Run task of group
sub Run {
	my $self = shift;

	$self->{"taskMngr"}->Run();

}



# Return process group value in percent
sub GetProgressValue {
	my $self       = shift;
	my $itemResult = shift;
	
	my $val = $self->{"processedItemsCount"} / $self->{"itemsCount"} * 100;	
}

sub _OnItemResultHandler {
	my $self       = shift;
	my $itemResult = shift;

	$self->{"processedItemsCount"}++;

	$self->{"onItemResult"}->Do($itemResult);
}

sub _OnStatusResultHandler {
	my $self       = shift;
	my $itemResult = shift;
	
	# Delete items rocessed counter, because, group will be processed from begining
	if($itemResult->{"itemId"} eq EnumsAbstrQ->EventItemType_STOP){
		
		$self->{"processedItemsCount"} = 0;
	}
 
	$self->{"onStatusResult"}->Do($itemResult);
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

