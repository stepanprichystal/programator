
#-------------------------------------------------------------------------------------------#
# Description: Base class for Managers, which allow create new item and reise event with
# Class allow raise two tzpes of event:
# 1) - standard event, which inform if task was succes/fail
# 2) - special event, which inform if it is worth to continue, if some standar event resul is Fail
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

	$self->{'onItemResult'}       = Event->new();    # 1) - standard event, which inform if task was succes/fail
	                                                 # 2) - special event, which inform if it is worth to continue,
	                                                 # if some standar event resul is Fail
	$self->{'onItemStatusResult'} = Event->new();

	return $self;                               
}

sub _GetNewItem {
	my $self  = shift;
	my $id    = shift;
	my $group = shift;

	#my $result = shift;

	#my $groupId = $self->{"groupId"};

	my $item = ItemResult->new($id);

	if ($group) {

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

sub _OnItemStatusResult {
	my $self       = shift;
	my $itemResult = shift;

	#raise onJobStarRun event
	my $onItemStatusResult = $self->{'onItemStatusResult'};
	if ( $onItemStatusResult->Handlers() ) {
		$onItemStatusResult->Do($itemResult);
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

