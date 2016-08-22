
#-------------------------------------------------------------------------------------------#
# Description: Custom control list. Enable create custom items from controls
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::CustomNotebook::CustomNotebook;
use base qw(Wx::Panel);

#3th party library
use Wx;
use Wx qw( :brush :font :pen :colour );

use strict;
use warnings;

#local library
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebookPage';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $parent    = shift;
	my $dimension = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [-1,-1] );

	bless($self);

	# Items references
	my %pages = ();

	$self->{"pages"} = \%pages;

	# PROPERTIES

	$self->__SetLayout();

	#EVENTS
	$self->{"onSelectItemChange"} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	 
	 my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	$self->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

	# DEFINE SIZERS
	 
	# BUILD LAYOUT STRUCTURE
 
	$self->SetSizer($szMain);

	# SET EVENTS

	#$self->{"onSelectItemChange"}->Add( sub { $self->__OnSelectItem(@_) } );
	
	# SET REFERENCES
	
	$self->{"szMain"} = $szMain;

}

sub AddPage {
	my $self = shift;

	my $id = shift;

	my $page = CustomNotebookPage->new( $self, $id );

	$self->{"pages"}->{ $page->GetPageId() } = $page;
	
	$self->{"szMain"}->Add($page, 1, &Wx::wxEXPAND, 1);
	$page->Hide();

	return $page;
}

sub RemovePage {
	my $self   = shift;
	my $pageId = shift;

	# remove physic control
	my $page = $self->{"pages"}->{$pageId};
	$page->Destroy();

	# remove page from container
	$self->{"pages"}->{$pageId} = undef;
}

sub ShowPage {
	my $self   = shift;
	my $pageId = shift;

	$self->__HideAllPage();
	my $page = $self->{"pages"}->{$pageId};
	

	$page->Show(1);
	
	$self->Layout();
	
	#$self->Refresh();

}

sub __HideAllPage {
	my $self = shift;

	
	my %pages = %{$self->{"pages"}};

	foreach my $id ( keys %pages ) {

		my $page = $pages{$id};
		$page->Hide();
	}
	
#	my $pageCnt = $self->__GetPageCount();
	#for(my $i = 0; $i < $pageCnt; $i++){
		
	#	$self->{"mainSz"}->Remove(0);
	#}
	
	
}

sub __GetPageCount{
	my $self = shift;
	
	my $total = 0;
	my %pages = %{$self->{"pages"}};
	foreach my $id ( keys %pages ) {

		my $page = $pages{$id};
		
		if($page){
			
			$total++;
		}
	}
	return $total;
}

sub __OnSelectItem {
	my $self = shift;
	my $item = shift;

}

 

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
