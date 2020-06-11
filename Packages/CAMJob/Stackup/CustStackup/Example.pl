#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use aliased 'Packages::CAMJob::Stackup::CustStackup::CustStackup';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::PDFDrawing::PDFDrawing';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsBuilder';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::InCAM::InCAM';



my $inCAM = InCAM->new();
#my $jobId    = "d152456"; #Outer RigidFLex TOP
#my $jobId    = "d270787"; #Outer RigidFLex BOT
#my $jobId    = "d261919"; # standard vv 10V
#my $jobId = "d274753"; # standard vv 8V
#my $jobId = "d274986"; # standard vv 4V
#my $jobId = "d266566"; # inner flex
#my $jobId = "d146753"; # 1v flex
#my $jobId = "d267628" ; # flex 2v + stiff
#my $jobId = "d064915"; # neplat
#my $jobId = "d275112"; # standard 1v
#my $jobId = "d275162"; # standard 2v


my $jobId = "x66093"; # standard vv 4V
my $step = "panel";

# 1) Init customer stackup class
my $newCustStckp = CustStackup->new($inCAM, $jobId,$step);

# 2) Build stackup
$newCustStckp->Build();

# 3) Generate output by some drawer

# Init Draw Builder
my $a4W = 210; #mm
my $a4H = 290; #mm


my ($w, $h) = $newCustStckp->GetSize();
my $rotation = $h*1.3 < $w && $w > $a4W ? 270 : undef; 
my $canvasX = $rotation ? $a4H : $a4W;
my $canvasY = $rotation ? $a4W : $a4H;
my $margin = 15;


my $p      = 'c:/Export/Test/test.pdf';

unlink($p);
my $drawBuilder = PDFDrawing->new( TblDrawEnums->Units_MM, $p, undef, [$canvasX, $canvasY], $margin, $rotation );
#my $drawBuilder = PDFDrawing->new( TblDrawEnums->Units_MM, undef, $p, [$canvasX, $canvasY], $margin, $rotation );
 
 
# Gemerate output

$newCustStckp->Output($drawBuilder, 1);



#
#my $tMain = $tDrawing->AddTable("Main");
#
## Add columns
#
#my $clmn1BorderStyle = BorderStyle->new();
#$clmn1BorderStyle->AddEdgeStyle( "top",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 0,   100 ) );
#$clmn1BorderStyle->AddEdgeStyle( "bot",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 100, 100 ) );
#$clmn1BorderStyle->AddEdgeStyle( "left",  Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 0,   255, 0 ) );
#$clmn1BorderStyle->AddEdgeStyle( "right", Enums->EdgeStyle_DASHED,      2, Color->new( 0,   255, 100 ), 2, 5 );
#
#$tMain->AddColDef( "zone_0", 5, $clmn1BorderStyle );
#
#$tMain->AddColDef( "zone_a", 10 );
#$tMain->AddColDef( "zone_b", 20 );
#$tMain->AddColDef( "zone_c", 30 );
#
## Add rows
#my $row1BorderStyle = BorderStyle->new();
#$row1BorderStyle->AddEdgeStyle( "top",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 0,   100 ) );
#$row1BorderStyle->AddEdgeStyle( "bot",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 100, 100 ) );
#$row1BorderStyle->AddEdgeStyle( "left",  Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 0,   255, 0 ) );
#$row1BorderStyle->AddEdgeStyle( "right", Enums->EdgeStyle_DASHED,      2, Color->new( 0,   255, 100 ), 2, 5 );
#
#$tMain->AddRowDef( "row_1", 10, $row1BorderStyle );
#$tMain->AddRowDef( "row_2", 20 );
#$tMain->AddRowDef( "row_3", 30 );
#$tMain->AddRowDef( "row_4", 40 );
#
## Add cell
#my $c1TextStyle = TextStyle->new( Enums->TextStyle_PARAGRAPH, 3, undef, undef, undef, undef, undef, 2 );
#
#my $paragraph = "erci ent ulluptat vel eum zzriure feuguero core conseni
#+s adignim irilluptat praessit la con henit velis dio ex enim ex ex eu
#+guercilit il enismol eseniam, suscing essequis nit iliquip erci blam 
#+dolutpatisi.
#Orpero do odipit ercilis ad er augait ing ex elit autatio od minisis a
#+mconsequam";
#
#$tMain->AddCell( 0, 0, 3,     undef, $paragraph, $c1TextStyle, BackgStyle->new( Enums->BackgStyle_SOLIDCLR, Color->new( 255, 0,   0 ) ) );
#$tMain->AddCell( 1, 1, undef, undef, undef,      undef,        BackgStyle->new( Enums->BackgStyle_SOLIDCLR, Color->new( 0,   255, 0 ) ) );
#$tMain->AddCell( 2, 2, undef, undef, undef,      undef,        BackgStyle->new( Enums->BackgStyle_SOLIDCLR, Color->new( 0,   0,   255 ) ) );
#
#my $c3BackStyle = BackgStyle->new( Enums->BackgStyle_SOLIDCLR, Color->new( 100, 100, 100 ) );
#my $c3BorderStyle = BorderStyle->new();
#
#$c3BorderStyle->AddEdgeStyle( "top",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 0,   100 ) );
#$c3BorderStyle->AddEdgeStyle( "bot",   Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 255, 100, 100 ) );
#$c3BorderStyle->AddEdgeStyle( "left",  Enums->EdgeStyle_SOLIDSTROKE, 2, Color->new( 0,   255, 0 ) );
#$c3BorderStyle->AddEdgeStyle( "right", Enums->EdgeStyle_DASHED,      2, Color->new( 0,   255, 100 ), 2, 5 );
#
#$tMain->AddCell( 3, 3, undef, undef, undef, undef, $c3BackStyle, $c3BorderStyle );
#
## Init Draw Builder
#my @media  = ( 150, 200 );
#my $margin = 0;
#my $p      = 'c:/Export/Test/test.pdf';
#
#unlink($p);
#my $drawBuilder = PDFDrawing->new( Enums->Units_MM, \@media, $margin, $p );
#my ( $scaleX, $scaleY ) = GeometryHelper->ScaleDrawingInCanvasSize( $tDrawing, $drawBuilder );
#my $xOffset = GeometryHelper->HAlignDrawingInCanvasSize( $tDrawing, $drawBuilder, EnumsBuilder->HAlign_LEFT, $scaleX, $scaleY );
#my $yOffset = GeometryHelper->VAlignDrawingInCanvasSize( $tDrawing, $drawBuilder, EnumsBuilder->VAlign_BOT, $scaleX, $scaleY );
#
##my  = $tDrawing->FitToCanvas( $w, $h );
#
#$tDrawing->Draw( $drawBuilder, $scaleX, $scaleY, $xOffset, $yOffset );
