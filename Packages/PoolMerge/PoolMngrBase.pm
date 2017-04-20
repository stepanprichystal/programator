
#-------------------------------------------------------------------------------------------#
# Description: Base class for Managers, which allow create new item and reise event with
# Class allow raise two tzpes of event:
# 1) - standard event, which inform if task was succes/fail
# 2) - special event, which inform if it is worth to continue, if some standar event resul is Fail
# this item
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::PoolMngrBase;
use base("Packages::ItemResult::ItemEventMngr");

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Packages::ItemResult::Enums';
use aliased 'Managers::AbstractQueue::Enums' => "EnumsAbstrQ";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

# Do standaret item result + send stop task if result is not succes
sub _OnPoolItemResult {
	my $self       = shift;
	my $itemResult = shift;

	#  call standard base class method
	$self->_OnItemResult($itemResult);

	# plus if item esult fail, call stop taks

	if ( $itemResult->Result() eq Enums->ItemResult_Fail ) {
		my $resSpec = $self->_GetNewItem( EnumsAbstrQ->EventItemType_STOP );
		$self->_OnStatusResult($resSpec);
	}

}

# Send message, master with chose master job
sub _OnSetMaster {
	my $self       = shift;
	my $master = shift;

	my $resSpec = $self->_GetNewItem( EnumsPool->EventItemType_MASTER );
	$resSpec->SetData($master);
	$self->_OnStatusResult($resSpec);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

