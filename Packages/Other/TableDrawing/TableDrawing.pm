
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::TableDrawing;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Other::TableDrawing::Enums';
use aliased 'Packages::Other::TableDrawing::Table::Table';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"units"}         = shift // Enums->Units_PT;    # units which are used for drawing
	$self->{"overwriteCell"} = shift // 1;                  #

	$self->{"tables"} = [];
	$self->{"scaleX"} = 1;
	$self->{"scaleY"} = 1;

	return $self;
}

sub AddTable {
	my $self         = shift;
	my $key          = shift;
	my $origin       = shift // { "x" => 0, "y" => 0 };
	my $drawPriority = shift // Enums->DrawPriority_CELLABOVE;

	my $t = Table->new( $key, $origin, $drawPriority, $self->{"overwriteCell"} );

	push( @{ $self->{"tables"} }, $t );

	return $t;
}

sub GetOriLimits {
	my $self = shift;

	my $minX = undef;
	my $maxX = undef;
	my $minY = undef;
	my $maxY = undef;

	for ( my $i = 0 ; $i < scalar( @{ $self->{"tables"} } ) ; $i++ ) {

		if ( !defined $minX || $self->{"tables"}->[$i]->GetOrigin()->{"x"} < $minX ) {
			$minX = $self->{"tables"}->[$i]->GetOrigin()->{"x"};
		}

		if ( !defined $minY || $self->{"tables"}->[$i]->GetOrigin()->{"y"} < $minY ) {
			$minY = $self->{"tables"}->[$i]->GetOrigin()->{"y"};
		}

		if ( !defined $maxX || $self->{"tables"}->[$i]->GetOrigin()->{"x"} + $self->{"tables"}->[$i]->GetWidth() > $maxX ) {
			$maxX = $self->{"tables"}->[$i]->GetOrigin()->{"x"} + $self->{"tables"}->[$i]->GetWidth();
		}

		if ( !defined $maxY || $self->{"tables"}->[$i]->GetOrigin()->{"y"} + $self->{"tables"}->[$i]->GetHeight() > $maxY ) {
			$maxY = $self->{"tables"}->[$i]->GetOrigin()->{"y"} + $self->{"tables"}->[$i]->GetHeight();
		}
	}

	my %lim = ();

	$lim{"xMin"} = $minX;
	$lim{"xMax"} = $maxX;
	$lim{"yMin"} = $minY;
	$lim{"yMax"} = $maxY;

	return %lim;
}

sub GetScaleLimits {
	my $self   = shift;
	my $scaleX = shift;
	my $scaleY = shift;

	my %lim = $self->GetOriLimits();

	$lim{"xMin"} *= $scaleX;
	$lim{"xMax"} *= $scaleX;
	$lim{"yMin"} *= $scaleY;
	$lim{"yMax"} *= $scaleY;

	return %lim;
}

sub Draw {
	my $self        = shift;
	my $drawBuilder = shift;
	my $scaleX      = shift // 1;
	my $scaleY      = shift // 1;
	my $originX     = shift // 0;
	my $originY     = shift // 0;

	#	die "Scale X is has been already set (" . sprintf( "%.2f", $self->{"scaleX"} ) . ") " if ( defined $scaleX && $self->{"scaleX"} != 1 );
	#	die "Scale Y is has been already set (" . sprintf( "%.2f", $self->{"scaleY"} ) . ") "
	#	  if ( defined $scaleY && $self->{"scaleY"} != 1 );

	#$scaleX = $self->{"scaleX"} if ( !defined $scaleX );
	#$scaleY = $self->{"scaleY"} if ( !defined $scaleY );

	$drawBuilder->Init();

	foreach my $table ( @{ $self->{"tables"} } ) {

		$self->__DrawTable( $table, $drawBuilder, $scaleX, $scaleY, $originX, $originY );

	}

	$drawBuilder->Finish();
}

sub __DrawTable {
	my $self        = shift;
	my $table       = shift;
	my $drawBuilder = shift;
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	my %lim = $self->GetOriLimits();

	# 1)Draw column border
	foreach my $colDef ( $table->GetCollsDef() ) {

		my %collLim = $table->GetCollLimits($colDef);

		$self->__DrawBorder( $drawBuilder, $colDef->GetBorderStyle(), \%collLim, \%lim, $scaleX, $scaleY, $originX, $originY );
	}

	# 2) Draw row border
	foreach my $rowDef ( $table->GetRowsDef() ) {

		my %rowLim = $table->GetRowLimits($rowDef);

		# 1) draw cell border
		$self->__DrawBorder( $drawBuilder, $rowDef->GetBorderStyle(), \%rowLim, \%lim, $scaleX, $scaleY, $originX, $originY );
	}

	# 3) Draw cells
	my @cels = $table->GetAllCells();

	foreach my $cell (@cels) {

		my %cellLim = $table->GetCellLimits($cell);

		# 1) Draw cell background
		$self->__DrawCellBackground( $drawBuilder, $cell, \%cellLim, \%lim, $scaleX, $scaleY, $originX, $originY );

		# 2) draw cell border
		$self->__DrawBorder( $drawBuilder, $cell->GetBorderStyle(), \%cellLim, \%lim, $scaleX, $scaleY, $originX, $originY );

		# 3) draw cell text
		if ( defined $cell->GetText() ) {

			my %cellLimTxt = $table->GetCellLimits( $cell, $cell->GetTextStyle()->GetMargin() );

			$self->__DrawText( $drawBuilder, $cell->GetText(), $cell->GetTextStyle(), \%cellLimTxt, \%lim, $scaleX, $scaleY, $originX, $originY );
		}
	}

}

sub __DrawCellBackground {
	my $self        = shift;
	my $drawBuilder = shift;
	my $cell        = shift;
	my %celLim      = %{ shift(@_) };
	my %lim         = %{ shift(@_) };
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	my %coord = $self->__PrepareBoxCoord( $drawBuilder->GetCoordSystem(),
										  $drawBuilder->GetCanvasMargin(),
										  \%celLim, \%lim, $scaleX, $scaleY, $originX, $originY );

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

	$drawBuilder->DrawRectangle( $startX, $startY, $rW, $rH, $cell->GetBackgStyle() );

}

sub __DrawText {
	my $self        = shift;
	my $drawBuilder = shift;
	my $text        = shift;
	my $textStyle   = shift;
	my %celLim      = %{ shift(@_) };
	my %lim         = %{ shift(@_) };
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	my %coord = $self->__PrepareBoxCoord( $drawBuilder->GetCoordSystem(),
										  $drawBuilder->GetCanvasMargin(),
										  \%celLim, \%lim, $scaleX, $scaleY, $originX, $originY );

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
	my %lim         = %{ shift(@_) };
	my $scaleX      = shift;
	my $scaleY      = shift;
	my $originX     = shift;
	my $originY     = shift;

	my %coord = $self->__PrepareBoxCoord( $drawBuilder->GetCoordSystem(),
										  $drawBuilder->GetCanvasMargin(),
										  \%borderLim, \%lim, $scaleX, $scaleY, $originX, $originY );

	my %edges = $borderStyle->GetAllEdgesStyle();

	foreach my $edgeKey ( keys %edges ) {

		next unless ( defined $edges{$edgeKey} );

		my $xStrkS = undef;
		my $xStrkE = undef;
		my $yStrkS = undef;
		my $yStrkE = undef;

		if ( $edgeKey eq "top" ) {

			$xStrkS = $coord{"LB"}->{"x"};
			$xStrkE = $coord{"RB"}->{"x"};
			$yStrkS = $coord{"LB"}->{"y"};
			$yStrkE = $coord{"LB"}->{"y"};
		}
		elsif ( $edgeKey eq "bot" ) {

			$xStrkS = $coord{"LB"}->{"x"};
			$xStrkE = $coord{"RB"}->{"x"};
			$yStrkS = $coord{"LT"}->{"y"};
			$yStrkE = $coord{"LT"}->{"y"};
		}
		elsif ( $edgeKey eq "left" ) {

			$xStrkS = $coord{"LB"}->{"x"};
			$xStrkE = $coord{"LB"}->{"x"};
			$yStrkS = $coord{"LB"}->{"y"};
			$yStrkE = $coord{"LT"}->{"y"};
		}
		elsif ( $edgeKey eq "right" ) {

			$xStrkS = $coord{"RB"}->{"x"};
			$xStrkE = $coord{"RB"}->{"x"};
			$yStrkS = $coord{"LB"}->{"y"};
			$yStrkE = $coord{"LT"}->{"y"};
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
	my %lim          = %{ shift(@_) };
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
		$boxPoints{"LT"}->{"y"} = ( $lim{"yMax"} - $lim{"yMin"} ) - $boxPoints{"LT"}->{"y"};
		$boxPoints{"RT"}->{"y"} = ( $lim{"yMax"} - $lim{"yMin"} ) - $boxPoints{"RT"}->{"y"};
		$boxPoints{"LB"}->{"y"} = ( $lim{"yMax"} - $lim{"yMin"} ) - $boxPoints{"LB"}->{"y"};
		$boxPoints{"RB"}->{"y"} = ( $lim{"yMax"} - $lim{"yMin"} ) - $boxPoints{"RB"}->{"y"};
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

	use aliased 'Packages::Other::TableDrawing::TableDrawing';
	use aliased 'Packages::Other::TableDrawing::DrawingBuilders::PDFDrawing::PDFDrawing';
	use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
	use aliased 'Packages::Other::TableDrawing::Table::Style::BackgStyle';
	use aliased 'Packages::Other::TableDrawing::DrawingBuilders::GeometryHelper';
	use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsBuilder';
	use aliased 'Packages::Other::TableDrawing::Table::Style::StrokeStyle';
	use aliased 'Packages::Other::TableDrawing::Table::Style::BorderStyle';
	use aliased 'Packages::Other::TableDrawing::Table::Style::TextStyle';

	my $tDrawing = TableDrawing->new( Enums->Units_MM );

	# Draw objects

	my $tMain = $tDrawing->AddTable("Main");

	# Add columns

	my $clmn1BorderStyle = BorderStyle->new();
	$clmn1BorderStyle->AddEdgeStyle( "top",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 0,   100 ) );
	$clmn1BorderStyle->AddEdgeStyle( "bot",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 100, 100 ) );
	$clmn1BorderStyle->AddEdgeStyle( "left",  Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 0,   255, 0 ) );
	$clmn1BorderStyle->AddEdgeStyle( "right", Enums->EdgeStyle_DASHED,      2, Color->new( 0,   255, 100 ), 2, 5 );

	$tMain->AddColDef( "zone_0", 5, $clmn1BorderStyle );

	$tMain->AddColDef( "zone_a", 10 );
	$tMain->AddColDef( "zone_b", 20 );
	$tMain->AddColDef( "zone_c", 30 );

	# Add rows
	my $row1BorderStyle = BorderStyle->new();
	$row1BorderStyle->AddEdgeStyle( "top",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 0,   100 ) );
	$row1BorderStyle->AddEdgeStyle( "bot",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 100, 100 ) );
	$row1BorderStyle->AddEdgeStyle( "left",  Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 0,   255, 0 ) );
	$row1BorderStyle->AddEdgeStyle( "right", Enums->EdgeStyle_DASHED,      2, Color->new( 0,   255, 100 ), 2, 5 );

	$tMain->AddRowDef( "row_1", 10, $row1BorderStyle );
	$tMain->AddRowDef( "row_2", 20 );
	$tMain->AddRowDef( "row_3", 30 );
	$tMain->AddRowDef( "row_4", 40 );

	# Add cell
	my $c1TextStyle = TextStyle->new( Enums->TextStyle_PARAGRAPH, 3, undef, undef, undef, undef, undef, 2 );
	
	my $paragraph="erci ent ulluptat vel eum zzriure feuguero core conseni
+s adignim irilluptat praessit la con henit velis dio ex enim ex ex eu
+guercilit il enismol eseniam, suscing essequis nit iliquip erci blam 
+dolutpatisi.
Orpero do odipit ercilis ad er augait ing ex elit autatio od minisis a
+mconsequam";
	
	$tMain->AddCell( 0, 0, 3, undef, $paragraph, $c1TextStyle, BackgStyle->new( Enums->BackgStyle_SOLIDCLR, Color->new( 255, 0,   0 ) ) );
	$tMain->AddCell( 1, 1, undef, undef, undef,    undef,        BackgStyle->new( Enums->BackgStyle_SOLIDCLR, Color->new( 0,   255, 0 ) ) );
	$tMain->AddCell( 2, 2, undef, undef, undef,    undef,        BackgStyle->new( Enums->BackgStyle_SOLIDCLR, Color->new( 0,   0,   255 ) ) );

	my $c3BackStyle = BackgStyle->new( Enums->BackgStyle_SOLIDCLR, Color->new( 100, 100, 100 ) );
	my $c3BorderStyle = BorderStyle->new();

	$c3BorderStyle->AddEdgeStyle( "top",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 0,   100 ) );
	$c3BorderStyle->AddEdgeStyle( "bot",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 100, 100 ) );
	$c3BorderStyle->AddEdgeStyle( "left",  Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 0,   255, 0 ) );
	$c3BorderStyle->AddEdgeStyle( "right", Enums->EdgeStyle_DASHED,      2, Color->new( 0,   255, 100 ), 2, 5 );

	$tMain->AddCell( 3, 3, undef, undef, undef, undef, $c3BackStyle, $c3BorderStyle );

	# Init Draw Builder
	my @media  = ( 150, 200 );
	my $margin = 0;
	my $p      = 'c:/Export/Test/test.pdf';

	unlink($p);
	my $drawBuilder = PDFDrawing->new( Enums->Units_MM, \@media, $margin, $p );
	my ( $scaleX, $scaleY ) = GeometryHelper->ScaleDrawingInCanvasSize( $tDrawing, $drawBuilder );
	my $xOffset = GeometryHelper->HAlignDrawingInCanvasSize( $tDrawing, $drawBuilder, EnumsBuilder->HAlign_LEFT, $scaleX, $scaleY );
	my $yOffset = GeometryHelper->VAlignDrawingInCanvasSize( $tDrawing, $drawBuilder, EnumsBuilder->VAlign_BOT, $scaleX, $scaleY );

	#my  = $tDrawing->FitToCanvas( $w, $h );

	$tDrawing->Draw( $drawBuilder, $scaleX, $scaleY, $xOffset, $yOffset );

}

1;

