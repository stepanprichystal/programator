
#-------------------------------------------------------------------------------------------#
# Description: Custom control list. Enable create custom items from controls
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::CustomQueue::MyWxCustomQueue;
use base qw(Wx::Panel);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
#use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::JobQueueItemForm';
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
	$self->{"onSelectItemChange"} = Event->new();

	return $self;
}

# Set height of item gap
sub SetItemGap {
	my $self  = shift;
	my $value = shift;    #value in px

	$self->{"itemGap"} = $value;
}

sub SetItemUnselectColor {
	my $self  = shift;
	my $color = shift;

	$self->{"itemUnselectColor"} = $color;
}

sub SetItemSelectColor {
	my $self  = shift;
	my $color = shift;

	$self->{"itemSelectColor"} = $color;
}

sub GetSelectedItem {
	my $self  = shift;
	my $value = shift;

	$self->{"itemGap"} = $value;
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

sub GetParentForItem {
	my $self = shift;

	return $self->{"containerPnl"};
}

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	$self->SetBackgroundColour( Wx::Colour->new( 230, 230, 230 ) );

	# DEFINE SIZERS

	my $scrollSizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $containerSz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE PANELS

	my $rowHeight = 10;
	my $scrollPnl = MyWxScrollPanel->new( $self, $rowHeight, );

	my $containerPnl = Wx::Panel->new( $scrollPnl, -1, );

	$containerPnl->SetBackgroundColour( Wx::Colour->new( 230, 230, 230 ) );

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

sub AddItemToQueue {
	my $self = shift;
	my $item = shift;

	#my $item = JobQueueItemForm->new( $self->{"containerPnl"});

	$item->{"onItemClick"}->Add( sub { $self->__OnItemClick(@_) } );

	push( @{ $self->{"jobItems"} }, $item );

	$self->{"containerSz"}->Add( $item, 0, &Wx::wxEXPAND | &Wx::wxALL , $self->{"itemGap"} );

	# get height of group table, for init scrollbar panel
	#$self->{"scrollPnl"}->Layout();

	#$self->{"nb"}->InvalidateBestSize();
	$self->{"scrollPnl"}->FitInside();

	#$self->{"mainFrm"}->Layout();
	$self->{"scrollPnl"}->Layout();

	my $total = $self->__GetItemsHeight();

	print "Total Height is : " . $total . "\n";

	$self->{"scrollPnl"}->SetRowCount( $total / 10 );

}

sub RemoveItemFromQueue {
	my $self = shift;

	#$self->{"scrollSizer"}->Add( $groupTableForm, 1, &Wx::wxEXPAND );

}

sub __OnItemClick {
	my $self = shift;
	my $item = shift;

	$self->__UnselectAll();
	$item->{"selected"} = 1;

	$item->SetBackgroundColour( $self->{"itemSelectColor"} );
	$item->Refresh();
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

		$item->{"selected"} = 0;
		$item->SetBackgroundColour( $self->{"itemUnselectColor"} );
		$item->Refresh();

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
