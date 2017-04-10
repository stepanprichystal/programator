
#-------------------------------------------------------------------------------------------#
# Description: Container, which display JobQueueItems in queue
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportPool::ExportPool::Forms::JobQueueForm;
use base qw(Managers::AbstractQueue::AbstractQueue::Forms::JobQueueForm);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportPool::ExportPool::Forms::JobQueueItemForm';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $parent    = shift;
	my $dimension = shift;

	my $self = $class->SUPER::new( $parent, $dimension );

	bless($self);

	# PROPERTIES

	$self->__SetLayout();

	#EVENTS
 
	$self->{"onProduce"}          = Event->new();
 
	return $self;
}

sub AddItem {
	my $self        = shift;
	my $task		= shift;

	my $taskId      = $task->GetTaskId();
	my $jobId       = $task->GetJobId();;
	my $taskData  = $task->GetTaskData();
	my $produceMngr = $task->ProduceResultMngr();
	my $taskMngr    = $task->GetTaskResultMngr();
	my $groupMngr   = $task->GetGroupResultMngr();
	my $itemMngr    = $task->GetGroupItemResultMngr();

	my $item = JobQueueItemForm->new( $self->GetParentForItem(), $jobId, $taskId, $taskData, $produceMngr, $taskMngr, $groupMngr, $itemMngr );
	
	$item->{"onProduce"}->Add( sub { $self->{"onProduce"}->Do(@_) } );

	return $self->_AddItem($item);
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

	$self->SetItemUnselectColor( Wx::Colour->new( 240, 240, 240 ) );
	$self->SetItemSelectColor( Wx::Colour->new( 215, 230, 251 ) );

}

sub __OnProduce {
	my $self = shift;

	$self->{"onProduce"}->Do( $self->{"taskId"} );

}

sub __OnAbort {
	my $self = shift;

	$self->{"onAbort"}->Do( $self->{"taskId"} );
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
