
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::TableDrawing;

#3th party library
use strict;
use warnings;
use Storable qw(dclone);

#local library
use aliased 'Packages::Other::TableDrawing::Enums';
use aliased 'Packages::Other::TableDrawing::Table::Table';
use aliased 'Packages::Other::TableDrawing::RenderDrawing';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"units"}         = shift // Enums->Units_PT;    # units which are used for drawing
	$self->{"overwriteCell"} = shift // 1;                  # Allow overfrite cell on same position as new cell (former cell can't be merged)

	$self->{"tables"} = [];
	$self->{"scaleX"} = 1;
	$self->{"scaleY"} = 1;

	return $self;
}

sub AddTable {
	my $self        = shift;
	my $key         = shift;
	my $origin      = shift // { "x" => 0, "y" => 0 };
	my $borderStyle = shift;

	my $t = Table->new( $key, $origin, $borderStyle, $self->{"overwriteCell"} );

	push( @{ $self->{"tables"} }, $t );

	return $t;
}

sub DuplicateTable {
	my $self  = shift;
	my $key   = shift;
	my $table = shift;
	
	my $dupl  = dclone($table);
	
	$dupl->{"key"} = $key;
	
	push( @{ $self->{"tables"} }, $dupl );
	
	return $dupl;
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
	my $originX     = shift // 0; # this offset do not consider ScaleX
	my $originY     = shift // 0;  # this offset do not consider ScaleY

	my %tblsLim = $self->GetOriLimits();

	RenderDrawing->RenderTables( $drawBuilder, $self->{"tables"}, \%tblsLim, $scaleX, $scaleY, $originX, $originY );
	
	return 1;
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

	my $paragraph = "erci ent ulluptat vel eum zzriure feuguero core conseni
+s adignim irilluptat praessit la con henit velis dio ex enim ex ex eu
+guercilit il enismol eseniam, suscing essequis nit iliquip erci blam 
+dolutpatisi.
Orpero do odipit ercilis ad er augait ing ex elit autatio od minisis a
+mconsequam";

	$tMain->AddCell( 0, 0, 3,     undef, $paragraph, $c1TextStyle, BackgStyle->new( Enums->BackgStyle_SOLIDCLR, Color->new( 255, 0,   0 ) ) );
	$tMain->AddCell( 1, 1, undef, undef, undef,      undef,        BackgStyle->new( Enums->BackgStyle_SOLIDCLR, Color->new( 0,   255, 0 ) ) );
	$tMain->AddCell( 2, 2, undef, undef, undef,      undef,        BackgStyle->new( Enums->BackgStyle_SOLIDCLR, Color->new( 0,   0,   255 ) ) );

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

