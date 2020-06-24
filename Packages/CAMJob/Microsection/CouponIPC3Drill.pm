
#-------------------------------------------------------------------------------------------#
# Description: Paclage which generate IPC3 coupon for microsections
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Microsection::CouponIPC3Drill;

#3th party library
use strict;
use warnings;
use JSON;
use List::Util qw[max min first];

#local library
use aliased 'Helpers::JobHelper';
use aliased "Helpers::FileHelper";
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfFill';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePolyline';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSolidPattern';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::CAMJob::Microsection::Helper';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => "FiltrEnums";

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Coupon settings
my $MAX_GROUP_HEIGHT    = 15000;
my $MAX_GROUP_LEN_1LINE = 7000;
my $GROUP_DIST          = 0;
my $GROUP_MARGIN        = 250;
my $CPN_MARGIN          = 250;
my $MIN_CPN_HEIGHT      = 7500;

# Hole settings
my $MIN_HOLE_SPACE = 700;    # 500µm hole ring to hole ring
my $HOLE_RING      = 200;    # 200µm hole anular ring
my $HOLE_UNMASK    = 50;     # 50µm hole mask clearance

# text settings
my $magicConstant = 0.00328;                 # InCAM need text width converted with this constant , took keep required width in µm
my $TEXT_SIZE     = 1200;                    # other text size
my $TEXT_WIDTH    = 200 * $magicConstant;    # other text width

# other parameters
my $TEXT_AREA_WIDTH = 2000;                  # width of left + right stripes, where is logo and layer side
my $GND_ISOLATION   = 700;                   # Isolation of feautures (holes/trakcs/text) of GND

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"step"} = EnumsGeneral->Coupon_DRILL;

	$self->{"holes"}         = [ $self->GetHoles() ];
	$self->{"holesGroupPos"} = [ $self->__GetLayoutHoles() ];

	return $self;
}

sub CreateCoupon {
	my $self = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @uniqueSR = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

	return 0 unless ( scalar(@uniqueSR) );

	# 1) Get holes types and compute holes positions

	# 2) Create coupon step
	my ( $wCpn, $hCpn ) = $self->__GetLayoutDimensions();

	my $step = SRStep->new( $inCAM, $jobId, $self->{"step"} );
	$step->Create( $wCpn, $hCpn, 0, 0, 0, 0 );
	CamHelper->SetStep( $inCAM, $self->{"step"} );

	$self->__DrawCoupon( $wCpn, $hCpn );

	return $result;

}

# Return array of holes where each array item contains:
# - tool = info about tool drill size + depth
# - layer = info about NC layer
sub GetHoles {
	my $self       = shift;
	my $addDefHole = shift;    # add 1mm plt thorugh hole if not exists in PCB

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = CamDrilling->GetNCLayersByTypes(
		$inCAM, $jobId,
		[
		   EnumsGeneral->LAYERTYPE_plt_nDrill,        EnumsGeneral->LAYERTYPE_plt_bDrillTop,
		   EnumsGeneral->LAYERTYPE_plt_bDrillBot,     EnumsGeneral->LAYERTYPE_plt_nFillDrill,
		   EnumsGeneral->LAYERTYPE_plt_bFillDrillTop, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot,
		   EnumsGeneral->LAYERTYPE_plt_cDrill,        EnumsGeneral->LAYERTYPE_plt_cFillDrill
		]
	);

	#my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_plt_bDrillTop ] );
 	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );
	@layers = sort{ abs($b->{"NCSigEndOrder"} - $b->{"NCSigStartOrder"}) <=> abs($a->{"NCSigEndOrder"} - $a->{"NCSigStartOrder"}) } @layers;



	my @uniqueSR = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

	my @holesGroup = ();

	foreach my $l (@layers) {

		my %inf = ();
		$inf{"layer"} = $l;
		$inf{"tools"} = [];

		foreach my $s (@uniqueSR) {

			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $s, $l->{"gROWname"}, 1 );
			next if ( $hist{"total"} == 0 );

			my $unitDTM = UniDTM->new( $inCAM, $jobId, $s, $l->{"gROWname"}, 1 );

			my @uniTools = $unitDTM->GetUniqueTools();

			foreach my $uniTool (@uniTools) {

				unless ( scalar( grep { $_->{"drillSize"} == $uniTool->GetDrillSize() } @{ $inf{"tools"} } ) ) {

					my %toolInf = ();
					$toolInf{"drillSize"} = $uniTool->GetDrillSize();
					$toolInf{"drillDepth"} = ( defined $uniTool->GetDepth() ? $uniTool->GetDepth() : 0 );

					push( @{ $inf{"tools"} }, \%toolInf );
				}
			}

			@{ $inf{"tools"} } = sort { $b->{"drillSize"} <=> $a->{"drillSize"} } @{ $inf{"tools"} };

			push( @holesGroup, \%inf );

		}
	}
 

	return @holesGroup;
}

sub GetHoleCpnPos {
	my $self      = shift;
	my $layer     = shift;
	my $drillSize = shift;

	my $p;

	my @holesGroupPos = @{ $self->{"holesGroupPos"} };

	my $groupOriX = ( $CPN_MARGIN + $TEXT_AREA_WIDTH   + $GROUP_MARGIN ) / 1000;
	my $groupOriY = ( $CPN_MARGIN + $GROUP_MARGIN ) / 1000;

	if ( $MIN_CPN_HEIGHT > ( $holesGroupPos[0]->{"gHeight"} + 2 * $CPN_MARGIN + $GROUP_MARGIN ) ) {

		$groupOriY += ( $MIN_CPN_HEIGHT - ( $holesGroupPos[0]->{"gHeight"} + 2 * $CPN_MARGIN + $GROUP_MARGIN ) ) / 1000 / 2;
	}

	foreach my $groupInf (@holesGroupPos) {

		foreach my $toolInf ( @{ $groupInf->{"tools"} } ) {

			if ( $groupInf->{"layer"}->{"gROWname"} eq $layer && $toolInf->{"drillSize"} eq $drillSize ) {

				$p = Point->new( $groupOriX + $toolInf->{"pos"}->X() / 1000, $groupOriY + $toolInf->{"pos"}->Y() / 1000 );
				last;
			}

		}

		last if ( defined $p );

		$groupOriX += ( $groupInf->{"gWidth"} + $GROUP_MARGIN + $GROUP_DIST + $TEXT_AREA_WIDTH +   $GROUP_MARGIN ) / 1000;

	}

	return $p;
}

sub __DrawCoupon {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my ( $wCpn, $hCpn ) = $self->__GetLayoutDimensions();

	# Define countour polyline
	my @contourP = ();
	push( @contourP, Point->new( 0,     0 ) );
	push( @contourP, Point->new( $wCpn, 0 ) );
	push( @contourP, Point->new( $wCpn, $hCpn ) );
	push( @contourP, Point->new( 0,     $hCpn ) );
	push( @contourP, Point->new( 0,     0 ) );

	my $fillL = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $fillL, "document", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $fillL );

	my $drawBackg = SymbolDrawing->new( $inCAM, $jobId );

	my $solidPattern = SurfaceSolidPattern->new( 0, 0 );
	my $surfP = PrimitiveSurfFill->new( $solidPattern, 0, 0, 0, 0, 0, 0, DrawEnums->Polar_NEGATIVE );
	$drawBackg->AddPrimitive($surfP);
	$drawBackg->Draw();

	# ------------------------------------------------------------------------------------------------
	# 1) Draw pads for ncdrill to signal layers
	# ------------------------------------------------------------------------------------------------

	my @holesGroupPos = @{ $self->{"holesGroupPos"} };
	my $drawSgnlPads = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );

	foreach my $groupInf (@holesGroupPos) {

		foreach my $toolInf ( @{ $groupInf->{"tools"} } ) {

			my $pPos = $self->GetHoleCpnPos( $groupInf->{"layer"}->{"gROWname"}, $toolInf->{"drillSize"} );

			my $padNeg =
			  PrimitivePad->new( "r" . ( $toolInf->{"drillSize"} + 2 * $HOLE_RING + $GND_ISOLATION ), $pPos, 0, DrawEnums->Polar_NEGATIVE );

			$drawSgnlPads->AddPrimitive($padNeg);

			my $pad =
			  PrimitivePad->new( "r" . ( $toolInf->{"drillSize"} + 2 * $HOLE_RING ), $pPos, 0, DrawEnums->Polar_POSITIVE );

			$drawSgnlPads->AddPrimitive($pad);
		}
	}

	$drawSgnlPads->Draw();

	# ------------------------------------------------------------------------------------------------
	# 1) Draw group textarea
	# ------------------------------------------------------------------------------------------------
	my $drawBackgText = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );

	my $groupOriX = ($CPN_MARGIN) / 1000;

	foreach my $groupInf (@holesGroupPos) {

		# Add separator
		my @textAreaLim = ();
		push( @textAreaLim, Point->new( $groupOriX,                           $CPN_MARGIN / 1000 ) );
		push( @textAreaLim, Point->new( $groupOriX + $TEXT_AREA_WIDTH / 1000, $CPN_MARGIN / 1000 ) );
		push( @textAreaLim, Point->new( $groupOriX + $TEXT_AREA_WIDTH / 1000, $hCpn - $CPN_MARGIN / 1000 ) );
		push( @textAreaLim, Point->new( $groupOriX,                           $hCpn - $CPN_MARGIN / 1000 ) );
		push( @textAreaLim, Point->new( $groupOriX,                           $CPN_MARGIN / 1000 ) );

		my $textAreaP = PrimitiveSurfPoly->new( \@textAreaLim, undef, DrawEnums->Polar_POSITIVE );

		$drawBackgText->AddPrimitive($textAreaP);

		# Add gaps
		$groupOriX += ( $TEXT_AREA_WIDTH +   $GROUP_MARGIN + $groupInf->{"gWidth"} + $GROUP_MARGIN + $GROUP_DIST ) / 1000;
	}

	$drawBackgText->Draw();

	my @sigLayers = CamJob->GetSignalLayer( $inCAM, $jobId );

	foreach my $l (@sigLayers) {

		$inCAM->COM(
					 "merge_layers",
					 "source_layer" => $fillL,
					 "dest_layer"   => $l->{"gROWname"},
					 "invert"       => ( $l->{"gROWpolarity"} eq "negative" ? "yes" : "no" )
		);
	}

	CamMatrix->DeleteLayer( $inCAM, $jobId, $fillL );

	# ------------------------------------------------------------------------------------------------
	# 7) Draw texts
	# ------------------------------------------------------------------------------------------------

	foreach my $l (@sigLayers) {

		my $drawLayrNum = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );

		CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );

		my $mirror;

		my $txt = undef;
		if ( $l->{"gROWname"} =~ /^c$/ ) {
			$txt    = 1;
			$mirror = 0;
		}
		elsif ( $l->{"gROWname"} =~ /^s$/ ) {
			$txt    = scalar(@sigLayers);
			$mirror = 1;
		}
		elsif ( $l->{"gROWname"} =~ m/^v(\d+)$/ ) {
			$txt = $1;

			my %attr = CamAttributes->GetLayerAttr( $inCAM, $jobId, "panel", $l->{"gROWname"} );
			$mirror = $attr{"layer_side"} =~ /bot/i ? 1 : 0;
		}

		my $groupTextOriX = ($CPN_MARGIN) / 1000;

		foreach my $groupInf (@holesGroupPos) {

			# 1) Draw layer text
			my $txtFull = "L" . $groupInf->{"layer"}->{"NCSigStartOrder"} . "-" . $groupInf->{"layer"}->{"NCSigEndOrder"};

			my $layerNeg = PrimitiveText->new(
				$txtFull,
				Point->new(
					$groupTextOriX +

					  $TEXT_AREA_WIDTH / 2 / 1000 + ( $mirror ? -1 : 1 ) * ($TEXT_SIZE) / 2 / 1000,
					( $hCpn - ( length($txtFull) * $TEXT_SIZE / 1000 ) ) / 2
				),
				$TEXT_SIZE / 1000,
				$TEXT_SIZE / 1000,
				($TEXT_WIDTH),
				$mirror,
				90,
				$l->{"gROWpolarity"} eq "positive" ? DrawEnums->Polar_NEGATIVE : DrawEnums->Polar_POSITIVE
			);

			$drawLayrNum->AddPrimitive($layerNeg);

			#$drawLayrNum->AddPrimitive($layer);

			$groupTextOriX += ( $TEXT_AREA_WIDTH +   $GROUP_MARGIN + $groupInf->{"gWidth"} + $GROUP_MARGIN + $GROUP_DIST ) / 1000;

		}

		$drawLayrNum->Draw();
	}

	# ------------------------------------------------------------------------------------------------
	# 8)Draw plated holes
	# ------------------------------------------------------------------------------------------------

	foreach my $groupInf (@holesGroupPos) {

		my $drawDrillPads = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );
		CamLayer->WorkLayer( $inCAM, $groupInf->{"layer"}->{"gROWname"} );

		my $defDTMType = CamDTM->GetDTMDefaultType( $inCAM, $jobId, "panel", $groupInf->{"layer"}->{"gROWname"}, 1 );

		#CamDTM->SetDTMTable( $inCAM, $jobId, $self->{"step"}, $groupInf->{"layer"}->{"gROWname"}, $defDTMType );

		foreach my $toolInf ( @{ $groupInf->{"tools"} } ) {

			my $pPos = $self->GetHoleCpnPos( $groupInf->{"layer"}->{"gROWname"}, $toolInf->{"drillSize"} );

			my $pad =
			  PrimitivePad->new( "r" . ( $toolInf->{"drillSize"} ), $pPos, 0, DrawEnums->Polar_POSITIVE );

			$drawDrillPads->AddPrimitive($pad);

		}

		$drawDrillPads->Draw();

		my @DTMTools = CamDTM->GetDTMTools( $inCAM, $jobId, $self->{"step"}, $groupInf->{"layer"}->{"gROWname"} );

		foreach my $toolInf ( @{ $groupInf->{"tools"} } ) {

			if ( $toolInf->{"drillDepth"} ) {

				my $DTMTool = first { $_->{"gTOOLdrill_size"} == $toolInf->{"drillSize"} } @DTMTools;

				$DTMTool->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } = $toolInf->{"drillDepth"};
			}
		}

		CamDTM->SetDTMTools( $inCAM, $jobId, $self->{"step"}, $groupInf->{"layer"}->{"gROWname"}, \@DTMTools, $defDTMType );
	}

	# ------------------------------------------------------------------------------------------------
	# 10) Draw mask layer
	# ------------------------------------------------------------------------------------------------

	my $unMaskL = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $unMaskL, "document", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $unMaskL );

	# Unmask holes

	my $drawUnmaskPads = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );

	foreach my $groupInf (@holesGroupPos) {

		foreach my $toolInf ( @{ $groupInf->{"tools"} } ) {

			my $pPos = $self->GetHoleCpnPos( $groupInf->{"layer"}->{"gROWname"}, $toolInf->{"drillSize"} );

			my $pad =
			  PrimitivePad->new( "r" . ( $toolInf->{"drillSize"} + 2 * $HOLE_RING + 2 * $HOLE_UNMASK ), $pPos, 0, DrawEnums->Polar_POSITIVE );

			$drawUnmaskPads->AddPrimitive($pad);
		}
	}

	$drawUnmaskPads->Draw();

	# Unmask coupon outline
	my $drawUnMaskContour = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );
	$drawUnMaskContour->AddPrimitive( PrimitivePolyline->new( \@contourP, "r200", DrawEnums->Polar_POSITIVE ) );
	$drawUnMaskContour->Draw();

	# Copy prepared mask to existing solder mask layer
	my @masksL = grep { $_->{"gROWlayer_type"} eq "solder_mask" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	foreach my $l (@masksL) {

		$inCAM->COM(
					 "merge_layers",
					 "source_layer" => $unMaskL,
					 "dest_layer"   => $l->{"gROWname"}
		);
	}

	CamMatrix->DeleteLayer( $inCAM, $jobId, $unMaskL );

}

# =========================================================================
# Fnction which return "layout"/ positions of specific coupon features
# =========================================================================

# Return dimension of complete coupon
# Dimension are dynamic and depands on drill hole amount, text sizes, etc..
sub __GetLayoutDimensions {
	my $self = shift;

	my $xStart = 0;
	my $xEnd   = 0;

	my @holesGroupPos = @{ $self->{"holesGroupPos"} };

	for ( my $i = 0 ; $i < scalar(@holesGroupPos) ; $i++ ) {

		my $g = $holesGroupPos[$i];

		$xEnd += $TEXT_AREA_WIDTH;
	 
		$xEnd += $GROUP_MARGIN;
		$xEnd += $g->{"gWidth"};
		$xEnd += $GROUP_MARGIN;

		$xEnd += $GROUP_DIST if ( $i < ( scalar(@holesGroupPos) - 2 ) );
	}
	$xEnd += 2 * $CPN_MARGIN;

	my $yStart = 0;
	my $yEnd   = 0;

	$yEnd += $GROUP_MARGIN;
	$yEnd += $holesGroupPos[0]->{"gHeight"} + 2 * $CPN_MARGIN + $GROUP_MARGIN;
	$yEnd += $GROUP_MARGIN;
	$yEnd += 2 * $CPN_MARGIN;

	$yEnd = $MIN_CPN_HEIGHT if ( $MIN_CPN_HEIGHT > ( $holesGroupPos[0]->{"gHeight"} + 2 * $CPN_MARGIN + $GROUP_MARGIN ) );

	return ( ( $xEnd - $xStart ) / 1000, ( $yEnd - $yStart ) / 1000 );

}

# Holes go from LEFT - RIGHT and DOWN - UP
# First hole starts in 0,0
# First line y = 0, next lines y > 0
sub __GetLayoutHoles {
	my $self = shift;

	my @groupToolPos = [];

	my @groups = @{ $self->{"holes"} };
	my $maxDSize = max( map { $_->{"drillSize"} } map { @{ $_->{"tools"} } } @groups );

	# Find number of lines per group

	my @linesCnt = ();
	foreach my $g (@groups) {

		my $maxLineCntGroup = 1;

		my $gCntLine1   = scalar( @{ $g->{"tools"} } );
		my $line1xLen   = $gCntLine1 * ( $maxDSize + 2 * $HOLE_RING ) + ( $gCntLine1 - 1 ) * $MIN_HOLE_SPACE;
		my $line1xHeigh = ( $maxDSize + 2 * $HOLE_RING );

		my $gCntLine2   = int( scalar( @{ $g->{"tools"} } ) / 2 ) + scalar( @{ $g->{"tools"} } ) % 2;
		my $line2xLen   = $gCntLine2 * ( $maxDSize + 2 * $HOLE_RING ) + ( $gCntLine2 - 1 ) * $MIN_HOLE_SPACE;
		my $line2xHeigh = 2 * ( $maxDSize + 2 * $HOLE_RING ) + $MIN_HOLE_SPACE;

		if ( $line1xLen > $MAX_GROUP_LEN_1LINE && $line1xHeigh < $MAX_GROUP_HEIGHT ) {

			push( @linesCnt, 2 );
		}
		else {
			push( @linesCnt, 1 );
		}
	}

	my $lineCnt = max(@linesCnt);

	# compute group holes positions
	my @holeGroupPos = ();
	foreach my $g (@groups) {

		my %gInf = ();
		$gInf{"layer"} = $g->{"layer"};
		$gInf{"tools"} = [];

		my @tools = @{ $g->{"tools"} };

		my $hPerLine = int( scalar(@tools) / $lineCnt ) + scalar(@tools) % $lineCnt;

		my $curY = 3 * $HOLE_RING + 1.5 * $maxDSize + $MIN_HOLE_SPACE;

		$gInf{"gHeight"} = $curY + $maxDSize / 2 + $HOLE_RING;

		for ( my $ri = 0 ; $ri < scalar($lineCnt) ; $ri++ ) {

			my $curX = $HOLE_RING + $maxDSize / 2;

			for ( my $ci = 0 ; $ci < $hPerLine ; $ci++ ) {

				my $t = shift @tools;
				if ( defined $t ) {

					my %tInf = ();
					$tInf{"drillSize"}  = $t->{"drillSize"};
					$tInf{"drillDepth"} = $t->{"drillDepth"};
					$tInf{"pos"}        = Point->new( $curX, $curY );

					push( @{ $gInf{"tools"} }, \%tInf );
				}

				$curX += 2 * $HOLE_RING + $MIN_HOLE_SPACE + $maxDSize if($ci < $hPerLine-1);
			}

			$gInf{"gWidth"} = $curX + $maxDSize / 2 + $HOLE_RING;

			$curY -= ( 2 * $HOLE_RING + $maxDSize + $MIN_HOLE_SPACE );
		}

		push( @holeGroupPos, \%gInf );
	}

	return @holeGroupPos;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Microsection::CouponIPC3Drill';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d277171";
	my $step  = "panel";

	my $m = CouponIPC3Drill->new( $inCAM, $jobId );
	$m->CreateCoupon();

}

1;

