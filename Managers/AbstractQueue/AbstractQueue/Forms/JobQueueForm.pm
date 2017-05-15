
#-------------------------------------------------------------------------------------------#
# Description: Container, which display JobQueueItems in queue
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::AbstractQueue::Forms::JobQueueForm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueue);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Managers::AsyncJobMngr::AppConf';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $parent    = shift;
	my $dimension = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], $dimension );

	bless($self);

	# Items references
	# PROPERTIES

	$self->__SetLayout();

	#EVENTS
	$self->{"onSelectItemChange"} = Event->new();
	$self->{"onStop"}             = Event->new();
	$self->{"onContinue"}         = Event->new();
	$self->{"onAbort"}            = Event->new();
	$self->{"onRestart"}            = Event->new();
	$self->{"onRemove"}           = Event->new();

	return $self;

}

sub _AddItem {
	my $self = shift;
	my $item = shift;

	$item->{"onStop"}->Add( sub     { $self->{"onStop"}->Do(@_) } );
	$item->{"onContinue"}->Add( sub { $self->{"onContinue"}->Do(@_) } );
	$item->{"onAbort"}->Add( sub    { $self->{"onAbort"}->Do(@_) } );
	$item->{"onRestart"}->Add( sub  { $self->{"onRestart"}->Do(@_) } );
	$item->{"onRemove"}->Add( sub   { $self->{"onRemove"}->Do(@_) } );

	$self->AddItemToQueue($item);

	$self->__SetJobOrder();

	return $item;

}

sub RemoveJobFromQueue {
	my $self   = shift;
	my $itemId = shift;

	$self->RemoveItemFromQueue($itemId);

	$self->__SetJobOrder();

}

sub __SetLayout {
	my $self = shift;

	$self->SetItemGap(2);
 
	$self->SetItemUnselectColor( AppConf->GetColor("clrGroupBackg") );
	$self->SetItemSelectColor( AppConf->GetColor("clrItemSelected") );

	# SET EVENTS

	$self->{"onSelectItemChange"}->Add( sub { $self->__OnSelectItem(@_) } );

}

sub __OnStop {
	my $self = shift;

	$self->{"onStop"}->Do( $self->{"taskId"} );
}

sub __OnContinue {
	my $self = shift;

	$self->{"onContinue"}->Do( $self->{"taskId"} );
}

sub __OnAbort {
	my $self = shift;

	$self->{"onAbort"}->Do( $self->{"taskId"} );
}

sub __OnRestart {
	my $self = shift;

	$self->{"onRestart"}->Do( $self->{"taskId"} );
}

sub __OnRemove {
	my $self = shift;

	$self->{"onRemove"}->Do( $self->{"taskId"} );
}

sub __OnSelectItem {
	my $self = shift;
	my $item = shift;

}

sub __SetJobOrder {
	my $self = shift;

	my @queue = @{ $self->{"jobItems"} };

	#find index of item
	for ( my $i = 0 ; $i < scalar(@queue) ; $i++ ) {

		$queue[$i]->SetItemOrder();
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
