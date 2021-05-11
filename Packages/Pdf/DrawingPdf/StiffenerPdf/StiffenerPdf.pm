
#-------------------------------------------------------------------------------------------#
# Description: Creation Stiffener thicnkess drawing for final PCB check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::DrawingPdf::StiffenerPdf::StiffenerPdf;

#3th party library
use strict;
use warnings;
use English;
use List::Util qw[first];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHistogram';

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
my $TITLE_TEXT_SIZE  = 5000;
my $TITLE_TEXT_WIDTH = 600 * $magicConstant;
my $TABLE_TEXT_SIZE  = 3000;
my $TABLE_TEXT_WIDTH = 300 * $magicConstant;

# Layer layout
my $TITLE_PCB_GAP = 20000;                     # 15 mm between title PCB gap
my $PCB_TABLE_GAP = 15000;                     # 15 mm between PCB and table

# Table  styles

my $headTextStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
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

# Other const
use constant STIFF_TOL => 5;    # Stiffener tolerance +-5%

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

# Create PDF drawing
sub CreateStiffPdf {
	my $self = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @stiffL = CamDrilling->GetNCLayersByTypes(
												  $inCAM, $jobId,
												  [
													 EnumsGeneral->LAYERTYPE_nplt_bstiffcMill, EnumsGeneral->LAYERTYPE_nplt_bstiffsMill,
													 EnumsGeneral->LAYERTYPE_nplt_stiffcMill,  EnumsGeneral->LAYERTYPE_nplt_stiffsMill
												  ]
	);

	# Test if stiffener exist
	die "No stiffener layer exist" unless ( scalar(@stiffL) );

	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@stiffL );

	# Choose background layer (display in gray as background for important information)
	my $backgroundL = "c";

	my @colors = ( "green", "red", "blue", "orange", "purple" );    # each stiffener thicknes has specific color on PDF

	my $step = "o+1";
	if ( CamHelper->StepExists( $inCAM, $jobId, 'panel' ) ) {
		my @steps = CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

		# take mpanel or o+1
		$step = $steps[0]->{"stepName"};
	}

	# Get all stiffener depths and its ref layers
	my @thickness = ();
	my @editSteps = CamStep->GetJobEditSteps( $inCAM, $jobId );

	foreach my $stiffL (@stiffL) {

		foreach my $s (@editSteps) {

			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $s, $stiffL->{"gROWname"}, 0 );
			next if ( $hist{"total"} == 0 );

			my %att = CamAttributes->GetLayerAttr( $inCAM, $jobId, $s, $stiffL->{"gROWname"} );

			my $pcbThick = $att{"final_pcb_thickness"};

			if ( defined $pcbThick && $pcbThick ne "" && $pcbThick > 0 ) {

				push(
					@thickness,
					{
					  "thick"   => $pcbThick,
					  "sourceL" => $stiffL,          # source layer, which define shape of stiffener
					  "outputL" => $stiffL,          # outputl layer, which display how stiffener looks like in real
					  "step"    => $s,
					  "color"   => shift(@colors)    # each stiffener thicknes has specific color on PDF
					}
				);
			}

		}
	}

	# Sort thickness from  thickest to thinnest
	@thickness = sort { $b->{"thick"} <=> $a->{"thick"} } @thickness;

	# Create inCAM step (flatten if main step contain S$R )
	my $pdfStep = $step . "_stiff_pdf";

	# Get all layers which will be usefull
	my @l2Flat = ( map { $_->{"gROWname"} } @stiffL );
	push( @l2Flat, $backgroundL );
	my @npltF = map { $_->{"gROWname"} }
	  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nDrill, EnumsGeneral->LAYERTYPE_nplt_nMill ] );
	push( @l2Flat, @npltF ) if ( scalar(@npltF) );

	CamStep->CreateFlattenStep( $inCAM, $jobId, $step, $pdfStep, 0, \@l2Flat );
	CamHelper->SetStep( $inCAM, $pdfStep );

	my $lBase = GeneralHelper->GetGUID();    # layer for drawing
	CamMatrix->CreateLayer( $inCAM, $jobId, $lBase, "document", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $lBase );
	CamStep->ProfileToLayer( $inCAM, $pdfStep, $lBase, "500" );

	# 1) Prepare stiffener output layer
	$self->__PrepareStiffLayer( $pdfStep, $lBase, \@thickness, $backgroundL );

	# 2) Prepare stiffener thickness table
	$self->__PrepareTable( $pdfStep, $lBase, \@thickness );

	# Add Title
	my $title = uc( $self->{"jobId"} ) . ": PCB + Stiffener thickness";
	my %lim = CamJob->GetLayerLimits2( $inCAM, $jobId, $pdfStep, $lBase );

	CamSymbol->AddText( $inCAM, $title,
						{ "x" => 0, "y" => $lim{"yMax"} + $TITLE_PCB_GAP / 1000 },
						$TITLE_TEXT_SIZE / 1000,
						$TITLE_TEXT_SIZE / 1000,
						$TITLE_TEXT_WIDTH );

	CamLayer->WorkLayer( $inCAM, $backgroundL );
	CamLayer->Contourize( $inCAM, $backgroundL, "x_or_y", 0 );

	# Output PDF
	$result = $self->__PdfOutput( $lBase, $backgroundL, \@thickness );

	# Do clean up
	foreach my $thickInf (@thickness) {
		CamMatrix->DeleteLayer( $inCAM, $jobId, $thickInf->{"outputL"} );
	}

	CamMatrix->DeleteLayer( $inCAM, $jobId, $lBase );

	CamStep->DeleteStep( $inCAM, $jobId, $pdfStep );

	return $result;
}

# Return PDF path
sub GetPdfPath {
	my $self = shift;

	return $self->{"outputPath"};
}

sub __PrepareStiffLayer {
	my $self        = shift;
	my $pdfStep     = shift;
	my $drawLayer   = shift;
	my @thickInfos  = @{ shift(@_) };    # sorted by stiffener thickness from thickest
	my $backgroundL = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $pdfStep );

	# Create ouptu layer for each stiff layer
	foreach my $thickInf (@thickInfos) {

		if (    $thickInf->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill
			 || $thickInf->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill )
		{

			# 1) Create full surface by profile
			my $lOut = CamLayer->FilledProfileLim( $inCAM, $jobId, $pdfStep, 1000, \%lim );
			CamLayer->ClipAreaByProf( $inCAM, $lOut, 0, 0, 1 );
			CamLayer->WorkLayer( $inCAM, $lOut );

			# 2) Copy negative of stiffener rout
			my $lNegHelp = GeneralHelper->GetGUID();
			CamMatrix->CreateLayer( $inCAM, $jobId, $lNegHelp, "document", "positive", 0 );

			my $lTmp = CamLayer->RoutCompensation( $inCAM, $thickInf->{"sourceL"}->{"gROWname"}, "document" );
			$inCAM->COM(
						 "merge_layers",
						 "source_layer" => $lTmp,
						 "dest_layer"   => $lNegHelp,
						 "invert"       => "yes"
			);
			CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );
			my @stiffRoutLHelper = ();

			# consider adhesive stiffener depth milling
			if ( $thickInf->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill ) {

				my $stiffAdh = ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_stiffcAdhMill ] ) )[0];
				push( @stiffRoutLHelper, $stiffAdh ) if ( defined $stiffAdh );

				my @tapeL = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId,
															 [ EnumsGeneral->LAYERTYPE_nplt_tapecMill, EnumsGeneral->LAYERTYPE_nplt_tapebrMill ] );
				push( @stiffRoutLHelper, @tapeL ) if ( scalar(@tapeL) );
			}

			if ( $thickInf->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill ) {

				my $stiffAdh = ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_stiffsAdhMill ] ) )[0];
				push( @stiffRoutLHelper, $stiffAdh ) if ( defined $stiffAdh );

				my @tapeL = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId,
															 [ EnumsGeneral->LAYERTYPE_nplt_tapesMill, EnumsGeneral->LAYERTYPE_nplt_tapebrMill ] );
				push( @stiffRoutLHelper, @tapeL ) if ( scalar(@tapeL) );
			}

			# add also main stiffener layer (wee need to close shape for next contourize)
			push( @stiffRoutLHelper, $thickInf->{"sourceL"} );

			foreach my $stiffRoutL (@stiffRoutLHelper) {
				my $lTmp = CamLayer->RoutCompensation( $inCAM, $stiffRoutL->{"gROWname"}, "document" );
				$inCAM->COM(
							 "merge_layers",
							 "source_layer" => $lTmp,
							 "dest_layer"   => $lNegHelp,
							 "invert"       => "yes"
				);
				CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );
			}

			CamLayer->Contourize( $inCAM, $lNegHelp, "x_or_y", "203200" );  # 203200 = max size of emptz space in InCAM which can be filled by surface
			$inCAM->COM(
						 "merge_layers",
						 "source_layer" => $lNegHelp,
						 "dest_layer"   => $lOut,
						 "invert"       => "no"
			);

			#

			CamMatrix->DeleteLayer( $inCAM, $jobId, $lNegHelp );
			$thickInf->{"outputL"} = $lOut;

		}
		elsif (    $thickInf->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill
				|| $thickInf->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffsMill )
		{

			my $lOut = CamLayer->RoutCompensation( $inCAM, $thickInf->{"sourceL"}->{"gROWname"}, "document" );
			CamLayer->Contourize( $inCAM, $lOut, "x_or_y", "203200" );    # 203200 = max size of emptz space in InCAM which can be filled by surface
			$thickInf->{"outputL"} = $lOut;
		}
	}

	# Stiffener layer may overlap eachother.
	# Final shape/thickness is given always by stiffener layer + can be defined by depth milling layer
	# Copy all "thinner stiffener" depth layer to stiffener layer
	for ( my $i = 0 ; $i < scalar(@thickInfos) ; $i++ ) {

		for ( my $j = $i + 1 ; $j < scalar(@thickInfos) ; $j++ ) {

			if (
				 (
				      $thickInfos[$i]->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill
				   && $thickInfos[$j]->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill
				 )
				 || (    $thickInfos[$i]->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill
					  && $thickInfos[$j]->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffsMill )
			  )
			{
				$inCAM->COM(
							 "merge_layers",
							 "source_layer" => $thickInfos[$j]->{"outputL"},
							 "dest_layer"   => $thickInfos[$i]->{"outputL"},
							 "invert"       => "yes"
				);
			}
		}

		CamLayer->Contourize( $inCAM, $thickInfos[$i]->{"outputL"}, "x_or_y", 0 );

		$inCAM->COM(
					 "merge_layers",
					 "source_layer" => $thickInfos[$i]->{"outputL"},
					 "dest_layer"   => $backgroundL,
					 "invert"       => "yes"
		);

		CamLayer->WorkLayer( $inCAM, $thickInfos[$i]->{"outputL"} );

		$inCAM->COM(
			"sel_fill",
			"type"                    => "predefined_pattern",
			"cut_prims"               => "no",
			"outline_draw"            => "yes",
			"outline_width"           => "400",
			"outline_invert"          => "no",
			"predefined_pattern_type" => "lines",
			"indentation"             => "even",
			"lines_angle"             => ( 45 + ( ( $i % 3 ) * 45 ) ),    # Everz stiffener diffrent odd/even
			"lines_witdh"             => "800",
			"lines_dist"              => "1500"
		);

		#CamLayer->Contourize( $inCAM, $thickInfos[$i]->{"outputL"}, "x_or_y", 0 );

	}

	# Finally copy final PCB Rout to all prepared output stiff layers
	# to acheive real stiffener illustration
	my @npltF = map { $_->{"gROWname"} }
	  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nDrill, EnumsGeneral->LAYERTYPE_nplt_nMill ] );

	foreach my $l (@npltF) {

		my $lOut = CamLayer->RoutCompensation( $inCAM, $l, "document" );

		foreach my $thickInf (@thickInfos) {

			$inCAM->COM(
						 "merge_layers",
						 "source_layer" => $lOut,
						 "dest_layer"   => $thickInf->{"outputL"},
						 "invert"       => "yes"
			);

		}
		CamMatrix->DeleteLayer( $inCAM, $jobId, $lOut );
	}

	return 1;
}

sub __PrepareTable {
	my $self       = shift;
	my $pdfStep    = shift;
	my $drawLayer  = shift;
	my @thickInfos = @{ shift(@_) };    # sorted by stiffener thickness from thickest

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $tDrawing = TableDrawing->new( TblDrawEnums->Units_MM );

	my $tMain = $tDrawing->AddTable( "Main", { "x" => 0, "y" => 0 }, $thickBorderStyle );

	# Add columns

	$tMain->AddColDef( "col_color",     30, undef, $thinBorderStyle );
	$tMain->AddColDef( "col_stiffSide", 25, undef, $thinBorderStyle );
	$tMain->AddColDef( "col_thickness", 60, undef, $thinBorderStyle );

	#	$tMain->AddColDef( "col_tol",       20, undef, $thinBorderStyle );
	$tMain->AddColDef( "col_tolVal", 60, undef, $thinBorderStyle );

	# Add rows

	$tMain->AddRowDef( "row_1", 9, undef, $thickBorderStyle );    # Header row

	# Add table header cells

	$tMain->AddCell( $tMain->GetCollByKey("col_color")->GetId(),     0, undef, undef, "Color",                          $headTextStyle, undef );
	$tMain->AddCell( $tMain->GetCollByKey("col_stiffSide")->GetId(), 0, undef, undef, "Side",                           $headTextStyle, undef );
	$tMain->AddCell( $tMain->GetCollByKey("col_thickness")->GetId(), 0, undef, undef, "Total thickness",                $headTextStyle, undef );
	$tMain->AddCell( $tMain->GetCollByKey("col_tolVal")->GetId(),    0, undef, undef, "Tolerance +-" . STIFF_TOL . "%", $headTextStyle, undef );

	# Add table body cells

	foreach my $thickInf (@thickInfos) {

		$tMain->AddRowDef( "row_" . ( $tMain->GetRowCnt() + 1 ), 6, undef, $thickBorderStyle );    # Header row

		# Add color cell
		$tMain->AddCell( $tMain->GetCollByKey("col_color")->GetId(),
						 $tMain->GetRowCnt() - 1,
						 undef, undef, $thickInf->{"color"}, $stdTextStyle, undef );

		# Add color cell
		my $side = "top";

		if (    $thickInf->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill
			 || $thickInf->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill )
		{
			$side = CamMatrix->GetNonSignalLayerSide( $inCAM, $jobId, $thickInf->{"sourceL"}->{"gROWname"} );

		}
		elsif (    $thickInf->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill
				|| $thickInf->{"sourceL"}->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffsMill )
		{
			$side = $thickInf->{"sourceL"}->{"gROWdrl_dir"} eq "bot2top" ? "bot" : "top";
		}

		$tMain->AddCell( $tMain->GetCollByKey("col_stiffSide")->GetId(), $tMain->GetRowCnt() - 1, undef, undef, $side, $stdTextStyle, undef );

		# Add color cell
		my $thick = $thickInf->{"thick"} / 1000;

		$tMain->AddCell( $tMain->GetCollByKey("col_thickness")->GetId(),
						 $tMain->GetRowCnt() - 1,
						 undef, undef, sprintf( "%.2f", $thick ) . "mm",
						 $stdTextStyle, undef );

		# Add color cell
		$tMain->AddCell( $tMain->GetCollByKey("col_tolVal")->GetId(),
						 $tMain->GetRowCnt() - 1,
						 undef, undef,
						 sprintf( "%.2f", $thick * 1 - ( STIFF_TOL / 100 ) ) . " - " . sprintf( "%.2f", $thick * 1 + ( STIFF_TOL / 100 ) ) . "mm",
						 $stdTextStyle, undef );

	}

	# Init Draw Builder
	my @media = ( 500, 500 );
	my $margin = 0;

	my $drawBuilder = InCAMDrawing->new( $inCAM, $jobId, $pdfStep, $drawLayer, TblDrawEnums->Units_MM, \@media, $margin );

	#my  = $tDrawing->FitToCanvas( $w, $h );

	my %tblLim = $tDrawing->GetOriLimits();

	my $oriX = 0;
	my $oriY = $tblLim{"yMax"} - $tblLim{"yMin"};

	my $tblCpnGap = 10;    # 15mm gap between table and coupon

	$tDrawing->Draw( $drawBuilder, 1, 1, 0, -( $oriY + $PCB_TABLE_GAP / 1000 ) );
}

sub __PdfOutput {
	my $self        = shift;
	my $drawLayer   = shift;
	my $backgroundL = shift;
	my @thickInfos  = @{ shift(@_) };    # sorted by stiffener thickness from thickest

	my $restul = 1;

	my $inCAM = $self->{"inCAM"};

	my @l2Print = ();

	push( @l2Print, $backgroundL );
	push( @l2Print, $drawLayer );
	push( @l2Print, map { $_->{"outputL"} } @thickInfos );

	my $layerStr = join( ";", @l2Print );

	my $pdfFile = $self->{"outputPath"};
	$pdfFile =~ s/\\/\//g;

	my $clrStiff = {};

	my $clrNum = 3;
	foreach my $thickInf (@thickInfos) {

		$clrStiff->{"color${clrNum}"} = $self->__TxtColor2PdfColor( $thickInf->{"color"} );
		$clrNum++;
	}

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
		"color1"          => '808080',     # background
		"color2"          => '000000',     # base layer table, profiles,..
		%{$clrStiff}

	);

	return $restul;
}

sub __TxtColor2PdfColor {
	my $self  = shift;
	my $color = shift;

	my %code = (
				 "red"    => "800000",
				 "green"  => "008000",
				 "blue"   => "000080",
				 "orange" => "946602",
				 "purple" => "180333"
	);

	return $code{$color};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::DrawingPdf::StiffenerPdf::StiffenerPdf';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d320240";
	my $map = StiffenerPdf->new( $inCAM, $jobId );
	$map->CreateStiffPdf();

}

1;

