
#-------------------------------------------------------------------------------------------#
# Description: Container, which display JobQueueItems in queue
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::Forms::JobQueueForm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueue);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::JobQueueItemForm';
use aliased 'Packages::Events::Event';

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

	return $self;
}

sub AddItem {
	my $self        = shift;
	my $taskId      = shift;
	my $jobId       = shift;
	my $exportData  = shift;
	my $produceMngr = shift;
	my $taskMngr    = shift;
	my $groupMngr   = shift;
	my $itemMngr    = shift;

	my $item = JobQueueItemForm->new( $self->GetParentForItem(), $jobId, $taskId, $exportData, $produceMngr, $taskMngr, $groupMngr, $itemMngr );

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

	$self->SetItemUnselectColor( Wx::Colour->new( 240, 240, 240 ) );
	$self->SetItemSelectColor( Wx::Colour->new( 215, 230, 251 ) );

	# SET EVENTS

	$self->{"onSelectItemChange"}->Add( sub { $self->__OnSelectItem(@_) } );

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
