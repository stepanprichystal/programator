
#-------------------------------------------------------------------------------------------#
# Description: Container, which display JobQueueItems in queue
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::PoolMerge::Forms::JobQueueForm;
use base qw(Managers::AbstractQueue::AbstractQueue::Forms::JobQueueForm);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
use aliased 'Programs::PoolMerge::PoolMerge::Forms::JobQueueItemForm';
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
 
	$self->{"onToExport"}          = Event->new();
 
	return $self;
}

sub AddItem {
	my $self        = shift;
	my $task		= shift;

	my $taskId      = $task->GetTaskId();
	my $jobId       = $task->GetJobId();;
	my $taskData  = $task->GetTaskData();
	my $toExportMngr = $task->ToExportResultMngr();
	my $taskMngr    = $task->GetTaskResultMngr();
	my $groupMngr   = $task->GetGroupResultMngr();
	my $itemMngr    = $task->GetGroupItemResultMngr();

	my $item = JobQueueItemForm->new( $self->GetParentForItem(), $jobId, $taskId, $taskData, $toExportMngr, $taskMngr, $groupMngr, $itemMngr );
	
	$item->{"onToExport"}->Add( sub { $self->{"onToExport"}->Do(@_) } );

	return $self->_AddItem($item);
}

sub SetJobItemResult {
	my $self = shift;
	my $task = shift;

	my $jobItem = $self->{"jobQueue"}->GetItem( $task->GetTaskId() );

	$jobItem->SetTaskResult( $task->Result(), $task->GetJobAborted(), $task->GetJobSentToExport() );

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
	$self->SetItemSelectColor( Wx::Colour->new( 248, 217, 186 ) );

}

sub __OnToExport {
	my $self = shift;

	$self->{"onToExport"}->Do( $self->{"taskId"} );

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
