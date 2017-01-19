use utf8;

#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::MyWxListCtrl;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx
  qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);
use Wx qw(:richtextctrl :textctrl :font);
use Wx qw(:icon wxTheApp wxNullBitmap);
use Wx qw(:listctrl);

#use Wx::ListCtrl;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use Widgets::Style;

sub new {

	my ( $class, $parent ) = @_;
	my $self = $class->SUPER::new($parent);

	bless($self);

	#EVENTS=========================

	#event, when some action happen
	$self->{'onPrev'} = undef;
	$self->{'onNext'} = undef;
	$self->{'onRefresh'} = undef;
	
	$self->__SetLayout();

	return $self;

}

sub __SetLayout {

	my $self = shift;

	my $szTop     = Wx::BoxSizer->new(&Wx::wxVERTICAL);    #top level sizer
	my $szFrstRow = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szSecRow = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	 

	my $refreshBtn = Wx::Button->new( $self, -1, "Refresh" );
	my $prevBtn = Wx::Button->new( $self, -1, "Previous" );
	my $nextBtn = Wx::Button->new( $self, -1, "Next" );
	my $paggingTxt = Wx::StaticText->new( $self, -1, "0-1000 (3000)");
	$paggingTxt->SetFont($Widgets::Style::fontSmallLbl);

	my $list =
	  Wx::ListCtrl->new( $self, -1, &Wx::wxDefaultPosition, [ 1500, 1500 ],
		&Wx::wxLC_REPORT );

	$self->{"list"} = $list;
	$self->{"paggingTxt"} = $paggingTxt;

	#print $self->InsertColumn(0, "Clmn 1");
	#print $self->InsertColumn(1, "Clmn 2");
	#print $self->InsertColumn(2, "Clmn 3");

	
	$szFrstRow->Add($refreshBtn, 0, &Wx::wxALL, 5);
	$szFrstRow->Add( 10, 10, 1, &Wx::wxEXPAND );
	$szFrstRow->Add( $paggingTxt, 0, &Wx::wxALL, 10 );
	$szFrstRow->Add( $prevBtn, 0, &Wx::wxALL, 5 );
	$szFrstRow->Add( $nextBtn, 0, &Wx::wxALL, 5 );
	

	$szSecRow->Add( $list, 1, &Wx::wxEXPAND | &Wx::wxALL, 5 );
	#$szSecRow->Add( 10, 10, 0, &Wx::wxEXPAND );

	$szTop->Add( $szFrstRow, 0, &Wx::wxEXPAND );
	$szTop->Add( $szSecRow, 1, &Wx::wxEXPAND);

	#$szTop->Add( 10, 10, 0, &Wx::wxEXPAND);
	#$szTop->Add( $list,  1, &Wx::wxEXPAND | &Wx::wxALL, 5);

	$self->SetSizer($szTop);
	$szTop->Layout();

	#register EVENTS
	Wx::Event::EVT_BUTTON( $prevBtn, -1, sub { __OnPrevClick($self) } );
	Wx::Event::EVT_BUTTON( $nextBtn, -1, sub { __OnNextClick($self) } );
	Wx::Event::EVT_BUTTON( $refreshBtn, -1, sub { __OnRefreshClick($self) } );
	

	#$self->InsertColumn(0, "test");
	#$self->DisplayData();

}

sub __OnPrevClick {
	my $self = shift;

	my $onPrev = $self->{'onPrev'};
	if ( defined $onPrev ) {

		$onPrev->();
	}
}

sub __OnNextClick {
	my $self = shift;

	my $onNext = $self->{'onNext'};
	if ( defined $onNext ) {

		$onNext->();
	}
}

sub __OnRefreshClick {
	my $self = shift;

	my $onRefresh = $self->{'onRefresh'};
	if ( defined $onRefresh ) {

		$onRefresh->();
	}
}

sub InsertColumns {
	my $self = shift;

	my @columns = @{ shift(@_) };
	my $width = shift;

	my $list = $self->{"list"};

	for ( my $i = 0 ; $i < scalar(@columns) ; $i++ ) {

		my $col = $columns[$i];

		$list->InsertColumn( $i, $col, &Wx::wxLIST_FORMAT_LEFT,
			&Wx::wxLIST_AUTOSIZE );
			
			 $list->SetColumnWidth( $i,$width);

	}

}


sub SetSingleColumnWidth {
	my $self = shift;
	my $idx = shift;
	my $width = shift;
	
	$self->{"list"}->SetColumnWidth( $idx,$width);
	
}



sub DisplayData {

	my $self = shift;

	my @rows = @{ shift(@_) };
	my @keys = @{ shift(@_) };
	

	#my $collCnt = $self->{"list"}->GetColumnCounn();

	#my( $small, $normal ) = $self->create_image_lists;
	#$self->AssignImageList( $small, wxIMAGE_LIST_SMALL );
	#$self->AssignImageList( $normal, wxIMAGE_LIST_NORMAL );

	$self->{"list"}->DeleteAllItems();
		
	for ( my $i = 0 ; $i < scalar(@rows) ; $i++ ) {

		my %r = %{ $rows[$i] };

		my $idx =
		  $self->{"list"}->InsertImageStringItem( $i, $r{ $keys[0] }, 0 );
		$self->{"list"}->SetItemData( $idx, $i );

		for ( my $j = 0 ; $j < scalar(@keys) ; $j++ ) {

			my $k = $keys[$j];
			if(defined $r{$k}){
				$self->{"list"}->SetItem( $idx, $j, $r{$k} );
			}
			
		}

		if ( defined $r{"colour"} ) {
			$self->{"list"}->SetItemBackgroundColour( $idx, $r{"colour"} );
			 
		}

	}

}

sub SetPagingValue{
	my $self = shift;
	my $text = shift;
	
	$self->{"paggingTxt"}->SetLabel($text);
	
}

1;

