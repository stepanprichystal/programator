
#-------------------------------------------------------------------------------------------#
# Description: Custom control list. Enable create custom items from controls
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
use aliased 'Widgets::Forms::MyWxScrollPanel';
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
	my @jobItems = ();
	$self->{"jobItems"} = \@jobItems;

	# PROPERTIES

	$self->__SetLayout();

	#EVENTS
	$self->{"onSelectItemChange"} = Event->new();

	for ( my $i = 0 ; $i < 2 ; $i++ ) {

		my $item = $self->AddItem( "F9999" . $i );
		
		$item->SetErrors($i);
		$item->SetProgress(2*$i);
		
	}

	return $self;
}

sub __SetLayout {
	my $self = shift;

	$self->SetItemGap(2);

	$self->SetItemUnselectColor( Wx::Colour->new( 255, 255, 255 ) );
	$self->SetItemSelectColor( Wx::Colour->new( 200, 240, 200 ));

	# SET EVENTS

	$self->{"onSelectItemChange"}->Add( sub { $self->__OnSelectItem(@_) } );

}

sub __OnSelectItem {
	my $self = shift;
	my $item = shift;

}

sub AddItem {
	my $self  = shift;
	my $jobId = shift;

	my $item = JobQueueItemForm->new( $self->GetParentForItem(), $jobId );

	$self->AddItemToQueue($item);
	
	return $item;

}

sub RemoveItemFromQueue {
	my $self = shift;

	#$self->AddItemToQueue($item);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
