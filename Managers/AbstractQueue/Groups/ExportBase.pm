#-------------------------------------------------------------------------------------------#
# Description: Base class for unit task classes.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::Groups::ExportBase;

#3th party library
use strict;
use warnings;

use aliased 'Packages::Events::Event';
 
#-------------------------------------------------------------------------------------------#
#  NC task, all layers, all machines..
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};

	# PROPERTIES

	$self->{"unitId"} = shift;

	# Approximate count of tasked items 
	# (because computing progressbar value)
	$self->{"itemsCount"}          = 0;  
	
	# Count of already tasked items
	$self->{"processedItemsCount"} = 0;

	$self->{"inCAM"}      = undef;
	$self->{"jobId"}      = undef;
	
	# Contains data (from ExportFiles/job file) necessary for task
	$self->{"taskData"} = undef;

	# EVENTS

	$self->{"onItemResult"} = Event->new();

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

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

