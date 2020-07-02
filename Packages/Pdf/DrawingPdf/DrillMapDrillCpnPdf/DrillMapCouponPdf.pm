
#-------------------------------------------------------------------------------------------#
# Description: Creation Drill mpas for IPC3 coupons
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::DrawingPdf::DrillMapDrillCpnPdf::DrillMapCouponPdf;

#3th party library
use strict;
use warnings;
use English;
use List::Util qw[first];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::CAMJob::Microsection::CouponIPC3Main';
use aliased 'Packages::CAMJob::Microsection::CouponIPC3Drill';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePolyline';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::Other::TableDrawing::TableDrawing';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::InCAMDrawing::InCAMDrawing';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BackgStyle';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::GeometryHelper';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsBuilder';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::StrokeStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BorderStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::TextStyle';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

# Text settings
my $magicConstant    = 0.00328;                # InCAM need text width converted with this constant , took keep required width in µm
my $TITLE_TEXT_SIZE  = 1500;
my $TITLE_TEXT_WIDTH = 200 * $magicConstant;
my $CPN_TEXT_SIZE    = 1000;
my $CPN_TEXT_WIDTH   = 150 * $magicConstant;
my $TABLE_TEXT_SIZE  = 1000;
my $TABLE_TEXT_WIDTH = 150 * $magicConstant;

# Layer layout
my $TITLE_CPN_GAP = 8000;                      # 15 mm between title CPN gap
my $CPN_TABLE_GAP = 5000;                      # 15 mm between coupon and table

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

sub CreateIPC3Main {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	
	my $m = CouponIPC3Main->new( $inCAM, $jobId );

	my $title = uc( $self->{"jobId"} ) . " - IPC-3 customer coupon drill map";

	return $self->__Create( $m, $title, "" );

}

sub CreateIPC3Drill {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $m = CouponIPC3Drill->new( $inCAM, $jobId );

	my $title = uc( $self->{"jobId"} ) . " - IPC-3 drill coupon drill map";

	return $self->__Create( $m, $title, "" );

}

sub __Create {
	my $self      = shift;
	my $couponObj = shift;    # inspected layers
	my $titleText = shift;    # titles
	my $noteText  = shift;    # note under drill table

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Test if coupon step exist
	die "Coupon step: " . $couponObj->GetStep() . " doesn't exists"
	  unless ( CamHelper->StepExists( $inCAM, $jobId, $couponObj->GetStep() ) );

	CamHelper->SetStep( $inCAM, $couponObj->GetStep() );

	# 1) Prepare drill map layer
	my $drillMapL = $self->__PrepareDrillMapLayer($couponObj);

	# 2) Prepare title
	my %lim = CamJob->GetLayerLimits2( $inCAM, $jobId, $couponObj->GetStep(), "c" );

	CamSymbol->AddText( $inCAM, $titleText,
						{ "x" => 0, "y" => $lim{"yMax"} + $TITLE_CPN_GAP / 1000 },
						$TITLE_TEXT_SIZE / 1000,
						$TITLE_TEXT_SIZE / 1000,
						$TITLE_TEXT_WIDTH );

	# 3) Prepare coupon background

	# choose background layer
	my $backgroundL = undef;

	if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) ) {
		$backgroundL = "c";
	}

	$self->__PdfOutput( $drillMapL, $backgroundL );

	return 1;
}

# Return all stacku paths
sub GetPdfPath {
	my $self = shift;

	return $self->{"outputPath"};
}

sub __PdfOutput {
	my $self       = shift;
	my $drillMap   = shift;
	my $background = shift;

	my $inCAM = $self->{"inCAM"};

	my $layerStr = $drillMap;

	if ($background) {
		$layerStr = $background . "\\;" . $layerStr;
	}

	my $pdfFile = $self->{"outputPath"};
	$pdfFile =~ s/\\/\//g;

	$inCAM->COM(
				 'print',
				 layer_name        => $layerStr,
				 mirrored_layers   => '',
				 draw_profile      => 'no',
				 drawing_per_layer => 'no',
				 label_layers      => 'no',
				 dest              => 'pdf_file',
				 num_copies        => '1',
				 dest_fname        => $pdfFile,
				 paper_size        => 'A4',
				 orient            => 'portrait',
				 auto_tray         => 'no',
				 top_margin        => '10',
				 bottom_margin     => '10',
				 left_margin       => '10',
				 right_margin      => '10',
				 "x_spacing"       => '0',
				 "y_spacing"       => '0',
				 "color1"          => '005099',
				 "color2"          => '000000'
	);

	$inCAM->COM( 'delete_layer', "layer" => $drillMap );

	return $pdfFile;
}

sub __PrepareDrillMapLayer {
	my $self         = shift;
	my $couponObj    = shift;
	my $colDrillSize = shift // 1;
	my $colFinSize   = shift // 1;
	my $colDepth     = shift // 1;
	my $colTol       = shift // 0;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lName = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $lName, "document", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $lName );

	# 2) Draw points

	my $drawHoles = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );

	my @holeGroups = $couponObj->GetHoles();
	my $curSymNum  = 1;

	foreach my $holeGroupInf (@holeGroups) {

		foreach my $toolInf ( @{ $holeGroupInf->{"tools"} } ) {

			my @pos = $couponObj->GetHoleCouponPos( $holeGroupInf->{"layer"}->{"gROWname"}, $toolInf->{"drillSize"} );

			foreach my $p (@pos) {

				my $padTxt = PrimitiveText->new( $curSymNum,
												 Point->new( $p->X() + 0.3, $p->Y() + 0.4 ),
												 $CPN_TEXT_SIZE / 1000,
												 $CPN_TEXT_SIZE / 1000,
												 ($CPN_TEXT_WIDTH), 0, 0, DrawEnums->Polar_POSITIVE );

				$drawHoles->AddPrimitive($padTxt);

				my $pad = PrimitivePad->new( "cross1000x1000x200x200x50x50xr", Point->new( $p->X(), $p->Y() ), 0, DrawEnums->Polar_POSITIVE );

				$drawHoles->AddPrimitive($pad);
			}

			$curSymNum++;

		}

	}

	# Add profile
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $couponObj->GetStep() );

	my @contourP = ();
	push( @contourP, Point->new( $lim{"xMin"}, $lim{"yMin"} ) );
	push( @contourP, Point->new( $lim{"xMax"}, $lim{"yMin"} ) );
	push( @contourP, Point->new( $lim{"xMax"}, $lim{"yMax"} ) );
	push( @contourP, Point->new( $lim{"xMin"}, $lim{"yMax"} ) );
	push( @contourP, Point->new( $lim{"xMin"}, $lim{"yMin"} ) );

	my $contour = PrimitivePolyline->new( \@contourP, "r150", DrawEnums->Polar_POSITIVE );
	$drawHoles->AddPrimitive($contour);

	$drawHoles->Draw();

	# 3) Draw tool table

	my $tDrawing = TableDrawing->new( TblDrawEnums->Units_MM );

	# Define styles

	my $headTextStyle =
	  TextStyle->new( TblDrawEnums->TextStyle_LINE,
					  $TABLE_TEXT_SIZE / 1000,
					  undef, TblDrawEnums->Font_BOLD, TblDrawEnums->FontFamily_STANDARD,
					  undef, TblDrawEnums->TextVAlign_CENTER, 1 );

	my $stdTextStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
									   $TABLE_TEXT_SIZE / 1000,
									   undef, TblDrawEnums->Font_NORMAL, TblDrawEnums->FontFamily_STANDARD,
									   undef, TblDrawEnums->TextVAlign_CENTER, 1 );

	my $thinBorderStyle = BorderStyle->new();

	$thinBorderStyle->AddEdgeStyle( "top",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1 );
	$thinBorderStyle->AddEdgeStyle( "bot",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1 );
	$thinBorderStyle->AddEdgeStyle( "left",  TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1 );
	$thinBorderStyle->AddEdgeStyle( "right", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1 );

	my $thickBorderStyle = BorderStyle->new();
	$thickBorderStyle->AddEdgeStyle( "top",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2 );
	$thickBorderStyle->AddEdgeStyle( "bot",   TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2 );
	$thickBorderStyle->AddEdgeStyle( "left",  TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2 );
	$thickBorderStyle->AddEdgeStyle( "right", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.2 );

	my $tMain = $tDrawing->AddTable( "Main", { "x" => 0, "y" => 0 }, $thickBorderStyle );

	# Add columns

	$tMain->AddColDef( "col_id",        8,  undef, $thinBorderStyle );
	$tMain->AddColDef( "col_layer",     10, undef, $thinBorderStyle );
	$tMain->AddColDef( "col_drillSize", 15, undef, $thinBorderStyle ) if ($colDrillSize);
	$tMain->AddColDef( "col_finSize",   15, undef, $thinBorderStyle ) if ($colFinSize);
	$tMain->AddColDef( "col_depth",     10, undef, $thinBorderStyle ) if ($colDepth);
	$tMain->AddColDef( "col_tol",       15, undef, $thinBorderStyle ) if ($colTol);

	# Add rows

	$tMain->AddRowDef( "row_1", 5, undef, $thickBorderStyle );    # Header row
	                                                              # Add cell

	#	my $testBackStyle1 = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 10,  10,  10 ) );
	#	my $testBackStyle2 = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 90,  90,  90 ) );
	#	my $testBackStyle3 = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 140, 140, 140 ) );
	#	my $testBackStyle4 = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 190, 190, 190 ) );
	#	my $testBackStyle5 = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 240, 240, 240 ) );

	# Add table header cells

	$tMain->AddCell( $tMain->GetCollByKey("col_id")->GetId(),        0, undef, undef, "Id",          $headTextStyle, undef );
	$tMain->AddCell( $tMain->GetCollByKey("col_layer")->GetId(),     0, undef, undef, "Layer",       $headTextStyle, undef );
	$tMain->AddCell( $tMain->GetCollByKey("col_drillSize")->GetId(), 0, undef, undef, "Drill size",  $headTextStyle, undef ) if ($colDrillSize);
	$tMain->AddCell( $tMain->GetCollByKey("col_finSize")->GetId(),   0, undef, undef, "Finish size", $headTextStyle, undef ) if ($colFinSize);
	$tMain->AddCell( $tMain->GetCollByKey("col_depth")->GetId(),     0, undef, undef, "Depth",       $headTextStyle, undef ) if ($colDepth);
	$tMain->AddCell( $tMain->GetCollByKey("col_tol")->GetId(),       0, undef, undef, "Tol+",        $headTextStyle, undef ) if ($colTol);

	# Add table body cells
	my $curSymNum2 = 1;
	foreach my $holeGroupInf (@holeGroups) {

		my $unitDTM = UniDTM->new( $inCAM, $jobId, "panel", $holeGroupInf->{"layer"}->{"gROWname"}, 1, 0, 0 );
		my @uniTools = $unitDTM->GetTools();

		foreach my $toolInf ( @{ $holeGroupInf->{"tools"} } ) {

			$tMain->AddRowDef( $tMain->GetRowCnt(), 3, undef, $thinBorderStyle );

			my $l = $holeGroupInf->{"layer"};

			# Tool Id
			$tMain->AddCell( $tMain->GetCollByKey("col_id")->GetId(), $tMain->GetRowCnt() - 1, undef, undef, "T" . $curSymNum2, $stdTextStyle,
							 undef );

			# Tool layer
			my $lText = "L" . $l->{"NCSigStartOrder"} . "-" . "L" . $l->{"NCSigEndOrder"};
			$tMain->AddCell( $tMain->GetCollByKey("col_layer")->GetId(), $tMain->GetRowCnt() - 1, undef, undef, $lText, $stdTextStyle, undef );

			# Tool size
			my $tDrillSize = sprintf( "%.3f", $toolInf->{"drillSize"} / 1000 );
			$tMain->AddCell( $tMain->GetCollByKey("col_drillSize")->GetId(),
							 $tMain->GetRowCnt() - 1,
							 undef, undef, $tDrillSize, $stdTextStyle, undef )
			  if ($colDrillSize);

			my $uniTool = first { $_->GetDrillSize() == $toolInf->{"drillSize"} } @uniTools;
			if ( defined $uniTool ) {

				# some tools can by fake and not physically on PCB
				# Thus we cant find them in panel

				# Tool size
				my $tFinSize = sprintf( "%.3f", $uniTool->GetFinishSize() / 1000 );
				$tMain->AddCell( $tMain->GetCollByKey("col_finSize")->GetId(),
								 $tMain->GetRowCnt() - 1,
								 undef, undef, $tFinSize, $stdTextStyle, undef )
				  if ($colFinSize);

				# Tool depth
				if ( $colDepth && $uniTool->GetDepth() ) {
					my $tDepth = sprintf( "%.3f", $uniTool->GetDepth() );
					$tMain->AddCell( $tMain->GetCollByKey("col_depth")->GetId(),
									 $tMain->GetRowCnt() - 1,
									 undef, undef, $tDepth, $stdTextStyle, undef );
				}

				$tMain->AddCell( $tMain->GetCollByKey("col_tol")->GetId(), $tMain->GetRowCnt() - 1, undef, undef, "NAN", $stdTextStyle, undef )
				  if ($colTol);

			}

			$curSymNum2++;
		}
	}

	# Init Draw Builder
	my @media = ( 500, 500 );
	my $margin = 0;

	my $drawBuilder = InCAMDrawing->new( $inCAM, $jobId, $couponObj->GetStep(), $lName, TblDrawEnums->Units_MM, \@media, $margin );

	#my  = $tDrawing->FitToCanvas( $w, $h );

	my %tblLim = $tDrawing->GetOriLimits();

	my $oriX = 0;
	my $oriY = $tblLim{"yMax"} - $tblLim{"yMin"};

	my $tblCpnGap = 10;    # 15mm gap between table and coupon

	$tDrawing->Draw( $drawBuilder, 1, 1, 0, -( $oriY + $CPN_TABLE_GAP / 1000 ) );

	# Add notes

	$tMain->AddRowDef( $tMain->GetRowCnt(), 4, undef, undef );
	$tMain->AddCell( $tMain->GetCollByKey("col_id")->GetId(),
					 $tMain->GetRowCnt() - 1,
					 $tMain->GetColCnt(), undef, "* All values in [mm]",
					 $stdTextStyle, undef );
	my %lLim = CamJob->GetLayerLimits2( $inCAM, $jobId, $couponObj->GetStep(), $lName );

	CamSymbol->AddText( $inCAM,
						"* All values are in [mm]",
						{ "x" => 0, "y" => $lLim{"yMin"} - 2 * $TABLE_TEXT_SIZE / 1000 },
						$TABLE_TEXT_SIZE / 1000,
						$TABLE_TEXT_SIZE / 1000,
						$TABLE_TEXT_WIDTH / 1000 );

	return $lName;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::DrawingPdf::DrillMapDrillCpnPdf::DrillMapCouponPdf';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d277171";
	my $map = DrillMapCouponPdf->new( $inCAM, $jobId );
	$map->CreateIPC3Drill();

}

1;

