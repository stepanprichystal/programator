
#-------------------------------------------------------------------------------------------#
# Description: Base class for Managers, which allow create new item and reise event with 
# this item
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ItemResult::ItemEventMngr;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Packages::ItemResult::ItemResult';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	$self->{'onItemResult'} = Event->new();

	return $self;    # Return the reference to the hash.
}

sub _GetNewItem {
	my $self = shift;
	my $id   = shift;
	my $group   = shift;
	#my $result = shift;

	#my $groupId = $self->{"groupId"};

	my $item = ItemResult->new($id);
	
	if($group){
		
		$item->SetGroup($group);
		
	}
	
	return $item;

}

sub _OnItemResult {
	my $self       = shift;
	my $itemResult = shift;

	#raise onJobStarRun event
	my $onItemResult = $self->{'onItemResult'};
	if ( $onItemResult->Handlers() ) {
		$onItemResult->Do($itemResult);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

