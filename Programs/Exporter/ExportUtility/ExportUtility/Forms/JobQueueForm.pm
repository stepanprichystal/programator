
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::Forms::JobQueueForm;
use base qw(Wx::Panel);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::JobQueueItemForm';
use aliased 'Widgets::Forms::MyWxScrollPanel';

#my $THREAD_MESSAGE_EVT : shared;
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $parent    = shift;
	my $dimension = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], $dimension );

	bless($self);

	#$self->{"state"} = Enums->GroupState_ACTIVEON;

	my @jobItems = ();
	$self->{"jobItems"} = \@jobItems;

	$self->__SetLayout();

	#EVENTS

	#$self->{"onChangeState"} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	$self->SetBackgroundColour( Wx::Colour->new( 250, 245, 0 ) );

	# DEFINE SIZERS

	my $scrollSizer     = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $containerSz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE PANELS

	my $rowHeight = 10;
	my $scrollPnl = MyWxScrollPanel->new( $self, $rowHeight, );

	my $containerPnl = Wx::Panel->new( $scrollPnl, -1, );
	
	$containerPnl->SetBackgroundColour( Wx::Colour->new(0, 50, 0 ) );

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

	# get height of group table, for init scrollbar panel
	$scrollPnl->Layout();

	$self->{"scrollPnl"}       = $scrollPnl;
	$self->{"scrollSizer"}     = $scrollSizer;
	$self->{"containerSz"} = $containerSz;
	$self->{"containerPnl"} = $containerPnl;


	
	for(my $i = 0; $i < 20 ; $i++){
		
		$self->AddItemToQueue($i);
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

sub AddItemToQueue {
	my $self = shift;
	my $index = shift;

	my $item = JobQueueItemForm->new($self->{"containerPnl"}, $index);

	push( @{ $self->{"jobItems"} }, $item );

	$self->{"containerSz"}->Add( $item, 0, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	# get height of group table, for init scrollbar panel
	$self->{"scrollPnl"}->Layout();

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

sub __OnScrollPaint {
	my $self      = shift;
	my $scrollPnl = shift;
	my $event     = shift;

	$self->Layout();
	$scrollPnl->FitInside();
	$scrollPnl->Refresh();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
