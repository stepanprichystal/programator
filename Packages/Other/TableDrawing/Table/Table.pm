
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::Table::Table;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use List::Util qw(first);

#local library
use aliased 'Packages::Other::TableDrawing::Table::TableCell';
use aliased 'Packages::Other::TableDrawing::Table::TableCollDef';
use aliased 'Packages::Other::TableDrawing::Table::TableRowDef';
use aliased 'Packages::Other::TableDrawing::Enums';
use aliased 'Packages::Other::TableDrawing::Table::Style::TextStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::BackgStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::BorderStyle';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"key"}           = shift;
	$self->{"origin"}        = shift // { "x" => 0, "y" => 0 };
	$self->{"borderStyle"}   = shift;
	$self->{"overwriteCell"} = shift // 0;

	$self->{"matrix"}   = [];
	$self->{"collsDef"} = [];
	$self->{"rowsDef"}  = [];
	
	$self->{"renderOrderEvt"}       = Event->new();

	return $self;
}

sub AddColDef {
	my $self        = shift;
	my $key         = shift;
	my $width       = shift;
	my $backgStyle  = shift;
	my $borderStyle = shift;

	die "Col with key: $key already exists" if ( defined first { $_->GetKey() eq $key } @{ $self->{"collsDef"} } );

	my $pos = scalar( @{ $self->{"collsDef"} } );
	my $colDef = TableCollDef->new( $pos, $key, $width, $backgStyle, $borderStyle );
	push( @{ $self->{"collsDef"} }, $colDef );

	my @rows = (undef) x $self->GetRowCnt();

	push( @{ $self->{"matrix"} }, \@rows );

	return $colDef;

}

sub AddRowDef {
	my $self        = shift;
	my $key         = shift;
	my $height      = shift;
	my $backgStyle  = shift;
	my $borderStyle = shift;

	die "Row with key: $key already exists" if ( defined first { $_->GetKey() eq $key } @{ $self->{"rowsDef"} } );

	my $pos = scalar( @{ $self->{"rowsDef"} } );
	my $rowDef = TableRowDef->new( $pos, $key, $height, $backgStyle, $borderStyle );
	push( @{ $self->{"rowsDef"} }, $rowDef );

	foreach my $col ( @{ $self->{"matrix"} } ) {

		push( @{$col}, undef );

	}

	return $rowDef;

}

sub AddCell {
	my $self        = shift;
	my $startCol    = shift;
	my $startRow    = shift;
	my $collCnt     = shift // 1;
	my $rowCnt      = shift // 1;
	my $text        = shift;
	my $textStyle   = shift;
	my $backgStyle  = shift;
	my $borderStyle = shift;

	#die "End col ($endCol) must be greater than star col ($startCol)" if ( $endCol < $startCol );
	#die "End row ($endRow) must be greater than star row ($startRow)" if ( $endRow < $startRow );

	die "Start column index ($startCol) is grater than column count (" . ( $self->GetColCnt() ) . ")"
	  if ( $startCol + 1 > $self->GetColCnt() );
	die "End column index (" . $startCol + $collCnt . ") is grater than column count (" . ( $self->GetColCnt() ) . ")"
	  if ( $startCol + $collCnt > $self->GetColCnt() );

	die "Start row index ($startRow) is grater than row count (" . ( $self->GetRowCnt() ) . ")"
	  if ( $startRow + 1 > $self->GetRowCnt() );
	die "End row index (" . $startRow + $rowCnt . ") is grater than row count (" . ( $self->GetRowCnt() ) . ")"
	  if ( $startRow + $rowCnt > $self->GetRowCnt() );

	die "Text style must be defined if text is set (cell: [$startCol, $startRow]" if ( defined $text && !defined $textStyle );

	my $cell = TableCell->new( $startCol, $startRow, $text, $textStyle, $backgStyle, $borderStyle, $collCnt, $rowCnt );

	for ( my $i = $startCol ; $i < $startCol + $collCnt ; $i++ ) {

		# Go through columns

		for ( my $j = $startRow ; $j < $startRow + $rowCnt ; $j++ ) {

			# Go othrough rows

			# 1) If position is not empty, check if we can owererite

			if ( defined $self->{"matrix"}->[$i]->[$j] && !$self->{"overwriteCell"} ) {
				die "Cell position [$i,$j] is already occupied and cell overwriting is not alowed";
			}

			if ( defined $self->{"matrix"}->[$i]->[$j] && $self->{"overwriteCell"} && $self->{"matrix"}->[$i]->[$j]->GetIsMerged() > 0 ) {

				die "Cell position [$i,$j] is occupied by merged cell. Overwriting of merged cell is not alowed ";
			}

			$self->{"matrix"}->[$i]->[$j] = $cell;
		}
	}
}

sub GetRenderPriority {
	my $self = shift;
	
	my %prior = ();

	$prior{ Enums->DrawPriority_COLLBACKG }  = 1;    # column background
	$prior{ Enums->DrawPriority_COLLBORDER } = 2;    # column border
	$prior{ Enums->DrawPriority_ROWBACKG }   = 3;    # row background
	$prior{ Enums->DrawPriority_ROWBORDER }  = 4;    # row border
	$prior{ Enums->DrawPriority_CELLBACKG }  = 5;    # cell background
	$prior{ Enums->DrawPriority_CELLBORDER } = 6;    # cell border
	$prior{ Enums->DrawPriority_CELLTEXT }   = 7;    # cell text
	$prior{ Enums->DrawPriority_TABBORDER }  = 8;    # table frame
	
	if( $self->{"renderOrderEvt"}->Handlers()){
		
		$self->{"renderOrderEvt"}->Do(\%prior);
	}
 
	return %prior;
}

sub GetOrigin {
	my $self = shift;

	return $self->{"origin"};
}

sub GetBorderStyle {
	my $self = shift;

	return $self->{"borderStyle"};

}

sub GetDrawPriority {
	my $self = shift;

	return $self->{"drawPriority"};
}

sub GetCollsDef {
	my $self = shift;

	return @{ $self->{"collsDef"} };
}

sub GetRowsDef {
	my $self = shift;

	return @{ $self->{"rowsDef"} };
}

sub GetColCnt {
	my $self = shift;

	return scalar( @{ $self->{"matrix"} } );

}

sub GetRowCnt {
	my $self = shift;

	my $row = 0;

	if ( scalar( @{ $self->{"matrix"} } ) ) {
		$row = scalar( @{ $self->{"matrix"}->[0] } );
	}

	return $row;

}

sub GetWidth {
	my $self = shift;

	my $w = 0;
	$w += $_->GetWidth() for ( @{ $self->{"collsDef"} } );

	return $w;
}

sub GetHeight {
	my $self = shift;

	my $h = 0;
	$h += $_->GetHeight() for ( @{ $self->{"rowsDef"} } );

	return $h;
}

sub GetAllCells {
	my $self = shift;

	my @cells = uniq( grep { defined $_ } map( @{$_}, @{ $self->{"matrix"} } ) );

	return @cells;
}

sub GetCellLimits {
	my $self    = shift;
	my $cell    = shift;
	my $margins = shift;

	my $col = $cell->GetPosX();
	my $row = $cell->GetPosY();

	my %lim = ();

	if ( $col > 0 ) {
		$lim{"xMin"} += $_->GetWidth() for ( @{ $self->{"collsDef"} }[ 0 .. ( $col - 1 ) ] );
	}
	else {
		$lim{"xMin"} = 0;
	}
	$lim{"xMax"} += $_->GetWidth() for ( @{ $self->{"collsDef"} }[ 0 .. ( $col + $cell->GetXPosCnt() - 1 ) ] );

	if ( $row > 0 ) {
		$lim{"yMin"} += $_->GetHeight() for ( @{ $self->{"rowsDef"} }[ 0 .. ( $row - 1 ) ] );
	}
	else {
		$lim{"yMin"} = 0;
	}

	$lim{"yMax"} += $_->GetHeight() for ( @{ $self->{"rowsDef"} }[ 0 .. ( $row + $cell->GetYPosCnt() - 1 ) ] );

	if ($margins) {
		$lim{"xMin"} += $margins;
		$lim{"xMax"} -= $margins;
		$lim{"yMin"} += $margins;
		$lim{"yMax"} -= $margins;
	}

	return %lim;
}

sub GetCollLimits {
	my $self    = shift;
	my $collDef = shift;

	#  x limits
	my %lim = ();

	if ( $collDef->GetIndex() > 0 ) {
		$lim{"xMin"} += $_->GetWidth() for ( @{ $self->{"collsDef"} }[ 0 .. ( $collDef->GetIndex() - 1 ) ] );
	}
	else {
		$lim{"xMin"} = 0;
	}
	$lim{"xMax"} = $lim{"xMin"} + $collDef->GetWidth();

	# y limits

	$lim{"yMin"} = 0;
	$lim{"yMax"} += $_->GetHeight() for ( @{ $self->{"rowsDef"} } );

	return %lim;
}

sub GetRowLimits {
	my $self   = shift;
	my $rowDef = shift;

	#  x limits
	my %lim = ();

	$lim{"xMin"} = 0;
	$lim{"xMax"} += $_->GetWidth() for ( @{ $self->{"collsDef"} } );

	# y limits

	if ( $rowDef->GetIndex() > 0 ) {
		$lim{"yMin"} += $_->GetHeight() for ( @{ $self->{"rowsDef"} }[ 0 .. ( $rowDef->GetIndex() - 1 ) ] );
	}
	else {
		$lim{"yMin"} = 0;
	}
	$lim{"yMax"} = $lim{"yMin"} + $rowDef->GetHeight();

	return %lim;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

