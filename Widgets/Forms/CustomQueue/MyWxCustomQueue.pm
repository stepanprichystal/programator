
#-------------------------------------------------------------------------------------------#
# Description: Custom queue list. Keep items of type MyWxCustomQueueItem
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::CustomQueue::MyWxCustomQueue;
use base qw(Wx::Panel);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Widgets::Forms::MyWxScrollPanel';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class     = shift;
	my $parent    = shift;
	my $id        = shift;
	my $position  = shift;
	my $dimension = shift;

	my $self = $class->SUPER::new( $parent, $id, $position, $dimension );

	bless($self);

	# Items references
	my @jobItems = ();
	$self->{"jobItems"} = \@jobItems;

	# PROPERTIES

	# gap between items in list
	$self->{"itemGap"} = 1;

	$self->__SetLayout();

	#EVENTS
	$self->{"itemUnselectColor"}  = undef;
	$self->{"itemSelectColor"}    = undef;
	$self->{"itemDisabledColor"}  = undef;
	$self->{"onSelectItemChange"} = Event->new();

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

sub AddItemToQueue {
	my $self = shift;
	my $item = shift;

	#my $item = JobQueueItemForm->new( $self->{"containerPnl"});

	$item->{"onItemClick"}->Add( sub { $self->__OnItemClick(@_) } );

	push( @{ $self->{"jobItems"} }, $item );

	$self->{"containerSz"}->Add( $item, 0, &Wx::wxEXPAND | &Wx::wxBOTTOM, $self->{"itemGap"} );

	$self->__RenumberItems();

	$self->{"scrollPnl"}->FitInside();
	$self->{"scrollPnl"}->Layout();

	my $total = $self->__GetItemsHeight();
	$self->{"scrollPnl"}->SetRowCount( $total / 10 );

}

sub RemoveItemFromQueue {
	my $self   = shift;
	my $itemId = shift;

	my @queue    = @{ $self->{"jobItems"} };
	my $position = -1;

	#find index of item
	for ( my $i = 0 ; $i < scalar(@queue) ; $i++ ) {

		if ( $itemId eq $queue[$i]->GetItemId() ) {

			$position = $i;
			last;
		}
	}

	if ( $position >= 0 ) {

		splice @{ $self->{"jobItems"} }, $position, 1;
		$self->{"containerSz"}->Remove($position);
		$queue[$position]->Destroy();
		$self->{"containerSz"}->Layout();

		$self->__RenumberItems();

		$self->{"scrollPnl"}->FitInside();
		$self->{"scrollPnl"}->Layout();

		my $total = $self->__GetItemsHeight();
		$self->{"scrollPnl"}->SetRowCount( $total / 10 );

		#select first item in queue if exist
		if ( scalar( @{ $self->{"jobItems"} } ) > 0 ) {

			my $firstItem = ${ $self->{"jobItems"} }[0];

			$self->SetSelectedItem( $firstItem->GetItemId() );

		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Methods for set queue
#-------------------------------------------------------------------------------------------#

# Set height of item gap
sub SetItemGap {
	my $self  = shift;
	my $value = shift;    #value in px

	$self->{"itemGap"} = $value;
}

# Set color of UNselect item
sub SetItemUnselectColor {
	my $self  = shift;
	my $color = shift;

	$self->{"itemUnselectColor"} = $color;
}

# Set color of select item
sub SetItemSelectColor {
	my $self  = shift;
	my $color = shift;

	$self->{"itemSelectColor"} = $color;
}

# Set color of disabled item
sub SetItemDisabledColor {
	my $self  = shift;
	my $color = shift;

	$self->{"itemDisabledColor"} = $color;
}

sub GetSelectedItem {
	my $self  = shift;
	my $value = shift;

	return first { $_->GetSelected() } @{ $self->{"jobItems"} };

}

sub SetSelectedItem {
	my $self   = shift;
	my $itemId = shift;

	foreach my $item ( @{ $self->{"jobItems"} } ) {

		if ( $item->{"itemId"} eq $itemId ) {

			$self->__OnItemClick($item);
			last;
		}

	}
}

sub SetDisabledItem {
	my $self   = shift;
	my $itemId = shift;
	my $disabled = shift;

	foreach my $item ( @{ $self->{"jobItems"} } ) {

		if ( $item->{"itemId"} eq $itemId ) {

			# Set color
			if ( defined $self->{"itemDisabledColor"} ) {
				$item->SetBackgroundColour( $self->{"itemSelectColor"} );
				$item->Refresh();
			}
			
			$item->SetDisabled($disabled);
			last;
		}
	}
}

sub GetParentForItem {
	my $self = shift;

	return $self->{"containerPnl"};
}

sub GetItem {
	my $self   = shift;
	my $itemId = shift;

	foreach my $item ( @{ $self->{"jobItems"} } ) {

		if ( $item->{"itemId"} eq $itemId ) {

			return $item;
		}
	}
}

sub GetAllItems {
	my $self   = shift;
	 
	return @{ $self->{"jobItems"} };
}

sub GetItemsCnt {
	my $self = shift;

	return @{ $self->{"jobItems"} };

}

 


#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#$self->SetBackgroundColour( Wx::Colour->new( 230, 230, 230 ) );

	# DEFINE SIZERS

	my $scrollSizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $containerSz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE PANELS

	my $rowHeight = 10;
	my $scrollPnl = MyWxScrollPanel->new( $self, $rowHeight, );

	my $containerPnl = Wx::Panel->new( $scrollPnl, -1, );

	#$containerPnl->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

	#$scrollSizer->Layout();

	# BUILD LAYOUT STRUCTURE

	#set sizers
	$containerPnl->SetSizer($containerSz);
	$scrollPnl->SetSizer($scrollSizer);

	# addpanel to siyers
	$scrollSizer->Add( $containerPnl, 0, &Wx::wxEXPAND );
	$szMain->Add( $scrollPnl, 1, &Wx::wxEXPAND );
	$self->SetSizer($szMain);

	# SET EVENTS
	Wx::Event::EVT_PAINT( $scrollPnl, sub { $self->__OnScrollPaint(@_) } );

	$self->{"scrollPnl"}    = $scrollPnl;
	$self->{"scrollSizer"}  = $scrollSizer;
	$self->{"containerSz"}  = $containerSz;
	$self->{"containerPnl"} = $containerPnl;

}

sub __RenumberItems {
	my $self = shift;

	my @queue = @{ $self->{"jobItems"} };

	#find index of item
	for ( my $i = 0 ; $i < scalar(@queue) ; $i++ ) {

		$queue[$i]->{"position"} = $i;
	}
}

sub __OnItemClick {
	my $self = shift;
	my $item = shift;

	$self->__UnselectAll();
	$item->SetSelected(1);

	if ( defined $self->{"itemSelectColor"} ) {
		$item->SetBackgroundColour( $self->{"itemSelectColor"} );
		$item->Refresh();
	}
	$self->{"onSelectItemChange"}->Do($item);

}

sub __OnScrollPaint {
	my $self      = shift;
	my $scrollPnl = shift;
	my $event     = shift;

	$self->Layout();
	$scrollPnl->FitInside();
	$scrollPnl->Refresh();
}

sub __UnselectAll {
	my $self = shift;

	foreach my $item ( @{ $self->{"jobItems"} } ) {

		$item->SetSelected(0);
		if ( defined $self->{"itemUnselectColor"} ) {
			$item->SetBackgroundColour( $self->{"itemUnselectColor"} );
			$item->Refresh();
		}

	}

}

sub __GetItemsHeight {
	my $self = shift;

	my ( $width, $height ) = $self->{"containerPnl"}->GetSizeWH();

	#	my @items = @{ $self->{"jobItems"} };
	#
	#	foreach my $item (@items) {
	#
	#		$total += $item->GetItemHeight();
	#	}

	return $height;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
