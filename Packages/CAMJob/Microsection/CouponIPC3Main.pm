
#-------------------------------------------------------------------------------------------#
# Description: Paclage which generate IPC3 coupon for microsections
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Microsection::CouponIPC3Main;

#3th party library
use strict;
use warnings;
use JSON;
use List::Util qw[max min];

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

# Hole settings
my $MIN_HOLE_SPACE = 700;    # 500µm hole ring to hole ring
my $HOLE_RING      = 200;    # 200µm hole anular ring
my $HOLE_UNMASK    = 50;     # 50µm hole mask clearance
my $HOLE_LINES     = 2;      # 2 lines of hole

# track settings
my $TRACK_WIDTH  = 200;      # 200µm track width
my $TRACK_ISOL   = 200;      # 200µm track isolation
my $TRACK_LENGTH = 20000;    # 200µm track width

# text settings
my $magicConstant = 0.00328;                 # InCAM need text width converted with this constant , took keep required width in µm
my $TITLE_SIZE    = 1700;                    # title size
my $TITLE_WIDTH   = 250 * $magicConstant;    # title text width
my $TEXT_SIZE     = 1200;                    # other text size
my $TEXT_WIDTH    = 200 * $magicConstant;    # other text width

# Rout bridges settings
my $BRIDGES_CNT_W = 1;
my $BRIDGES_CNT_H = 1;
my $BRIDGES_WIDTH = 1000;                    # bridges width in µm

# other parameters
my $MOUNT_HOLE         = 3150;               # mount hole size 2000µm
my $MOUNT_HOLE_PITCH   = 17000;              # mount hole pitch 18000µm
my $LR_AREA_WIDTH      = 2500;               # width of left + right stripes, where is logo and layer side
my $MIDDLE_AREA_MARGIN = 700;                # margins of whole middle area
my $MIDDLE_AREA_SPACE  = 500;                # vertical Space between titles/ tracks/holes
my $GND_ISOLATION      = 700;                # Isolation of feautures (holes/trakcs/text) of GND

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"step"} = EnumsGeneral->Coupon_IPC3MAIN;

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
	my @holes    = $self->GetHoles(1);
	my @holesPos = $self->__GetLayoutHoles( \@holes );

	# 2) Create coupon step
	my ( $wCpn, $hCpn ) = $self->__GetLayoutDimensions( \@holes, \@holesPos );

	my $step = SRStep->new( $inCAM, $jobId, $self->{"step"} );
	$step->Create( $wCpn, $hCpn, 0, 0, 0, 0 );
	CamHelper->SetStep( $inCAM, $self->{"step"} );

	$self->__DrawCoupon( $wCpn, $hCpn, \@holes, \@holesPos );

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

	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

	my @uniqueSR = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

	my @holes = ();

	foreach my $l (@layers) {

		my $minTool = undef;

		foreach my $s (@uniqueSR) {

			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $s, $l->{"gROWname"}, 1 );
			next if ( $hist{"total"} == 0 );

			my $unitDTM = UniDTM->new( $inCAM, $jobId, $s, $l->{"gROWname"}, 1 );
			my $uniTool = $unitDTM->GetMinTool( EnumsDrill->TypeProc_HOLE, 1 );

			if ( !defined $minTool || $uniTool->GetDrillSize() < $minTool->GetDrillSize() ) {
				$minTool = $uniTool;
			}
		}

		if ( defined $minTool ) {

			my %inf = ();
			$inf{"layer"} = $l;
			$inf{"tool"}->{"drillSize"} = $minTool->GetDrillSize();
			$inf{"tool"}->{"depth"} = defined $minTool->GetDepth() ? $minTool->GetDepth() : 0;

			push( @holes, \%inf );

		}
	}

	# Add default hole 1mm
	if ($addDefHole) {
		my $inf =
		  grep { $_->{"layer"}->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill && $_->{"tool"}->{"drillSize"} == 1000 } @holes;

		my @through = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );
		CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@through );
		@through = grep { $_->{"NCSigStartOrder"} == 1 } @through;

		if ( !scalar($inf) && scalar(@through) ) {
			my %inf = ();
			$inf{"layer"}               = $through[0];
			$inf{"tool"}->{"drillSize"} = 1000;
			$inf{"tool"}->{"depth"}     = 0;

			push( @holes, \%inf );
		}
	}

	# Sort holes by size

	@holes = sort { $b->{"tool"}->{"drillSize"} <=> $a->{"tool"}->{"drillSize"} } @holes;
	return @holes;
}

sub __DrawCoupon {
	my $self     = shift;
	my $wCpn     = shift;
	my $hCpn     = shift;
	my @holes    = @{ shift(@_) };
	my @holesPos = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my ( $wHoles, $hHoles ) = $self->__GetLayoutHolesLimits( \@holes, \@holesPos );

	# Define countour polyline
	my @contourP = ();
	push( @contourP, Point->new( 0,     0 ) );
	push( @contourP, Point->new( $wCpn, 0 ) );
	push( @contourP, Point->new( $wCpn, $hCpn ) );
	push( @contourP, Point->new( 0,     $hCpn ) );
	push( @contourP, Point->new( 0,     0 ) );

	# ------------------------------------------------------------------------------------------------
	# 1) Draw coupon background
	# ------------------------------------------------------------------------------------------------

	my $drawBackg = SymbolDrawing->new( $inCAM, $jobId );
	my $fillL = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $fillL, "document", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $fillL );

	my $solidPattern = SurfaceSolidPattern->new( 0, 0 );
	my $surfP = PrimitiveSurfFill->new( $solidPattern, 0, 0, 0, 0, 0, 0, DrawEnums->Polar_NEGATIVE );
	$drawBackg->AddPrimitive($surfP);

	my @leftAreaLim = ();
	push( @leftAreaLim, Point->new( 0,                     0 ) );
	push( @leftAreaLim, Point->new( $LR_AREA_WIDTH / 1000, 0 ) );
	push( @leftAreaLim, Point->new( $LR_AREA_WIDTH / 1000, $hCpn ) );
	push( @leftAreaLim, Point->new( 0,                     $hCpn ) );
	push( @leftAreaLim, Point->new( 0,                     0 ) );

	my $leftAreaP = PrimitiveSurfPoly->new( \@leftAreaLim, undef, DrawEnums->Polar_POSITIVE );
	my $righttAreaP = $leftAreaP->Copy();

	$_->Move( $wCpn - $LR_AREA_WIDTH / 1000 ) foreach $righttAreaP->GetPoints();
	$drawBackg->AddPrimitive($leftAreaP);
	$drawBackg->AddPrimitive($righttAreaP);

	$drawBackg->AddPrimitive( PrimitivePolyline->new( \@contourP, "r150", DrawEnums->Polar_NEGATIVE ) );

	$drawBackg->Draw();

	# ------------------------------------------------------------------------------------------------
	# 2) Draw pads for ncdrill to signal layers
	# ------------------------------------------------------------------------------------------------

	my $hOriX = ( $LR_AREA_WIDTH + $MIDDLE_AREA_MARGIN + $holesPos[0]->{"hole"}->{"tool"}->{"drillSize"} / 2 + $HOLE_RING ) / 1000;
	my $hOriy = ( $MIDDLE_AREA_MARGIN + max( map { $_->{"tool"}->{"drillSize"} } @holes ) / 2 + $HOLE_RING ) / 1000;

	my $drawSgnlPads = SymbolDrawing->new( $inCAM, $jobId, Point->new( $hOriX, $hOriy ) );

	foreach my $holeInf (@holesPos) {

		foreach my $hPos ( @{ $holeInf->{"positions"} } ) {

			my $padNeg =
			  PrimitivePad->new( "r" . ( $holeInf->{"hole"}->{"tool"}->{"drillSize"} + 2 * $HOLE_RING + $GND_ISOLATION ),
								 $hPos, 0, DrawEnums->Polar_NEGATIVE );

			$drawSgnlPads->AddPrimitive($padNeg);

			my $pad =
			  PrimitivePad->new( "r" . ( $holeInf->{"hole"}->{"tool"}->{"drillSize"} + 2 * $HOLE_RING ), $hPos, 0, DrawEnums->Polar_POSITIVE );

			$drawSgnlPads->AddPrimitive($pad);

		}
	}

	$drawSgnlPads->Draw();

	# ------------------------------------------------------------------------------------------------
	# 3) Draw tracks
	# ------------------------------------------------------------------------------------------------

	my $trackTextOriX = ( $LR_AREA_WIDTH + $MIDDLE_AREA_MARGIN ) / 1000;
	my $trackTextOriY = ( $MIDDLE_AREA_MARGIN + $hHoles * 1000 + 2 * $MIDDLE_AREA_SPACE ) / 1000;

	my $drawTrack = SymbolDrawing->new( $inCAM, $jobId, Point->new( $trackTextOriX, $trackTextOriY ) );

	my $trackOriX = 0;
	my $trackOriY = $MIDDLE_AREA_SPACE / 1000 + $TEXT_SIZE / 1000 + $MIDDLE_AREA_SPACE / 1000;

	my $botTrackNeg = PrimitiveLine->new(
										  Point->new( $trackOriX,                        $trackOriY ),
										  Point->new( $trackOriX + $TRACK_LENGTH / 1000, $trackOriY ),
										  "r" . ( $TRACK_WIDTH + $GND_ISOLATION ),
										  DrawEnums->Polar_NEGATIVE
	);
	my $botTrack = PrimitiveLine->new(
									   Point->new( $trackOriX,                        $trackOriY ),
									   Point->new( $trackOriX + $TRACK_LENGTH / 1000, $trackOriY ),
									   "r" . ($TRACK_WIDTH),
									   DrawEnums->Polar_POSITIVE
	);

	my $topTrackNeg = PrimitiveLine->new(
										  Point->new( $trackOriX,                        $trackOriY + $TRACK_ISOL / 1000 + $TRACK_WIDTH / 1000 ),
										  Point->new( $trackOriX + $TRACK_LENGTH / 1000, $trackOriY + $TRACK_ISOL / 1000 + $TRACK_WIDTH / 1000 ),
										  "r" . ( $TRACK_WIDTH + $GND_ISOLATION ),
										  DrawEnums->Polar_NEGATIVE
	);
	my $topTrack = PrimitiveLine->new(
									   Point->new( $trackOriX,                        $trackOriY + $TRACK_ISOL / 1000 + $TRACK_WIDTH / 1000 ),
									   Point->new( $trackOriX + $TRACK_LENGTH / 1000, $trackOriY + $TRACK_ISOL / 1000 + $TRACK_WIDTH / 1000 ),
									   "r" . ($TRACK_WIDTH),
									   DrawEnums->Polar_POSITIVE
	);

	$drawTrack->AddPrimitive($botTrackNeg);
	$drawTrack->AddPrimitive($topTrackNeg);
	$drawTrack->AddPrimitive($botTrack);
	$drawTrack->AddPrimitive($topTrack);

	$drawTrack->Draw();

	# ------------------------------------------------------------------------------------------------
	# 4) Two mount holes negatives
	# ------------------------------------------------------------------------------------------------
	my ( $mountPLeft, $mountPRight ) = $self->__GetLayoutMountHoles( $wCpn, $hCpn );

	my $drawMountNegHoles = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );

	my $padLeft = PrimitivePad->new( "r" . ( $MOUNT_HOLE + 300 ), $mountPLeft, 0, DrawEnums->Polar_NEGATIVE );
	$drawMountNegHoles->AddPrimitive($padLeft);

	my $padRight = PrimitivePad->new( "r" . ( $MOUNT_HOLE + 300 ), $mountPRight, 0, DrawEnums->Polar_NEGATIVE );
	$drawMountNegHoles->AddPrimitive($padRight);

	$drawMountNegHoles->Draw();

	# ------------------------------------------------------------------------------------------------
	# 6)Draw plated drills
	# ------------------------------------------------------------------------------------------------

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

			#			my %lPars = JobHelper->ParseSignalLayerName( $l->{"gROWname"} );
			#			$mirror = $self->{"stackup"}->GetSideByCuLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );
			my %attr = CamAttributes->GetLayerAttr( $inCAM, $jobId, "panel", $l->{"gROWname"} );
			$mirror = $attr{"layer_side"} =~ /bot/i ? 1 : 0;
		}

		# 1) Draw track text

		my $trackTextOriX =
		  ( $mirror ? $wCpn - ( $LR_AREA_WIDTH + $MIDDLE_AREA_MARGIN ) / 1000 : ( $LR_AREA_WIDTH + $MIDDLE_AREA_MARGIN ) / 1000 );
		my $trackTextOriY = ( $MIDDLE_AREA_MARGIN + $hHoles * 1000 + 2 * $MIDDLE_AREA_SPACE ) / 1000;

		my $drawTrack = SymbolDrawing->new( $inCAM, $jobId, Point->new( $trackTextOriX, $trackTextOriY ) );
		my $trackTextNeg = PrimitiveText->new( $TRACK_WIDTH . "um track/isol",
											   Point->new(),
											   $TEXT_SIZE / 1000,
											   $TEXT_SIZE / 1000,
											   ( $TEXT_WIDTH * 1.2 ),
											   $mirror, 0, DrawEnums->Polar_NEGATIVE );
		$drawTrack->AddPrimitive($trackTextNeg);

		my $trackText =
		  PrimitiveText->new( $TRACK_WIDTH . "um track/isol",
							  Point->new(),
							  $TEXT_SIZE / 1000,
							  $TEXT_SIZE / 1000,
							  ($TEXT_WIDTH), $mirror, 0, DrawEnums->Polar_POSITIVE );
		$drawTrack->AddPrimitive($trackText);

		$drawTrack->Draw();

		# 1) Draw gatema logo

		my $drawLogo = SymbolDrawing->new( $inCAM, $jobId, Point->new( $LR_AREA_WIDTH / 2 / 1000, $hCpn / 2 ) );
		my $logoNeg = PrimitivePad->new( "gatema_logo", Point->new( 0, 0 ), $mirror, DrawEnums->Polar_NEGATIVE, 90, 0, 0.45, 0.45 );
		$drawLogo->AddPrimitive($logoNeg);
		my $logo = PrimitivePad->new( "gatema_logo", Point->new( 0, 0 ), $mirror, DrawEnums->Polar_POSITIVE, 90, 0, 0.45, 0.45 );

		#$drawLogo->AddPrimitive($logo);
		$drawLogo->Draw();

		my $drawLayrNum = SymbolDrawing->new( $inCAM, $jobId, Point->new( $wCpn - $LR_AREA_WIDTH / 2 / 1000, $hCpn / 2 ) );

		# 2) Draw layer text
		my $txtFull = "L" . $txt . " layer";

		my $layerNeg = PrimitiveText->new(
										   $txtFull,
										   Point->new(
													   ( $mirror ? -1 : 1 ) * ($TEXT_SIZE) / 2 / 1000, -( length($txtFull) * $TEXT_SIZE / 2 / 1000 )
										   ),
										   $TEXT_SIZE / 1000,
										   $TEXT_SIZE / 1000,
										   ($TEXT_WIDTH),
										   $mirror, 90,
										   DrawEnums->Polar_NEGATIVE
		);

		$drawLayrNum->AddPrimitive($layerNeg);

		my $layer = PrimitiveText->new( $txtFull,
										Point->new( ( $mirror ? -1 : 1 ) * ($TEXT_SIZE) / 2 / 1000, -( length($txtFull) * $TEXT_SIZE / 2 / 1000 ) ),
										$TEXT_SIZE / 1000,
										$TEXT_SIZE / 1000,
										($TEXT_WIDTH), $mirror, 90, DrawEnums->Polar_POSITIVE );

		#$drawLayrNum->AddPrimitive($layer);
		$drawLayrNum->Draw();

		# Draw title
		my ( $titleOriX, $titleOriY ) = $self->__GetLayoutTitleOrigin( $wCpn, $hCpn );

		my $drawTitle = SymbolDrawing->new( $inCAM, $jobId, Point->new( $titleOriX, $titleOriY ) );

		my $titleTextNeg = PrimitiveText->new(
											   uc($jobId),
											   Point->new(
														   ( $mirror ? 1 : -1 ) * ( length($jobId) * $TITLE_SIZE / 2 / 1000 ),
														   -$TITLE_SIZE / 2 / 1000
											   ),
											   $TITLE_SIZE / 1000,
											   $TITLE_SIZE / 1000,
											   ( $TITLE_WIDTH * 1.2 ),
											   $mirror, 0,
											   DrawEnums->Polar_NEGATIVE
		);
		$drawTrack->AddPrimitive($titleTextNeg);

		my $titleText = PrimitiveText->new( uc($jobId),
											Point->new( ( $mirror ? 1 : -1 ) * ( length($jobId) * $TITLE_SIZE / 2 / 1000 ), -$TITLE_SIZE / 2 / 1000 ),
											$TITLE_SIZE / 1000,
											$TITLE_SIZE / 1000,
											($TITLE_WIDTH), $mirror, 0, DrawEnums->Polar_POSITIVE );
		$drawTitle->AddPrimitive($titleText);

		$drawTitle->Draw();

	}

	# ------------------------------------------------------------------------------------------------
	# 8)Draw plated holes
	# ------------------------------------------------------------------------------------------------

	foreach my $holeInf (@holesPos) {

		my $drawDrillPads = SymbolDrawing->new( $inCAM, $jobId, Point->new( $hOriX, $hOriy ) );
		CamLayer->WorkLayer( $inCAM, $holeInf->{"hole"}->{"layer"}->{"gROWname"} );
		foreach my $hPos ( @{ $holeInf->{"positions"} } ) {

			my $pad =
			  PrimitivePad->new( "r" . ( $holeInf->{"hole"}->{"tool"}->{"drillSize"} ), $hPos, 0, DrawEnums->Polar_POSITIVE );

			$drawDrillPads->AddPrimitive($pad);

		}

		$drawDrillPads->Draw();

		my $defDTMType = CamDTM->GetDTMDefaultType( $inCAM, $jobId, "panel", $holeInf->{"hole"}->{"layer"}->{"gROWname"}, 1 );

		my @tools = CamDTM->GetDTMTools( $inCAM, $jobId, $self->{"step"}, $holeInf->{"hole"}->{"layer"}->{"gROWname"} );
		$tools[0]->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } = $holeInf->{"hole"}->{"tool"}->{"depth"};

		CamDTM->SetDTMTools( $inCAM, $jobId, $self->{"step"}, $holeInf->{"hole"}->{"layer"}->{"gROWname"}, \@tools, $defDTMType );

		# set depths
	}

	# ------------------------------------------------------------------------------------------------
	# 10) Draw mask layer
	# ------------------------------------------------------------------------------------------------

	my $unMaskL = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $unMaskL, "document", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $unMaskL );

	# Unmask holes

	my $drawUnmaskPads = SymbolDrawing->new( $inCAM, $jobId, Point->new( $hOriX, $hOriy ) );

	foreach my $holeInf (@holesPos) {

		foreach my $hPos ( @{ $holeInf->{"positions"} } ) {

			my $pad =
			  PrimitivePad->new( "r" . ( $holeInf->{"hole"}->{"tool"}->{"drillSize"} + 2 * $HOLE_RING + 2 * $HOLE_UNMASK ),
								 $hPos, 0, DrawEnums->Polar_POSITIVE );

			$drawUnmaskPads->AddPrimitive($pad);
		}
	}
	$drawUnmaskPads->Draw();

	# UnMask mount holes

	my $drawUnMaskMountHoles = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );

	my $mountLeftLeft = PrimitivePad->new( "r" . ( $MOUNT_HOLE + 2 * $HOLE_UNMASK ), $mountPLeft, 0, DrawEnums->Polar_POSITIVE );
	$drawUnMaskMountHoles->AddPrimitive($mountLeftLeft);

	my $mountRight = PrimitivePad->new( "r" . ( $MOUNT_HOLE + 2 * $HOLE_UNMASK ), $mountPRight, 0, DrawEnums->Polar_POSITIVE );
	$drawUnMaskMountHoles->AddPrimitive($mountRight);

	$drawUnMaskMountHoles->Draw();

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

	# UnMask title text

	foreach my $maskL (@masksL) {

		my $sigL = ( $maskL->{"gROWname"} =~ /^m([cs])\d?$/ )[0];

		if ( CamHelper->LayerExists( $inCAM, $jobId, $sigL ) ) {

			my $f = FeatureFilter->new( $inCAM, $jobId, $sigL );
			$f->SetText($jobId);
			$f->SetFeatureTypes( "text" => 1 );
			if ( $f->Select() ) {

				my $unMaskTitleL = GeneralHelper->GetGUID();

				CamLayer->CopySelOtherLayer( $inCAM, [$unMaskTitleL] );

				CamLayer->WorkLayer( $inCAM, $unMaskTitleL );
				CamLayer->Contourize( $inCAM, $unMaskTitleL );
				CamLayer->WorkLayer( $inCAM, $unMaskTitleL );
				CamLayer->ResizeFeatures( $inCAM, 100 );
				$inCAM->COM(
							 "merge_layers",
							 "source_layer" => $unMaskTitleL,
							 "dest_layer"   => $maskL->{"gROWname"}
				);

				CamMatrix->DeleteLayer( $inCAM, $jobId, $unMaskTitleL );
			}
		}

	}

	# ------------------------------------------------------------------------------------------------
	# 10) Draw mount holes
	# ------------------------------------------------------------------------------------------------

	CamMatrix->CreateLayer( $inCAM, $jobId, "f", "rout", "positive", 1 ) unless ( CamHelper->LayerExists( $inCAM, $jobId, "f" ) );

	my $drawMountHoles = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );
	CamLayer->WorkLayer( $inCAM, "f" );

	my $drillLeft = PrimitivePad->new( "r" . ($MOUNT_HOLE), $mountPLeft, 0, DrawEnums->Polar_POSITIVE );
	$drawMountHoles->AddPrimitive($drillLeft);

	my $drillRight = PrimitivePad->new( "r" . ($MOUNT_HOLE), $mountPRight, 0, DrawEnums->Polar_POSITIVE );
	$drawMountHoles->AddPrimitive($drillRight);

	$drawMountHoles->Draw();

	# ------------------------------------------------------------------------------------------------
	# 11) Prepare outline rout on bridges
	# ------------------------------------------------------------------------------------------------
	Helper->PrepareProfileRoutOnBridges( $inCAM, $jobId, $self->{"step"}, 1, 1, $BRIDGES_CNT_W, $BRIDGES_CNT_H, $BRIDGES_WIDTH );

	CamLayer->ClearLayers($inCAM);

	return 1;

}

# =========================================================================
# Fnction which return "layout"/ positions of specific coupon features
# =========================================================================

# Return dimension of complete coupon
# Dimension are dynamic and depands on drill hole amount, text sizes, etc..
sub __GetLayoutDimensions {
	my $self     = shift;
	my @holes    = @{ shift(@_) };
	my @holesPos = @{ shift(@_) };

	my $xStart = 0;
	my $xEnd   = 0;

	my ( $wHoles, $hHoles ) = $self->__GetLayoutHolesLimits( \@holes, \@holesPos );

	$xEnd += $LR_AREA_WIDTH;
	$xEnd += $MIDDLE_AREA_MARGIN;
	$xEnd += max( $wHoles * 1000, $TRACK_LENGTH );
	$xEnd += $MIDDLE_AREA_MARGIN;
	$xEnd += $LR_AREA_WIDTH;

	my $yStart = 0;
	my $yEnd   = 0;

	$yEnd += $MIDDLE_AREA_MARGIN;
	$yEnd += $hHoles * 1000;
	$yEnd += 2 * $MIDDLE_AREA_SPACE;
	$yEnd += $TEXT_SIZE;
	$yEnd += $MIDDLE_AREA_SPACE;
	$yEnd += 2 * $TRACK_WIDTH + $TRACK_ISOL;
	$yEnd += 3 * $MIDDLE_AREA_SPACE;
	$yEnd += max( $TITLE_SIZE, $MOUNT_HOLE );
	$yEnd += $MIDDLE_AREA_MARGIN;

	return ( ( $xEnd - $xStart ) / 1000, ( $yEnd - $yStart ) / 1000 );

}

# Holes go from LEFT - RIGHT and DOWN - UP
# First hole starts in 0,0
# First line y = 0, next lines y > 0
sub __GetLayoutHoles {
	my $self  = shift;
	my @holes = @{ shift(@_) };

	my @holesPos = ();

	my $posX = 0;

	for ( my $j = 0 ; $j < scalar(@holes) ; $j++ ) {

		my $tool = $holes[$j]->{"tool"};

		if ( $j > 0 ) {
			$posX += $MIN_HOLE_SPACE / 1000 + $tool->{"drillSize"} / 1000 / 2 + $HOLE_RING / 1000;
		}

		my $posY     = 0;
		my @posLines = ();
		for ( my $i = 0 ; $i < $HOLE_LINES ; $i++ ) {

			push( @posLines, Point->new( $posX, $posY ) );

			# Find diameter of biigest hole
			my $maxDim = max( map { $_->{"tool"}->{"drillSize"} } @holes );
			$posY += $maxDim / 1000 + 2 * $HOLE_RING / 1000 + $MIN_HOLE_SPACE / 1000;
		}

		my %inf = ( "hole" => $holes[$j], "positions" => \@posLines );
		$posX += $tool->{"drillSize"} / 1000 / 2 + $HOLE_RING / 1000;

		push( @holesPos, \%inf );

	}

	return @holesPos;
}

# Return width and height of rectangle, which is created by limits of all drill holes (+ theirs Cu rings)
sub __GetLayoutHolesLimits {
	my $self     = shift;
	my @holes    = @{ shift(@_) };
	my @holesPos = @{ shift(@_) };

	my $w =
	  ( $holesPos[0]->{"hole"}->{"tool"}->{"drillSize"} / 2 + $HOLE_RING ) / 1000 +
	  ( $holesPos[-1]->{"hole"}->{"tool"}->{"drillSize"} / 2 + $HOLE_RING ) / 1000 +
	  $holesPos[-1]->{"positions"}->[0]->X();

	my $maxDim = max( map { $_->{"tool"}->{"drillSize"} } @holes );

	my $h = ( $HOLE_LINES * ( $maxDim + 2 * $HOLE_RING ) + ( $HOLE_LINES - 1 ) * $MIN_HOLE_SPACE ) / 1000;

	return ( $w, $h );

}

# Rerturn two Point object for left and right mount hole
sub __GetLayoutMountHoles {
	my $self = shift;
	my $wCpn = shift;
	my $hCpn = shift;

	my $oriX = $wCpn / 2;                                                                        # center of coupon
	my $oriY = $hCpn - $MIDDLE_AREA_MARGIN / 1000 - max( $TITLE_SIZE, $MOUNT_HOLE ) / 2 / 1000;  # middle of title text height / center of mount holes

	my $leftP  = Point->new( $oriX - $MOUNT_HOLE_PITCH / 2 / 1000, $oriY );
	my $rightP = Point->new( $oriX + $MOUNT_HOLE_PITCH / 2 / 1000, $oriY );

	return ( $leftP, $rightP );
}

# Return center point of title text
sub __GetLayoutTitleOrigin {
	my $self = shift;
	my $wCpn = shift;
	my $hCpn = shift;

	my $titleOriX = $wCpn / 2;    # center of coupon
	my $titleOriY =
	  $hCpn - $MIDDLE_AREA_MARGIN / 1000 - max( $TITLE_SIZE, $MOUNT_HOLE ) / 2 / 1000;    # middle of title text height / center of mount holes

	return ( $titleOriX, $titleOriY );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Microsection::CouponIPC3Main';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d277171";
	my $step  = "panel";

	my $m = CouponIPC3Main->new( $inCAM, $jobId );
	$m->CreateCoupon();

}

1;

