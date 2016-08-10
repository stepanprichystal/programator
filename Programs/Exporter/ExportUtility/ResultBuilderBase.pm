
#-------------------------------------------------------------------------------------------#
# Description: Structure represent group of operation on technical procedure
# Tell which operation will be merged, thus which layer will be merged to one file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ResultBuilderBase;

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
	
	#take only package name (last) from whole package definition
	$self->{"groupId"} = shift;
	my @splitted = split('::', $self->{"groupId"});
	$self->{"groupId"} = $splitted[scalar(@splitted)-1];
	
	# Events

	$self->{"onItemResult"} = Event->new();

	return $self;    # Return the reference to the hash.
}

sub _SendItemResult {
	my $self = shift;
	
	
	my $onItemResult = $self->{'onItemResult'};
	if ( $onItemResult->Handlers() ) {
		$onItemResult->Do(@_);
	}

}

sub _GetNewItem {
	my $self   = shift;
	my $id     = shift;
	my $result = shift;

	my $groupId = $self->{"groupId"};

	my $item = ItemResult->new( $groupId . "/" . $id, $result );

}

sub _SetItemId {
	my $self = shift;
	my $id   = shift;
	my $item = shift;

	my $groupId = $self->{"groupId"};

	$item->{"itemId"} = $groupId . "/" . $id;
	 

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

