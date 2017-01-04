
#-------------------------------------------------------------------------------------------#
# Description: Base class for Managers, which are responsible for export pcb data
# Rules for creating export scripts.
# Because each export scripts are launched in "Export utility" in perl ithreads
# is necessary acomplish this.
# - code hasn't contain another child thread. Use library Packages::SystemCall for using threads
# - code hasn't use library Connectors::HeliosConnector::HelperWriter, because free wrong pool errors
# for this use this library but launeched by Packages::SystemCall again
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::MngrBase;

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

