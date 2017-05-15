
#-------------------------------------------------------------------------------------------#
# Description: Represent notebook tab for CustomNotebook class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::CustomNotebook::CustomNotebookPage;
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
	my $class  = shift;
	my $parent = shift;
	my $pageId = shift;

	my $self = $class->SUPER::new( $parent, -1, );

	bless($self);

	# Items references

	# PROPERTIES
	$self->{"pageId"}  = $pageId;
	$self->{"content"} = undef;     #reference to page content

	$self->__SetLayout();

	#EVENTS
	$self->{"onSelectItemChange"} = Event->new();

	return $self;
}



sub RefreshContent {
	my $self = shift;
	
	$self->Layout();

	$self->{"scrollPnl"}->FitInside();

	my $s      = $self->{"containerSz"}->GetSize();
	my $height = $s->GetHeight();

	 

	$self->{"scrollPnl"}->SetRowCount( $height / 10 );


}

sub GetPageId {
	my $self = shift;

	return $self->{"pageId"};
}

sub GetParent {
	my $self = shift;

	return $self->{"containerPnl"};
}

sub GetPageContent {
	my $self = shift;

	return $self->{"content"};
}

sub AddContent {
	my $self    = shift;
	my $content = shift;

	$self->{"content"} = $content;


	$self->{"containerSz"}->Add( $content, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$self->{"scrollPnl"}->FitInside();

	$self->{"scrollPnl"}->Layout();

	my ( $width, $height ) = $self->{"containerPnl"}->GetSizeWH();
 
	$self->{"scrollPnl"}->SetRowCount( $height / 10 );

}


sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	$self->SetBackgroundColour( Wx::Colour->new( 150, 0, 0 ) );

	# DEFINE SIZERS

	my $scrollSizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $containerSz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE PANELS

	my $rowHeight = 10;
	my $scrollPnl = MyWxScrollPanel->new( $self, $rowHeight, );

	my $containerPnl = Wx::Panel->new( $scrollPnl, -1, );

	$containerPnl->SetBackgroundColour( Wx::Colour->new( 0, 255, 0 ) );

	#$scrollSizer->Layout();

	# BUILD LAYOUT STRUCTURE

	#set sizers
	$containerPnl->SetSizer($containerSz);
	$scrollPnl->SetSizer($scrollSizer);

	# addpanel to siyers
	$scrollSizer->Add( $containerPnl, 1, &Wx::wxEXPAND );
	$szMain->Add( $scrollPnl, 1, &Wx::wxEXPAND );
	$self->SetSizer($szMain);

	# SET EVENTS
	Wx::Event::EVT_PAINT( $scrollPnl, sub { $self->__OnScrollPaint(@_) } );

	$self->{"scrollPnl"}    = $scrollPnl;
	$self->{"scrollSizer"}  = $scrollSizer;
	$self->{"containerSz"}  = $containerSz;
	$self->{"containerPnl"} = $containerPnl;
	$self->{"szMain"} = $szMain;
}

sub __OnScrollPaint {
	my $self      = shift;
	my $scrollPnl = shift;
	my $event     = shift;

	$self->Layout();

	#$scrollPnl->FitInside();
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
