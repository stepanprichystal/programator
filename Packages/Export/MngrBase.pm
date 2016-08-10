
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
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

	#my $result = shift;

	#my $groupId = $self->{"groupId"};

	my $item = ItemResult->new($id);
	
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

