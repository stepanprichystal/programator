
#-------------------------------------------------------------------------------------------#
# Description: Modul is responsible for creation pdf pressfit
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::DrawingPdf::DrillMapDrillCpnPdf::DrillMapCouponPdf;

#3th party library
use strict;
use warnings;
use English;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Microsection::CouponIPC3Main';
use aliased 'Packages::CAMJob::Microsection::CouponIPC3Drill';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::Point';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

my $magicConstant   = 0.00328;                # InCAM need text width converted with this constant , took keep required width in µm
my $TEXT_SIZE       = 1200;
my $TITLE_TEXT_SIZE = 2000;
my $TOOL_TEXT_SIZE  = 1000;
my $TOOL_TEXT_WIDTH = 150 * $magicConstant;
my $SCALE_CPN       = 0;

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

	my $title = uc( $self->{"jobId"} ) . " - Microsection of IPC class 3 customer coupon [mm]";

	$self->__Create( $m, $title, "" );

}

sub __Create {
	my $self      = shift;
	my $couponObj = shift;    # inspected layers
	my $titleText = shift;    # titles
	my $noteText  = shift;    # note under drill table

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamHelper->SetStep( $inCAM, $couponObj->GetStep() );

	# 1) Prepare drill map layer
	my $drillMapL = $self->__PrepareDrillMapLayer($couponObj);

	# 2) Output pdf

	# choose background layer
	my $backgroundL = undef;

	if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) ) {
		$backgroundL = "c";
	}

	$self->__ImgPreviewOut( $drillMapL, $backgroundL );

	return 1;
}

# Return all stacku paths
sub GetPdfPaths {
	my $self = shift;

	return @{ $self->{"outputPaths"} };
}

sub __ImgPreviewOut {
	my $self       = shift;
	my $drillMap   = shift;
	my $background = shift;

	my $inCAM = $self->{"inCAM"};

	my $layerStr = $drillMap->{"layer"};

	if ($background) {
		$layerStr = $background . "\\;" . $layerStr;
	}

	my $pdfFile = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";
	$pdfFile =~ s/\\/\//g;

	CamHelper->SetStep( $inCAM, $drillMap->{"step"} );

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
				 orient            => 'none',
				 auto_tray         => 'no',
				 top_margin        => '0',
				 bottom_margin     => '0',
				 left_margin       => '0',
				 right_margin      => '0',
				 "x_spacing"       => '0',
				 "y_spacing"       => '0',
				 "color1"          => '909090',
				 "color2"          => '990000'
	);

	$inCAM->COM( 'delete_layer', "layer" => $drillMap->{"layer"} );

	return $pdfFile;
}

sub __PrepareDrillMapLayer {
	my $self         = shift;
	my $couponObj    = shift;
	my $colDrillSize = shift // 1;
	my $colDepth     = shift // 1;
	my $colTol       = shift // 0

	  my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lName = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $lName, "document", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $lName );

	# 1) Draw points

	my $drawHoles = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );

	my @holeGroups = $couponObj->GetHoles();
	my $curSymNum  = 1;

	foreach my $holeGroupInf (@holeGroups) {

		foreach my $toolInf ( @{ $holeGroupInf->{"tools"} } ) {

			my @pos = $couponObj->GetHoleCouponPos( $holeGroupInf->{"layer"}->{"gROWname"}, $toolInf->{"drillSize"} );

			foreach my $p (@pos) {

				my $padTxt = PrimitiveText->new( $curSymNum,
												 Point->new( $p->X(), $p->Y() ),
												 $TOOL_TEXT_SIZE / 1000,
												 $TOOL_TEXT_SIZE / 1000,
												 ($TOOL_TEXT_WIDTH), 0, 0, DrawEnums->Polar_POSITIVE );

				$drawHoles->AddPrimitive($padTxt);

				my $pad = PrimitivePad->new( "cross1000x1000x200x200x50x50xr", Point->new( $p->X(), $p->Y() ), 0, DrawEnums->Polar_POSITIVE );

				$drawHoles->AddPrimitive($pad);
			}
		}

		$curSymNum++;

	}

	$drawHoles->Draw();

	# 2) Draw tool table
	
	

	return $lName;

}

sub __PrepareDrillMaps {
	my $self      = shift;
	my $step      = shift;
	my $layer     = shift;
	my @tools     = @{ shift(@_) };
	my $titleText = shift;            # titles
	my $noteText  = shift;            # note under drill table

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lPressfit = GeneralHelper->GetGUID();
	my $lDrillMap = GeneralHelper->GetGUID();

	#$inCAM->COM( "merge_layers", "source_layer" => $layer, "dest_layer" => $lPressfit );

	$inCAM->COM(
		"copy_layer",
		"source_job"   => $jobId,
		"source_step"  => $step,
		"source_layer" => $layer,
		"dest"         => "layer_name",
		"dest_step"    => $step,
		"dest_layer"   => $lPressfit,
		"mode"         => "append",

		"copy_lpd"     => "new_layers_only",
		"copy_sr_feat" => "no"
	);

	CamLayer->SetLayerTypeLayer( $inCAM, $jobId, $lPressfit, "drill" );
	CamLayer->WorkLayer( $inCAM, $lPressfit );

	# 1) keep only pressfit hole in layer

	my @dcodes = map { $_->{"gTOOLnum"} } @tools;
	my $result = CamFilter->ByDCodes( $inCAM, \@dcodes );

	#my $result = CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".plated_type", "press_fit" );

	$inCAM->COM("sel_reverse");
	$inCAM->COM("get_select_count");

	if ( $self->{"inCAM"}->GetReply() > 0 ) {

		$inCAM->COM("sel_delete");
	}

	# 2) create drill map
	$inCAM->COM(
				 "cre_drills_map",
				 "layer"           => $lPressfit,
				 "map_layer"       => $lDrillMap,
				 "preserve_attr"   => "no",
				 "draw_origin"     => "no",
				 "define_via_type" => "no",
				 "units"           => "mm",
				 "mark_dim"        => "2000",
				 "mark_line_width" => "400",
				 "mark_location"   => "center",
				 "sr"              => "no",
				 "slots"           => "no",
				 "columns"         => "Count\;Type\;+Tol\;-Tol\;Finish",
				 "notype"          => "abort",
				 "table_pos"       => "right",
				 "table_align"     => "bottom"
	);

	$inCAM->COM( 'delete_layer', "layer" => $lPressfit );

	# 3) Add text job id to layer

	CamLayer->WorkLayer( $inCAM, $lDrillMap );

	my %profileLim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $step, 1 );

	my %positionTit = ( "x" => $profileLim{"xMin"}, "y" => $profileLim{"yMax"} + 10 );

	CamSymbol->AddText( $inCAM, $titleText, \%positionTit, 5, undef, 2 );

	my %positionInf = ( "x" => $profileLim{"xMax"} + 2, "y" => $profileLim{"yMin"} - 5 );

	#CamSymbol->AddText( $inCAM, "For pressfit measurements use the column 'Finish'", \%positionInf, 2, undef, 0.5 );

	CamSymbol->AddText( $inCAM, $noteText, \%positionInf, 2, undef, 0.5 );

	$inCAM->COM( "profile_to_rout", "layer" => $lDrillMap, "width" => "200" );

	return $lDrillMap;

}

# check if tool has finis size and tolerance
sub __CheckTools {
	my $self  = shift;
	my @tools = @{ shift(@_) };

	foreach my $t (@tools) {

		# test on finish size
		if (    !defined $t->{"gTOOLfinish_size"}
			 || $t->{"gTOOLfinish_size"} == 0
			 || $t->{"gTOOLfinish_size"} eq ""
			 || $t->{"gTOOLfinish_size"} eq "?" )
		{

			die "Pressfit tool: " . $t->{"gTOOLdrill_size"} . "µm has no finish size.\n";
		}

		if ( $t->{"gTOOLmin_tol"} == 0 && $t->{"gTOOLmax_tol"} == 0 ) {

			die "Measured tool: " . $t->{"gTOOLdrill_size"} . "µm has not defined tolerance.\n";
		}
	}
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
	$map->CreateIPC3Main();

}

1;

