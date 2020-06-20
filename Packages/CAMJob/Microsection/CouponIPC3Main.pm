
#-------------------------------------------------------------------------------------------#
# Description: Paclage which generate drilling coupon for microsections
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
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::CAM::UniDTM::UniDTM';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my $CPN_HEIGHT = 4000 + 3000;    # 1000 is text

# Hole settings
my $MIN_HOLE_SPACE = 500;        # 500µm hole ring to hole ring
my $HOLE_RING      = 200;        # 200µm hole anular ring
my $HOLE_UNMASK    = 50;         # 50µm hole mask clearance
my $HOLE_LINES     = 2;          # 2 lines of hole

# track settings
my $TRACK_WIDTH  = 200;          # 200µm track width
my $TRACK_ISOL   = 200;          # 200µm track isolation
my $TRACK_LENGTH = 20000;        # 200µm track width

# text settings
my $TITLE_SIZE  = 1700;             # title size
my $TITLE_WIDTH = 200 * 0.00328;    # title text width
my $TEXT_SIZE   = 1200;             # other text size
my $TEXT_WIDTH  = 150 * 0.00328;    # other text width

# other parameters
my $MOUNT_HOLE         = 2500;      # mount hole size 2000µm
my $MOUNT_HOLE_PITCH   = 18000;     # mount hole pitch 18000µm
my $LR_AREA_WIDTH      = 2500;      # width of left + right stripes, where is logo and layer side
my $MIDDLE_AREA_MARGIN = 700;       # margins of whole middle area
my $MIDDLE_AREA_SPACE  = 500;       # vertical Space between titles/ tracks/holes
my $GND_ISOLATION      = 700;       # Isolation of feautures (holes/trakcs/text) of GND

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	return $self;
}

sub CreateCoupon {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @uniqueSR = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

	return 0 unless ( scalar(@uniqueSR) );

	# 1) Get holes types and compute holes positions
	my @holes    = $self->GetHoles(1);
	my @holesPos = $self->__GetHolesPositions( \@holes );
	my ( $wHoles, $hHoles ) = $self->__GetHolesLimits( \@holes, \@holesPos );

	# 2) Create coupon step
	my ( $wCpn, $hCpn ) = $self->__GetDimensions( $wHoles, $hHoles );
	my $stepName = EnumsGeneral->Coupon_IPC3MAIN;
	my $step = SRStep->new( $inCAM, $jobId, $stepName );
	$step->Create( $wCpn, $hCpn, 0, 0, 0, 0 );
	CamHelper->SetStep( $inCAM, $stepName );

	# 3) Draw coupon

	# Define countour polyline
	my @contourP = ();
	push( @contourP, Point->new( 0,     0 ) );
	push( @contourP, Point->new( $wCpn, 0 ) );
	push( @contourP, Point->new( $wCpn, $hCpn ) );
	push( @contourP, Point->new( 0,     $hCpn ) );
	push( @contourP, Point->new( 0,     0 ) );

	# Fill laers with CU

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

	# Draw two tracks
	my $trackTextOriX = ( $LR_AREA_WIDTH + $MIDDLE_AREA_MARGIN ) / 1000;
	my $trackTextOriY = ( $MIDDLE_AREA_MARGIN + $hHoles * 1000 + 2 * $MIDDLE_AREA_SPACE ) / 1000;

	my $drawTrack = SymbolDrawing->new( $inCAM, $jobId, Point->new( $trackTextOriX, $trackTextOriY ) );
	my $trackTextNeg = PrimitiveText->new( $TRACK_WIDTH . "um track/isol",
										   Point->new(),
										   $TEXT_SIZE / 1000,
										   $TEXT_SIZE / 1000,
										   ( $TEXT_WIDTH * 1.2 ),
										   0, 0, DrawEnums->Polar_NEGATIVE );
	$drawTrack->AddPrimitive($trackTextNeg);

	my $trackText =
	  PrimitiveText->new( $TRACK_WIDTH . "um track/isol",
						  Point->new(),
						  $TEXT_SIZE / 1000,
						  $TEXT_SIZE / 1000,
						  ($TEXT_WIDTH), 0, 0, DrawEnums->Polar_POSITIVE );
	$drawTrack->AddPrimitive($trackText);

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

	# Draw title + two mount holes
	my $titleOriX = $wCpn / 2;    # center of coupon
	my $titleOriY =
	  $hCpn - $MIDDLE_AREA_MARGIN / 1000 - max( $TITLE_SIZE, $MOUNT_HOLE ) / 2 / 1000;    # middle of title text height / center of mount holes

	my $drawTitle = SymbolDrawing->new( $inCAM, $jobId, Point->new( $titleOriX, $titleOriY ) );

	my $titleTextNeg = PrimitiveText->new( uc($jobId),
										   Point->new( -length($jobId) * $TITLE_SIZE / 2 / 1000, -$TITLE_SIZE / 2 / 1000 ),
										   $TITLE_SIZE / 1000,
										   $TITLE_SIZE / 1000,
										   ( $TITLE_WIDTH * 1.2 ),
										   0, 0, DrawEnums->Polar_NEGATIVE );
	$drawTrack->AddPrimitive($titleTextNeg);

	my $titleText =
	  PrimitiveText->new( uc($jobId),
						  Point->new( -length($jobId) * $TITLE_SIZE / 2 / 1000, -$TITLE_SIZE / 2 / 1000 ),
						  $TITLE_SIZE / 1000,
						  $TITLE_SIZE / 1000,
						  ($TITLE_WIDTH),, 0, 0, DrawEnums->Polar_POSITIVE );
	$drawTitle->AddPrimitive($titleText);

	# Draw mount holes negative pads

	my $padLeft =
	  PrimitivePad->new( "r" . ( $MOUNT_HOLE + 300 ), Point->new( -$MOUNT_HOLE_PITCH / 2 / 1000, 0 ), 0, DrawEnums->Polar_NEGATIVE );
	$drawTitle->AddPrimitive($padLeft);

	my $padRight =
	  PrimitivePad->new( "r" . ( $MOUNT_HOLE + 300 ), Point->new( $MOUNT_HOLE_PITCH / 2 / 1000, 0 ), 0, DrawEnums->Polar_NEGATIVE );
	$drawTitle->AddPrimitive($padRight);

	$drawTitle->Draw();

	# Draw gatema logo
	my $drawLogo = SymbolDrawing->new( $inCAM, $jobId, Point->new( $LR_AREA_WIDTH / 2 / 1000, $hCpn / 2 ) );
	my $logoNeg = PrimitivePad->new( "gatema_logo", Point->new( 0, 0 ), 0, DrawEnums->Polar_NEGATIVE, 90, $GND_ISOLATION, 0.45, 0.45 );
	$drawLogo->AddPrimitive($logoNeg);
	my $logo = PrimitivePad->new( "gatema_logo", Point->new( 0, 0 ), 0, DrawEnums->Polar_POSITIVE, 90, 0, 0.45, 0.45 );
	$drawLogo->AddPrimitive($logo);
	$drawLogo->Draw();

	# Draw signal pads

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

	# Draw plated holes

	foreach my $holeInf (@holesPos) {

		my $drawDrillPads = SymbolDrawing->new( $inCAM, $jobId, Point->new( $hOriX, $hOriy ) );
		CamLayer->WorkLayer( $inCAM, $holeInf->{"hole"}->{"layer"}->{"gROWname"} );
		foreach my $hPos ( @{ $holeInf->{"positions"} } ) {

			my $pad =
			  PrimitivePad->new( "r" . ( $holeInf->{"hole"}->{"tool"}->{"drillSize"} ), $hPos, 0, DrawEnums->Polar_POSITIVE );

			$drawDrillPads->AddPrimitive($pad);

		}

		$drawDrillPads->Draw();

		if ( $holeInf->{"hole"}->{"tool"}->{"depth"} ) {

			my @tools = CamDTM->GetDTMTools( $inCAM, $jobId, $stepName, $holeInf->{"hole"}->{"layer"}->{"gROWname"} );
			$tools[0]->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } = $holeInf->{"hole"}->{"tool"}->{"depth"};

			CamDTM->SetDTMTools( $inCAM, $jobId, $stepName, $holeInf->{"hole"}->{"layer"}->{"gROWname"}, \@tools );
		}

		# set depths
	}

	#		}
	#
	#	}
	#
	#	# mask pads
	#	my @maskLayers = grep { $_->{"gROWname"} =~ /^m[cs]$/ } CamJob->GetBoardLayers( $inCAM, $jobId );
	#
	#	foreach my $l (@maskLayers) {
	#
	#		CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
	#
	#		foreach my $h (@holes) {
	#
	#			my $p = Point->new( $h->X() / 1000, $h->Y() / 1000 );
	#
	#			CamSymbol->AddPad( $inCAM, "r1480", $p );
	#		}
	#
	#		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $stepName );
	#
	#		my %c1 = ( "x" => $lim{"xMin"}, "y" => $lim{"yMin"} );
	#		my %c2 = ( "x" => $lim{"xMax"}, "y" => $lim{"yMin"} );
	#		my %c3 = ( "x" => $lim{"xMax"}, "y" => $lim{"yMax"} );
	#		my %c4 = ( "x" => $lim{"xMin"}, "y" => $lim{"yMax"} );
	#
	#		my @coord = ( \%c1, \%c2, \%c3, \%c4 );
	#
	#		#
	#		CamSymbol->AddPolyline( $inCAM, \@coord, "r200", "positive", 1 );
	#	}
	#
	#	# add holes
	#	for ( my $i = 0 ; $i < scalar(@groups) ; $i++ ) {
	#
	#		my @holes = $self->__GetGroupHoles($i);
	#
	#		CamLayer->WorkLayer( $inCAM, $groups[$i]->{"layer"} );
	#
	#		foreach my $h (@holes) {
	#
	#			my $p = Point->new( $h->X() / 1000, $h->Y() / 1000 );
	#
	#			CamSymbol->AddPad( $inCAM, "r" . $groups[$i]->{"tool"}, $p );
	#
	#		}
	#
	#		if ( defined $groups[$i]->{"toolDepth"} ) {
	#
	#			my @tools = CamDTM->GetDTMTools( $inCAM, $jobId, $stepName, $groups[$i]->{"layer"} );
	#			$tools[0]->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } = $groups[$i]->{"toolDepth"};
	#
	#			CamDTM->SetDTMTools( $inCAM, $jobId, $stepName, $groups[$i]->{"layer"}, \@tools );
	#		}
	#
	#		# set depths
	#	}
	#
	#	# add texts 1
	#	CamLayer->WorkLayer( $inCAM, "c" );
	#	for ( my $i = 0 ; $i < scalar(@groups) ; $i++ ) {
	#
	#		my $p = Point->new( ( $i * $CPN_GROUP_WIDTH ) + 500, $CPN_HEIGHT - 1500 );
	#
	#		my $p2 = Point->new( $p->X() / 1000, $p->Y() / 1000 );
	#
	#		CamSymbol->AddText( $inCAM, $groups[$i]->{"text"}, $p2, 1, 0.2, 0.3 );
	#	}
	#
	#	# add texts 2
	#	CamLayer->WorkLayer( $inCAM, "c" );
	#	for ( my $i = 0 ; $i < scalar(@groups) ; $i++ ) {
	#
	#		my $p = Point->new( ( $i * $CPN_GROUP_WIDTH ) + 500, $CPN_HEIGHT - 2700 );
	#
	#		my $p2 = Point->new( $p->X() / 1000, $p->Y() / 1000 );
	#
	#		CamSymbol->AddText( $inCAM, $groups[$i]->{"text2"}, $p2, 1, 0.2, 0.3 );
	#	}
	#
	#	# add separator
	#	CamLayer->WorkLayer( $inCAM, "c" );
	#	for ( my $i = 1 ; $i < scalar(@groups) ; $i++ ) {
	#
	#		my $ps = Point->new( ( $i * $CPN_GROUP_WIDTH ) / 1000, ( $CPN_HEIGHT - 200 ) / 1000 );
	#		my $pe = Point->new( ( $i * $CPN_GROUP_WIDTH ) / 1000, (200) / 1000 );
	#
	#		CamSymbol->AddLine( $inCAM, $ps, $pe, "r200" );
	#	}

	return 1;

}

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

# Holes go from LEFT - RIGHT and DOWN - UP
# First hole starts in 0,0
# First line y = 0, next lines y > 0
sub __GetHolesPositions {
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

sub __GetDimensions {
	my $self   = shift;
	my $holesW = shift;
	my $holesH = shift;

	my $xStart = 0;
	my $xEnd   = 0;

	$xEnd += $LR_AREA_WIDTH;
	$xEnd += $MIDDLE_AREA_MARGIN;
	$xEnd += max( $holesW * 1000, $TRACK_LENGTH );
	$xEnd += $MIDDLE_AREA_MARGIN;
	$xEnd += $LR_AREA_WIDTH;

	my $yStart = 0;
	my $yEnd   = 0;

	$yEnd += $MIDDLE_AREA_MARGIN;
	$yEnd += $holesH * 1000;
	$yEnd += 2 * $MIDDLE_AREA_SPACE;
	$yEnd += $TEXT_SIZE;
	$yEnd += $MIDDLE_AREA_SPACE;
	$yEnd += 2 * $TRACK_WIDTH + $TRACK_ISOL;
	$yEnd += 3 * $MIDDLE_AREA_SPACE;
	$yEnd += max( $TITLE_SIZE, $MOUNT_HOLE );
	$yEnd += $MIDDLE_AREA_MARGIN;

	return ( ( $xEnd - $xStart ) / 1000, ( $yEnd - $yStart ) / 1000 );

}

sub __GetHolesLimits {
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

