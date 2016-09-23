#-------------------------------------------------------------------------------------------#
# Description: Base class for unit export classes.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::ExportBase;

#3th party library
use strict;
use warnings;

use aliased 'Packages::Events::Event';
 
#-------------------------------------------------------------------------------------------#
#  NC export, all layers, all machines..
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};

	# PROPERTIES

	$self->{"unitId"} = shift;

	# Approximate count of exported items 
	# (because computing progressbar value)
	$self->{"itemsCount"}          = 0;  
	
	# Count of already exported items
	$self->{"processedItemsCount"} = 0;

	$self->{"inCAM"}      = undef;
	$self->{"jobId"}      = undef;
	
	# Contains data (from ExportFiles/job file) necessary for export
	$self->{"exportData"} = undef;

	# EVENTS

	$self->{"onItemResult"} = Event->new();

	bless $self;
	return $self;
}

# Run export of group
sub Run {
	my $self = shift;

	$self->{"exportMngr"}->Run();

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
