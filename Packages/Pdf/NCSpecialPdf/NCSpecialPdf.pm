
#-------------------------------------------------------------------------------------------#
# Description: Export pdf with special NC operation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::NCSpecialPdf::NCSpecialPdf;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use Math::Trig;
use Math::Geometry::Planar;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputParser::OutputParserCountersink::OutputParserCountersink';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::Pdf::NCSpecialPDF::Drawing';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::Export::NCExport::ExportMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	my $step = "o+1";

	if ( CamHelper->StepExists( $self->{"inCAM"}, $self->{"jobId"}, "mpanel" ) ) {

		$step = "mpanel";
	}

	$self->{"step"}     = $step;
	$self->{"stepFlat"} = $step . "_ncpdf";
	$self->{"pcbThick"} = CamJob->GetFinalPcbThick($self->{"inCAM"}, $self->{"jobId"} ) / 1000;    # in mm
	
	$self->{"drawingCnt"} = 0; # total drawing count prepared from data

	$self->{"pdfOutput"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

sub Create {
	my $self = shift;
	
	my $result = 0;

	my $jobId = $self->{"jobId"};
	my $inCAM = $self->{"inCAM"};

	my @preparedLayers = ();

	my $export = ExportMngr->new( $self->{"inCAM"}, $self->{"jobId"}, "panel" );
	$self->{"operationMngr"} = $export->GetOperationMngr();

	# 1) flatten step in order parse countersink layers

	my @types = ();
	push( @types, EnumsGeneral->LAYERTYPE_plt_nDrill );
	push( @types, EnumsGeneral->LAYERTYPE_nplt_nDrill );
	push( @types, EnumsGeneral->LAYERTYPE_nplt_nMill );

	my @counterSinkTypes = ();

	push( @counterSinkTypes, EnumsGeneral->LAYERTYPE_plt_bMillTop );
	push( @counterSinkTypes, EnumsGeneral->LAYERTYPE_plt_bMillBot );
	push( @counterSinkTypes, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
	push( @counterSinkTypes, EnumsGeneral->LAYERTYPE_nplt_bMillBot );

	push( @types, @counterSinkTypes );

	my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, \@types );
	
	
	# ''
	CamStep->CreateFlattenStep( $inCAM, $jobId, $self->{"step"}, $self->{"stepFlat"}, 1, [ map { $_->{"gROWname"} } @layers ], "c" );

	CamHelper->SetStep( $inCAM, $self->{"stepFlat"} );

	my $control = OutputParserCountersink->new( $inCAM, $jobId, $self->{"stepFlat"} );

	foreach my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, \@counterSinkTypes ) ) {

		my $operationName = $self->__GetOperationByLayer($l);

		my $side = $l->{"gROWname"} =~ /c/ ? "top" : "bot";

		my $result = $control->Prepare($l, 0); # 0 - do not final layer check after parsing. Layer can contain not only z-axis with angle tool

		foreach my $classRes ( $result->GetClassResults(1) ) {

			# get NC operation

			$self->__ProcessLayerData( $classRes, $l );
			$self->__ProcessDrawing( $classRes, $l, $side );
			$self->__ProcessOther( $classRes, $l, $side, $operationName );

			push( @preparedLayers, map { $_->GetLayerName() } $classRes->GetLayers() );

		}

	}

	if(scalar(@preparedLayers)){
		$result = 1;
		
		$self->__OutputPdf( \@preparedLayers );
	}

	
	$control->Clear();
	
	CamStep->DeleteStep($inCAM, $jobId, $self->{"stepFlat"});
	
	return $result;

}

sub GetOutputPath {
	my $self = shift;

	return $self->{"pdfOutput"};
}

sub __ProcessLayerData {
	my $self     = shift;
	my $classRes = shift;
	my $l        = shift;

	my $step = $self->{"stepFlat"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $layerRes ( $classRes->GetLayers() ) {
		
		$self->{"drawingCnt"}++;

		# ----------------------------------------------------------------
		# 1) adjust copied feature data. Create outlilne from each feature
		# ----------------------------------------------------------------

		# Parsed data from "parser class result"
		my $drawLayer = $layerRes->GetLayerName();
		CamLayer->WorkLayer( $inCAM, $drawLayer );
		CamLayer->DeleteFeatures($inCAM);

		my @positions = @{ $layerRes->GetDataVal("positions") };

		foreach my $pos (@positions) {

			CamSymbol->AddPad( $inCAM, "cross3000x3000x500x500x50x50xr", $pos );
		}

		CamStep->ProfileToLayer( $inCAM, $step, $drawLayer, 200 );

	}
}

# Prepare image
sub __ProcessDrawing {
	my $self     = shift;
	my $classRes = shift;
	my $l        = shift;
	my $side     = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"stepFlat"};

	foreach my $layerRes ( $classRes->GetLayers() ) {

		# ----------------------------------------------------------------
		# 2) Create countersink drawing
		# ----------------------------------------------------------------
		my %lim = CamJob->GetLayerLimits2( $inCAM, $jobId, $step, $layerRes->GetLayerName() );    # limits of pcb outline

		my $lTmp = GeneralHelper->GetGUID();
		$inCAM->COM( 'create_layer', layer => $lTmp );

		# compute scale of drawing
		# width of drawing should be 3x bigger than pcb profile width
		my $drawingWidth = 120;
		my $scale        = 5 * $lim{"xMax"} / $drawingWidth;

		my $draw = Drawing->new( $inCAM, $jobId, $lTmp, Point->new( 0, 0 ), $self->{"pcbThick"}, $side, $l->{"plated"}, 5 );

		# Compute depth of "imagine drill tool"
		# If countersink is done by surface, edge of drill tool goes around according "surface border"
		# Image for this case will show "image tool", where center of tool is same as center of surface, thus "image tool"
		# not go around surface bordr but just like normal drill tool, which drill hole

		#$toolDepth    = $chains[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetDepth();    # angle of tool
		my $imgToolAngle = $layerRes->GetDataVal("DTMTool")->GetAngle();    # angle of tool

		my $rCounterSink = $layerRes->GetDataVal("radiusReal");

		if ( $l->{"plated"} ) {
			$rCounterSink = $layerRes->GetDataVal("radiusBeforePlt");
		}

		my $imgToolDepth = cotan( deg2rad( ( $imgToolAngle / 2 ) ) ) * $rCounterSink;

		$draw->CreateDetailCountersinkDrilled( $rCounterSink, $layerRes->GetDataVal("drillTool"), $imgToolDepth, $layerRes->GetDataVal("exceededDepth"), $imgToolAngle, "hole" );

		#CamLayer->WorkLayer( $inCAM, $lTmp );
		my %limDraw = CamJob->GetLayerLimits2( $inCAM, $jobId, $step, $lTmp);    # limits of pcb outline
		$inCAM->COM( "sel_move", "dx" => $lim{"xMax"} + 10, "dy" => $limDraw{"yMax"} - $limDraw{"yMin"} );    # drawing 10 mm above profile data

		CamLayer->WorkLayer( $inCAM, $lTmp );
		CamLayer->CopySelOtherLayer( $inCAM, [ $layerRes->GetLayerName() ] );
		CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );

	}
}

# Prepare image
sub __ProcessOther {
	my $self          = shift;
	my $classRes      = shift;
	my $l             = shift;
	my $side          = shift;
	my $operationName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"stepFlat"};

	foreach my $layerRes ( $classRes->GetLayers() ) {

		# ----------------------------------------------------------------
		# Create title
		# ----------------------------------------------------------------
		my %lim = CamJob->GetLayerLimits2( $inCAM, $jobId, $step, $layerRes->GetLayerName() );    # limits of pcb outline

		my $yPos = $lim{"yMax"} + 20;
		my %point = ( "x" => 0, "y" => $yPos );

		CamLayer->WorkLayer( $inCAM, $layerRes->GetLayerName() );

		my $txt = uc($jobId)." - vykres ".$self->{"drawingCnt"}.". Operace \"$operationName\" ";
		$txt .= " (zahloubeni z " . uc($side) . " " . ( $l->{"plated"} ? "pred prokovem" : "po prokovu".")" );

		CamSymbol->AddLine( $inCAM, Point->new( 0, $yPos - 3 ), Point->new( length($txt) * 3, $yPos - 3 ), "r300" );
		CamSymbol->AddLine( $inCAM, Point->new( 0, $yPos - 4 ), Point->new( length($txt) * 3, $yPos - 4 ), "r300" );

		if ( $l->{"plated"} ) {
			CamSymbol->AddText( $inCAM, "(Veskere rozmery jsou uvedeny pred prokovem)", Point->new( 0, $yPos - 8 ), 2.5, undef, 0.5 );
		}

		CamSymbol->AddText( $inCAM, $txt, \%point, 3, undef, 0.5 );

	}
}

sub __GetOperationByLayer {
	my $self = shift;
	my $l    = shift;

	my $operation  = undef;
	my @operations = ();

	my @operItems = $self->{"operationMngr"}->GetOperationItems();

	foreach my $item (@operItems) {

		my @layers = $item->GetSortedLayers();

		if ( scalar( grep { $_->{"gROWname"} eq $l->{"gROWname"} } $item->GetSortedLayers() ) ) {

			push( @operations, $item );
		}
	}

	# reduce operations, if exist in some group

	my @groups = grep { $_->{"group"} } $self->{"operationMngr"}->GetInfoTable();

	for ( my $i = scalar(@operations) - 1 ; $i >= 0 ; $i-- ) {

		my $opName = $operations[$i]->{'name'};

		foreach my $g (@groups) {

			if ( $g->{"data"}->[0]->{"name"} =~ /$opName/i && $opName ne $g->{"data"}->[0]->{"groupName"} ) {

				splice @operations, $i, 1;
			}
		}
	}

	return $operations[0]->{"name"};

}

sub __OutputPdf {
	my $self   = shift;
	my $layers = shift;

	my $inCAM = $self->{"inCAM"};

	my $layerStr = join( "\\;", @{$layers} );

	my $pdfFile = $self->{"pdfOutput"};
	$pdfFile =~ s/\\/\//g;

	CamHelper->SetStep( $inCAM, $self->{"stepFlat"} );

	$inCAM->COM(
				 'print',
				 layer_name        => $layerStr,
				 mirrored_layers   => '',
				 draw_profile      => 'no',
				 drawing_per_layer => 'yes',
				 label_layers      => 'no',
				 dest              => 'pdf_file',
				 num_copies        => '1',
				 dest_fname        => $pdfFile,
				 paper_size        => 'A4',
				 orient            => 'none',
				 auto_tray         => 'no',
				 top_margin        => '10',
				 bottom_margin     => '10',
				 left_margin       => '10',
				 right_margin      => '10',
				 "x_spacing"       => '0',
				 "y_spacing"       => '0'
	);

	return $pdfFile;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Pdf::NCSpecialPdf::NCSpecialPdf';

	use aliased 'Packages::InCAM::InCAM';
	use aliased 'CamHelpers::CamStep';
	use aliased 'CamHelpers::CamHelper';

	my $inCAM = InCAM->new();

	my $jobId = "d225131";

	my $pdf = NCSpecialPdf->new( $inCAM, $jobId );

	$pdf->Create();

}

1;

