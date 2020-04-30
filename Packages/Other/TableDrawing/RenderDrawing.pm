
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::RenderDrawing;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Other::TableDrawing::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub RenderTables {
	my $self        = shift;
	my $drawBuilder = shift;
	my $tables      = shift;
	my $tablesLim   = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $offsetX     = shift;
	my $offsetY     = shift;
	
	$drawBuilder->Init();

	my @tables = $tables->GetAllTables();
	foreach my $table (@tables) {

		my $originX = $offsetX;
		my $originY = $offsetY;

		# Consider table offset
		my $o = $table->GetOrigin();
		$originX += $o->{"x"} * $scaleX;

		if ( $drawBuilder->GetCoordSystem() eq Enums->CoordSystem_LEFTTOP ) {

			# X axis reise to right, Y axis raise to bottom

			$originY += $o->{"y"} * $scaleY;
		}
		elsif ( $drawBuilder->GetCoordSystem() eq Enums->CoordSystem_LEFTBOT ) {

			# X axis reise to right, Y axis raise to top

			$originY -= $o->{"y"} * $scaleY;

		}

		$self->__RenderTable( $table, $drawBuilder, $tablesLim, $scaleX, $scaleY, $originX, $originY );

	}

	$drawBuilder->Finish();
}

sub __RenderTable {
	my $self        = shift;
	my $table       = shift;
	my $drawBuilder = shift;
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	my %priority = $table->GetRenderPriority();

	# Sort render operation by priority (smaller number => heigher priority)
	my @t = map { [ $priority{$_}, $_ ] } keys %priority;

	my @prior = map { $_->[1] } sort { $a->[0] <=> $b->[0] } map { [ $priority{$_}, $_ ] } keys %priority;

	foreach my $p (@prior) {

		$self->__RenderBorderTable( $table, $drawBuilder, $tblsLim, $scaleX, $scaleY, $originX, $originY ) if ( $p eq Enums->DrawPriority_TABBORDER );
		$self->__RenderBorderColl( $table, $drawBuilder, $tblsLim, $scaleX, $scaleY, $originX, $originY ) if ( $p eq Enums->DrawPriority_COLLBORDER );
		$self->__RenderBorderRow( $table, $drawBuilder, $tblsLim, $scaleX, $scaleY, $originX, $originY ) if ( $p eq Enums->DrawPriority_ROWBORDER );
		$self->__RenderBorderCell( $table, $drawBuilder, $tblsLim, $scaleX, $scaleY, $originX, $originY ) if ( $p eq Enums->DrawPriority_CELLBORDER );
		$self->__RenderBackgColl( $table, $drawBuilder, $tblsLim, $scaleX, $scaleY, $originX, $originY ) if ( $p eq Enums->DrawPriority_COLLBACKG );
		$self->__RenderBackgRow( $table, $drawBuilder, $tblsLim, $scaleX, $scaleY, $originX, $originY ) if ( $p eq Enums->DrawPriority_ROWBACKG );
		$self->__RenderBackgCell( $table, $drawBuilder, $tblsLim, $scaleX, $scaleY, $originX, $originY ) if ( $p eq Enums->DrawPriority_CELLBACKG );
		$self->__RenderTextCell( $table, $drawBuilder, $tblsLim, $scaleX, $scaleY, $originX, $originY )
		  if ( $p eq Enums->DrawPriority_CELLTEXT );

	}
}

sub __RenderBorderTable {
	my $self        = shift;
	my $table       = shift;
	my $drawBuilder = shift;
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	# Draw table border
	if ( $table->GetBorderStyle() ) {

		my %tabLim = ();

		$tabLim{"xMin"} = 0;
		$tabLim{"xMax"} = $table->GetWidth();
		$tabLim{"yMin"} = 0;
		$tabLim{"yMax"} = $table->GetHeight();

		$self->__DrawBorder( $drawBuilder, $table->GetBorderStyle(), \%tabLim, $tblsLim, $scaleX, $scaleY, $originX, $originY );
	}
}

sub __RenderBorderColl {
	my $self        = shift;
	my $table       = shift;
	my $drawBuilder = shift;
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	# 1)Draw column border
	foreach my $colDef ( $table->GetCollsDef() ) {

		my %collLim = $table->GetCollLimits($colDef);

		if ( $colDef->GetBorderStyle() ) {
			$self->__DrawBorder( $drawBuilder, $colDef->GetBorderStyle(), \%collLim, $tblsLim, $scaleX, $scaleY, $originX, $originY );
		}

	}
}

sub __RenderBorderRow {
	my $self        = shift;
	my $table       = shift;
	my $drawBuilder = shift;
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	# 2) Draw row border
	foreach my $rowDef ( $table->GetRowsDef() ) {

		my %rowLim = $table->GetRowLimits($rowDef);

		# 1) draw cell border
		if ( $rowDef->GetBorderStyle() ) {
			$self->__DrawBorder( $drawBuilder, $rowDef->GetBorderStyle(), \%rowLim, $tblsLim, $scaleX, $scaleY, $originX, $originY );
		}

	}

}

sub __RenderBorderCell {
	my $self        = shift;
	my $table       = shift;
	my $drawBuilder = shift;
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	# 3) Draw cells
	my @cels = $table->GetAllCells();

	foreach my $cell (@cels) {

		my %cellLim = $table->GetCellLimits($cell);

		# 2) draw cell border
		if ( $cell->GetBorderStyle() ) {
			$self->__DrawBorder( $drawBuilder, $cell->GetBorderStyle(), \%cellLim, $tblsLim, $scaleX, $scaleY, $originX, $originY );
		}

	}

}

sub __RenderBackgColl {
	my $self        = shift;
	my $table       = shift;
	my $drawBuilder = shift;
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	# 1)Draw column border
	foreach my $colDef ( $table->GetCollsDef() ) {

		my %collLim = $table->GetCollLimits($colDef);

		if ( defined $colDef->GetBackgStyle() ) {

			$self->__DrawBackground( $drawBuilder, $colDef->GetBackgStyle(), \%collLim, $tblsLim, $scaleX, $scaleY, $originX, $originY );
		}
	}
}

sub __RenderBackgRow {
	my $self        = shift;
	my $table       = shift;
	my $drawBuilder = shift;
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	# 2) Draw row border
	foreach my $rowDef ( $table->GetRowsDef() ) {

		my %rowLim = $table->GetRowLimits($rowDef);
		if ( $rowDef->GetBackgStyle() ) {
			$self->__DrawBackground( $drawBuilder, $rowDef->GetBackgStyle(), \%rowLim, $tblsLim, $scaleX, $scaleY, $originX, $originY );
		}
	}

}

sub __RenderBackgCell {
	my $self        = shift;
	my $table       = shift;
	my $drawBuilder = shift;
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	# 3) Draw cells
	my @cels = $table->GetAllCells();

	foreach my $cell (@cels) {

		my %cellLim = $table->GetCellLimits($cell);

		# 1) Draw cell background
		if ( $cell->GetBackgStyle() ) {
			$self->__DrawBackground( $drawBuilder, $cell->GetBackgStyle(), \%cellLim, $tblsLim, $scaleX, $scaleY, $originX, $originY );
		}
	}

}

sub __RenderTextCell {
	my $self        = shift;
	my $table       = shift;
	my $drawBuilder = shift;
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	# 3) Draw cells
	my @cels = $table->GetAllCells();

	foreach my $cell (@cels) {

		my %cellLim = $table->GetCellLimits($cell);

		# 3) draw cell text
		if ( defined $cell->GetText() ) {

			my %cellLimTxt = $table->GetCellLimits( $cell, $cell->GetTextStyle()->GetMargin() );

			$self->__DrawText( $drawBuilder, $cell->GetText(), $cell->GetTextStyle(), \%cellLimTxt, $tblsLim, $scaleX, $scaleY, $originX, $originY );
		}
	}

}

sub __DrawBackground {
	my $self        = shift;
	my $drawBuilder = shift;
	my $backgStyle  = shift;
	my %backLim     = %{ shift(@_) };
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	my %coord = $self->__PrepareBoxCoord( $drawBuilder->GetCoordSystem(),
										  $drawBuilder->GetCanvasMargin(),
										  \%backLim, $tblsLim, $scaleX, $scaleY, $originX, $originY );

	my $rW = abs( $coord{"RT"}->{"x"} - $coord{"LT"}->{"x"} );
	my $rH = abs( $coord{"LT"}->{"y"} - $coord{"LB"}->{"y"} );

	my $startX = $coord{"LT"}->{"x"};
	my $startY = undef;

	if ( $drawBuilder->GetCoordSystem() eq Enums->CoordSystem_LEFTTOP ) {

		# X axis reise to right, Y axis raise to bottom

		$startY = $coord{"LT"}->{"y"};
	}
	elsif ( $drawBuilder->GetCoordSystem() eq Enums->CoordSystem_LEFTBOT ) {

		# X axis reise to right, Y axis raise to top

		$startY = $coord{"LB"}->{"y"};

	}

	$drawBuilder->DrawRectangle( $startX, $startY, $rW, $rH, $backgStyle );

}

sub __DrawText {
	my $self        = shift;
	my $drawBuilder = shift;
	my $text        = shift;
	my $textStyle   = shift;
	my %celLim      = %{ shift(@_) };
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	my %coord = $self->__PrepareBoxCoord( $drawBuilder->GetCoordSystem(),
										  $drawBuilder->GetCanvasMargin(),
										  \%celLim, $tblsLim, $scaleX, $scaleY, $originX, $originY );

	my $rW     = abs( $coord{"RT"}->{"x"} - $coord{"LT"}->{"x"} );
	my $rH     = abs( $coord{"LT"}->{"y"} - $coord{"LB"}->{"y"} );
	my $startX = $coord{"LT"}->{"x"};
	my $startY = undef;

	if ( $drawBuilder->GetCoordSystem() eq Enums->CoordSystem_LEFTTOP ) {

		# X axis reise to right, Y axis raise to bottom

		$startY = $coord{"LT"}->{"y"};
	}
	elsif ( $drawBuilder->GetCoordSystem() eq Enums->CoordSystem_LEFTBOT ) {

		# X axis reise to right, Y axis raise to top

		$startY = $coord{"LB"}->{"y"};

	}

	if ( $textStyle->GetTextType() eq Enums->TextStyle_LINE ) {

		$drawBuilder->DrawTextLine( $startX, $startY, $rW, $rH, $text, $textStyle->GetSize(), $scaleX, $scaleY, $textStyle->GetColor(),
									$textStyle->GetFont(),
									$textStyle->GetFontFamily(),
									$textStyle->GetVAlign(),
									$textStyle->GetHAlign() );

	}
	elsif ( $textStyle->GetTextType() eq Enums->TextStyle_MULTILINE ) {

		my @textLines = split( "\n", $text );

		if ( $drawBuilder->GetCoordSystem() eq Enums->CoordSystem_LEFTBOT ) {

			# X axis reise to right, Y axis raise to top

			@textLines = reverse(@textLines);

		}

		$drawBuilder->DrawTextMultiLine( $startX, $startY, $rW, $rH, \@textLines, $textStyle->GetSize(), $scaleX, $scaleY, $textStyle->GetColor(),
										 $textStyle->GetFont(),
										 $textStyle->GetFontFamily(),
										 $textStyle->GetVAlign(),
										 $textStyle->GetHAlign() );

	}
	elsif ( $textStyle->GetTextType() eq Enums->TextStyle_PARAGRAPH ) {

		$drawBuilder->DrawTextParagraph( $startX, $startY, $rW, $rH, $text, $textStyle->GetSize(), $scaleX, $scaleY, $textStyle->GetColor(),
										 $textStyle->GetFont(),
										 $textStyle->GetFontFamily(),
										 $textStyle->GetVAlign(),
										 $textStyle->GetHAlign() );

	}

}

sub __DrawBorder {
	my $self        = shift;
	my $drawBuilder = shift;
	my $borderStyle = shift;
	my %borderLim   = %{ shift(@_) };
	my $tblsLim     = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	my %coord = $self->__PrepareBoxCoord( $drawBuilder->GetCoordSystem(),
										  $drawBuilder->GetCanvasMargin(),
										  \%borderLim, $tblsLim, $scaleX, $scaleY, $originX, $originY );

	my %edges = $borderStyle->GetAllEdgesStyle();

	foreach my $edgeKey ( keys %edges ) {

		next unless ( defined $edges{$edgeKey} );

		my $xStrkS = undef;
		my $xStrkE = undef;
		my $yStrkS = undef;
		my $yStrkE = undef;

		if ( $edgeKey eq "top" ) {

			$xStrkS = $coord{"LT"}->{"x"};
			$xStrkE = $coord{"RT"}->{"x"};
			$yStrkS = $coord{"LT"}->{"y"};
			$yStrkE = $coord{"RT"}->{"y"};
		}
		elsif ( $edgeKey eq "bot" ) {

			$xStrkS = $coord{"LB"}->{"x"};
			$xStrkE = $coord{"RB"}->{"x"};
			$yStrkS = $coord{"LB"}->{"y"};
			$yStrkE = $coord{"RB"}->{"y"};
		}
		elsif ( $edgeKey eq "left" ) {

			$xStrkS = $coord{"LB"}->{"x"};
			$xStrkE = $coord{"LT"}->{"x"};
			$yStrkS = $coord{"LB"}->{"y"};
			$yStrkE = $coord{"LT"}->{"y"};
		}
		elsif ( $edgeKey eq "right" ) {

			$xStrkS = $coord{"RB"}->{"x"};
			$xStrkE = $coord{"RT"}->{"x"};
			$yStrkS = $coord{"RB"}->{"y"};
			$yStrkE = $coord{"RT"}->{"y"};
		}

		if ( $edges{$edgeKey}->GetStyle() eq Enums->EdgeStyle_SOLIDSTROKE ) {

			$drawBuilder->DrawSolidStroke( $xStrkS, $yStrkS, $xStrkE, $yStrkE, $edges{$edgeKey}->GetWidth(), $edges{$edgeKey}->GetColor() );

		}
		elsif ( $edges{$edgeKey}->GetStyle() eq Enums->EdgeStyle_DASHED ) {

			$drawBuilder->DrawDashedStroke( $xStrkS, $yStrkS, $xStrkE, $yStrkE,
											$edges{$edgeKey}->GetWidth(),
											$edges{$edgeKey}->GetColor(),
											$edges{$edgeKey}->GetDashLen(),
											$edges{$edgeKey}->GetGapLen() );

		}
	}
}

sub __PrepareBoxCoord {
	my $self         = shift;
	my $coordSystem  = shift;
	my $canvasMargin = shift;
	my %objLim       = %{ shift(@_) };
	my $tblsLim      = shift;
	my $scaleX       = shift;
	my $scaleY       = shift;
	my $originX      = shift;
	my $originY      = shift;

	my %boxPoints = ();
	$boxPoints{"LT"} = { "x" => $objLim{"xMin"}, "y" => $objLim{"yMin"} };
	$boxPoints{"RT"} = { "x" => $objLim{"xMax"}, "y" => $objLim{"yMin"} };
	$boxPoints{"LB"} = { "x" => $objLim{"xMin"}, "y" => $objLim{"yMax"} };
	$boxPoints{"RB"} = { "x" => $objLim{"xMax"}, "y" => $objLim{"yMax"} };

	if ( $coordSystem eq Enums->CoordSystem_LEFTTOP ) {

		# X axis reise to right, Y axis raise to bottom

		# nothin change, neither x, nor y
	}
	elsif ( $coordSystem eq Enums->CoordSystem_LEFTBOT ) {

		# X axis reise to right, Y axis raise to top

		# x without change

		# y change
		$boxPoints{"LT"}->{"y"} = ( $tblsLim->{"yMax"} - $tblsLim->{"yMin"} ) - $boxPoints{"LT"}->{"y"};
		$boxPoints{"RT"}->{"y"} = ( $tblsLim->{"yMax"} - $tblsLim->{"yMin"} ) - $boxPoints{"RT"}->{"y"};
		$boxPoints{"LB"}->{"y"} = ( $tblsLim->{"yMax"} - $tblsLim->{"yMin"} ) - $boxPoints{"LB"}->{"y"};
		$boxPoints{"RB"}->{"y"} = ( $tblsLim->{"yMax"} - $tblsLim->{"yMin"} ) - $boxPoints{"RB"}->{"y"};
	}

	# consider scale
	$boxPoints{"LT"}->{"x"} *= $scaleX;
	$boxPoints{"RT"}->{"x"} *= $scaleX;
	$boxPoints{"LB"}->{"x"} *= $scaleX;
	$boxPoints{"RB"}->{"x"} *= $scaleX;

	$boxPoints{"LT"}->{"y"} *= $scaleY;
	$boxPoints{"RT"}->{"y"} *= $scaleY;
	$boxPoints{"LB"}->{"y"} *= $scaleY;
	$boxPoints{"RB"}->{"y"} *= $scaleY;

	# consider magin and origin
	$boxPoints{"LT"}->{"x"} += $canvasMargin + $originX;
	$boxPoints{"RT"}->{"x"} += $canvasMargin + $originX;
	$boxPoints{"LB"}->{"x"} += $canvasMargin + $originX;
	$boxPoints{"RB"}->{"x"} += $canvasMargin + $originX;

	$boxPoints{"LT"}->{"y"} += $canvasMargin + $originY;
	$boxPoints{"RT"}->{"y"} += $canvasMargin + $originY;
	$boxPoints{"LB"}->{"y"} += $canvasMargin + $originY;
	$boxPoints{"RB"}->{"y"} += $canvasMargin + $originY;

	return %boxPoints;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

