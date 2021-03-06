#-------------------------------------------------------------------------------------------#
# Description: Custom notebook. Keep notebook pages in list
# Always show only one tab. There is no header.
# For add new page:
# 1) GetPage()
# 2) $page->AddContent()
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

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

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

sub AddPage {
	my $self = shift;
	my $id = shift;
	my $scrolling = shift // 1;

	my $page = CustomNotebookPage->new( $self, $id, $scrolling );

	$self->{"pages"}->{ $page->GetPageId() } = $page;

	#$self->{"szMain"}->Add( 1, 1, 1, &Wx::wxEXPAND );

	$self->{"szMain"}->Add( $page, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$page->Hide();

	return $page;
}

sub RemovePage {
	my $self   = shift;
	my $pageId = shift;

	# remove physic control
	my $page = $self->{"pages"}->{$pageId};
	
	unless(defined $page){
		print STDERR "page is not defined";
	}
	
	$page->Destroy();

	# remove page from container
	$self->{"pages"}->{$pageId} = undef;
}

sub GetPage {
	my $self   = shift;
	my $pageId = shift;

	return $self->{"pages"}->{$pageId};
}


sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#$self->SetBackgroundColour( Wx::Colour->new( 50, 0, 0 ) );

	# DEFINE SIZERS

	# BUILD LAYOUT STRUCTURE

	$self->SetSizer($szMain);

	# SET EVENTS

	#$self->{"onSelectItemChange"}->Add( sub { $self->__OnSelectItem(@_) } );

	# SET REFERENCES

	$self->{"szMain"} = $szMain;

}


sub ShowPage {
	my $self   = shift;
	my $pageId = shift;

	$self->__HideAllPage();
	my $page = $self->{"pages"}->{$pageId};

	$page->Show(1);

	$self->Layout();
}

sub __HideAllPage {
	my $self = shift;

	my %pages = %{ $self->{"pages"} };

	foreach my $id ( keys %pages ) {

		my $page = $pages{$id};

		if ($page) {
			$page->Hide();
		}

	}
}

sub GetPageCount {
	my $self = shift;

	my $total = 0;
	my %pages = %{ $self->{"pages"} };
	foreach my $id ( keys %pages ) {

		my $page = $pages{$id};

		if ($page) {

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
