
#-------------------------------------------------------------------------------------------#
# Description: Export pdf with special NC operation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PdfExport::PdfSpecNCMngr;
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
use aliased 'Packages::CAMJob::OutputData::Drawing::Drawing';
use aliased 'Packages::CAM::SymbolDrawing::Point';

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

	$self->{"stepFlat"} = $step . "_ncpdf";
	$self->{"step"}     = $step;
	$self->{"pcbThick"} = JobHelper->GetFinalPcbThick( $self->{"jobId"} ) / 1000;    # in mm

	return $self;
}

sub Run {
	my $self = shift;

	my $jobId = $self->{"jobId"};
	my $inCAM = $self->{"inCAM"};

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

	CamStep->CreateFlattenStep( $inCAM, $jobId, $self->{"step"}, $self->{"stepFlat"}, 1, [ map { $_->{"gROWname"} } @layers ] );

	CamHelper->SetStep( $inCAM, $self->{"stepFlat"} );

	my $control = OutputParserCountersink->new( $inCAM, $jobId, $self->{"stepFlat"} );

	foreach my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, \@counterSinkTypes ) ) {
		
		my $side = $l->{"gROWname"} =~ /c/ ? "top" : "bot";

		my $result = $control->Prepare($l);

		foreach my $classRes ( $result->GetClassResults(1) ) {

			$self->__ProcessLayerData( $classRes, $l );
			$self->__ProcessDrawing( $classRes, $l, $side );

		}

	}

}

sub __ProcessLayerData {
	my $self     = shift;
	my $classRes = shift;
	my $l        = shift;

	my $step = $self->{"stepFlat"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $layerRes ( $classRes->GetLayers() ) {

		# ----------------------------------------------------------------
		# 1) adjust copied feature data. Create outlilne from each feature
		# ----------------------------------------------------------------

		# Parsed data from "parser class result"
		my $drawLayer = $layerRes->GetLayerName();
		CamLayer->WorkLayer( $inCAM, $drawLayer );
		CamLayer->DeleteFeatures($inCAM);

		my @positions = @{ $layerRes->{"positions"} };

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
		my $lTmp = GeneralHelper->GetGUID();
		$inCAM->COM( 'create_layer', layer => $lTmp );

		my $draw = Drawing->new( $inCAM, $jobId, $lTmp, Point->new( 0, 0 ), $self->{"pcbThick"}, $side, $l->{"plated"} );

		# Compute depth of "imagine drill tool"
		# If countersink is done by surface, edge of drill tool goes around according "surface border"
		# Image for this case will show "image tool", where center of tool is same as center of surface, thus "image tool"
		# not go around surface bordr but just like normal drill tool, which drill hole
 
		#$toolDepth    = $chains[0]->GetChain()->GetChainTool()->GetUniDTMTool()->GetDepth();    # angle of tool
		my $imgToolAngle = $layerRes->{"DTMTool"}->GetAngle();    # angle of tool

		my $rCounterSink = $layerRes->{"radiusReal"};

		if ( $l->{"plated"} ) {
			$rCounterSink = $layerRes->{"radiusBeforePlt"};
		}

		my $imgToolDepth = cotan( deg2rad( ( $imgToolAngle / 2 ) ) ) * $rCounterSink;
 
		$draw->CreateDetailCountersinkDrilled( $rCounterSink, $layerRes->{"drillTool"} , $imgToolDepth, $imgToolAngle, "hole" );

		# get limits of drawing and place it above layer data
		CamLayer->WorkLayer( $inCAM, $lTmp );
		my %lim = CamJob->GetLayerLimits2( $inCAM, $jobId, $step, $lTmp );

		$inCAM->COM( "sel_move", "dx" => 0, "dy" => $self->{"profileLim"}->{"yMax"} - $lim{"yMin"} + 10 );    # drawing 10 mm above profile data

		CamLayer->WorkLayer( $inCAM, $lTmp );
		CamLayer->CopySelected( $inCAM, [ $layerRes->GetLayerName() ] );
		CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::PdfExport::PdfSpecNCMngr';

	use aliased 'Packages::InCAM::InCAM';
	use aliased 'CamHelpers::CamStep';
	use aliased 'CamHelpers::CamHelper';

	my $inCAM = InCAM->new();

	my $jobId = "d152457";

	my $pdf = PdfSpecNCMngr->new( $inCAM, $jobId );

	$pdf->Run();

	die;

}

1;

