#-------------------------------------------------------------------------------------------#
# Description: Responsible for creating "table of column", where GroupWrapperForms are
# placed in. Is responsible for recaltulating "column" layout.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::CustomControlList::ControlList;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;
use aliased 'Widgets::Forms::CustomControlList::ControlListColumn';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class        = shift;
	my $parent       = shift;
	my $columnCnt    = shift;
	my $columnWidths = shift;
	my $verticalLine = shift;

	my $self = $class->SUPER::new($parent, -1, &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxSIMPLE_BORDER);

	bless($self);

	$self->{"columnCnt"}    = $columnCnt;
	$self->{"columnWidth"}  = $columnWidths;
	$self->{"verticalLine"} = $verticalLine;

	my @columns = ();
	$self->{"columns"} = \@columns;
	my @columnsHeader = ();
	$self->{"columnsHeader"} = \@columnsHeader;

	my @rows = ();
	$self->{"rows"} = \@rows;

	$self->{"vLineColor"} = undef;    # color of vertical line
	$self->{"vLineWidth"} = undef;    # width of vertical line
	$self->{"bodyColor"}  = undef;

	my @vSep = ();
	$self->{"vSep"} = \@vSep;

	$self->__SetLayout();

	$self->{"onSelectedChanged"} = Event->new();

	return $self;
}

sub SetHeader {
	my $self   = shift;
	my @titles = @{ shift(@_) };

	my @columnsHeader = @{ $self->{"columnsHeader"} };

	# init columns
	for ( my $i = 0 ; $i < $self->{"columnCnt"} ; $i++ ) {

		my $coll = $columnsHeader[$i];
		my $tit  = $titles[$i];

		my $titleTxt = Wx::StaticText->new( $self, -1, $tit, [ -1, -1 ] );

		$coll->AddCell($titleTxt);
	}

}

sub AddRow {
	my $self = shift;
	my $row  = shift;
	push( @{ $self->{"rows"} }, $row );
	
	# Register on select changed
	
	$row->{"onSelectedChanged"}->Add( sub { $self->__OnSelectedChange(@_)});
	

	my @columns = @{ $self->{"columns"} };

	for ( my $i = 0 ; $i < $self->{"columnCnt"} ; $i++ ) {

		my $coll = $columns[$i];
		my $cell = $row->GetCellsByPos($i);

		$coll->AddCell($cell);

	}

}

sub GetSelectedRows {
	my $self = shift;

	my @rows = @{ $self->{"rows"} };

	my @selected = grep { $_->IsSelected() } @rows;

	return @selected;
}

sub GetSelectedId {

}

sub SelectAll {
	my $self = shift;

	$self->{"rows"}->SetSelected(1);
}

sub UnselectAll {
	my $self = shift;

	$self->{"rows"}->SetSelected(0);
}

# Set color of select item
sub SetBodyBackgroundColor {
	my $self  = shift;
	my $color = shift;

	$self->{"bodyColor"} = $color;
}

# Set color of select item
sub SetVerticalLine {
	my $self  = shift;
	my $color = shift;

	#my $width = shift;

	$self->{"vLineColor"} = $color;

	#$self->{"vLineWidth"} = $width;

	foreach my $sep ( @{ $self->{"vSep"} } ) {

		$sep->SetBackgroundColour($color);
		$sep->Refresh();
	}

}

# Create column, for placing GroupWrappersForm
sub __SetLayout {

	my $self  = shift;
	my $units = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szHeader  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szColumns = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	if ( $self->{"bodyColor"} ) {
		$self->SetBackgroundColour( $self->{"bodyColor"} );
	}

	# DEFINE SIZERS

	my @widths = @{ $self->{"columnWidth"} };

	# init columns
	#	for ( my $i = 0 ; $i < $self->{"columnCnt"} ; $i++ ) {
	#
	#		my $w = $widths[$i];
	#		my $col = ControlListColumn->new( $self, $w );
	#
	#	}

	# BUILD LAYOUT STRUCTURE

	# init columns
	my @columns = @{ $self->{"columns"} };

	for ( my $i = 0 ; $i < $self->{"columnCnt"} ; $i++ ) {

		my $w         = $widths[$i];
		my $colRows   = ControlListColumn->new( $self, $w );
		my $colHeader = ControlListColumn->new( $self, $w );

		$szColumns->Add( $colRows->GetSizer(), 0, &Wx::wxEXPAND );
		$szHeader->Add( $colHeader->GetSizer(), 0, &Wx::wxEXPAND );

		# add column separator
		#if ( $i > 0 ) {

		if ( $self->{"verticalLine"} ) {

			$szColumns->Add( $self->__GetVSeparator(), 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );    #
			$szHeader->Add( $self->__GetVSeparator(), 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
		}

		#}

		push( @{ $self->{"columns"} },       $colRows );
		push( @{ $self->{"columnsHeader"} }, $colHeader );

	}

	$szMain->Add( $szHeader,                0, &Wx::wxEXPAND );
	$szMain->Add( $self->__GetHeaderLine(), 0, &Wx::wxEXPAND );
	$szMain->Add( $szColumns,               0, &Wx::wxEXPAND );

	$self->SetSizer($szMain);
	$self->{"szMain"} = $szMain;

}

sub __GetVSeparator {
	my $self = shift;

	my $sepSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $sepPnl = Wx::Panel->new( $self, -1 );
	$sepPnl->SetBackgroundColour( Wx::Colour->new( 200, 0, 0 ) );
	$sepPnl->SetSizer($sepSz);
	$sepSz->Add( 1, 5, 0, &Wx::wxEXPAND );

	push( @{ $self->{"vSep"} }, $sepPnl );

	return $sepPnl;
}

sub __GetHeaderLine {
	my $self = shift;

	my $sepSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $sepPnl = Wx::Panel->new( $self, -1 );
	$sepPnl->SetBackgroundColour( Wx::Colour->new( 163, 163, 163 ) );
	$sepPnl->SetSizer($sepSz);
	$sepSz->Add( 1, 1, 0, &Wx::wxEXPAND );

	return $sepPnl;
}

sub __ResetRearrange {
	my $self       = shift;
	my $page       = shift;
	my $pageHeight = shift;

	$self->{"lastRearrange"} = time();

	#move alll group to first column and do new rearange

	my $colCnt = scalar( @{ $self->{"columns"} } );
	for ( my $i = $colCnt - 2 ; $i >= 0 ; $i-- ) {

		while (1) {
			my $columnNext = ${ $self->{"columns"} }[ $i + 1 ];

			# If nothing to move, exit from loop
			unless ( $columnNext->MoveBackGroup() ) {
				last;
			}
		}
	}

	$self->RearrangeGroups( $page, $pageHeight, 1 );

}

# Return max column height, last col is not count!
sub __GetMaxColumnHeight {
	my $self = shift;

	my $colCnt = scalar( @{ $self->{"columns"} } );

	#move group back, untill column height < then table height

	my $max = 0;
	for ( my $i = 0 ; $i < $colCnt - 1 ; $i++ ) {
		my $column    = ${ $self->{"columns"} }[$i];
		my $colHeight = $column->GetHeight();

		if ( $colHeight > $max ) {

			$max = $colHeight;

		}
	}

	return $max;

}

sub __GetColumnAvgHeight {
	my $self = shift;

	my $colCnt = scalar( @{ $self->{"columns"} } );

	#move group back, untill column height < then table height

	my $total = 0;
	for ( my $i = 0 ; $i < $colCnt ; $i++ ) {
		my $column    = ${ $self->{"columns"} }[$i];
		my $colHeight = $column->GetHeight();

		$total += $colHeight;

	}

	return int( $total / $colCnt );

}

sub __OnSelectedChange {
	my $self = shift;
	my $row  = shift;

	$self->{"onSelectedChanged"}->Do($self, $row);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
	my $test = Programs::Exporter::ExportChecker::Forms::GroupTableForm->new();

	$test->MainLoop();
}

1;

1;

