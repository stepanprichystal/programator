#-------------------------------------------------------------------------------------------#
# Description: Adjustment of customer schema
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::FlexiLayers::FlexiBendArea;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use List::Util qw[max min];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamSymbolArc';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::Stackup::Enums' => 'EnumsStack';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::BendAreaParser';
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::CoverlayPinParser';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';
use aliased 'Packages::Polygon::Polygon::PolygonPoints';
use aliased 'Packages::Polygon::Enums' => 'PolyEnums';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums'                     => "FilterEnums";
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::Enums' => 'EnumsPins';
use aliased 'Packages::Polygon::PointsTransform';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Check if mpanel contain requsted schema by customer
sub PutCuToBendArea {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $clearance = shift // 250;    # Default clearance of Cu from bend border is 250?m
	my $lCu       = shift;           # ref where array of affected signal layer name will be stored

	my $result = 1;

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	my @bendAreas = $parser->GetBendAreas();

	# put Cu only to rigid signal layer
	my @layers = ();

	my @lamPackages = StackupOperation->GetJoinedFlexRigidProducts( $inCAM, $jobId );

	foreach my $lamPckg (@lamPackages) {

		if (    $lamPckg->{"pTopCoreType"} eq EnumsStack->CoreType_FLEX
			 && $lamPckg->{"pBotCoreType"} eq EnumsStack->CoreType_RIGID )
		{

			# find first Cu layer in BOT package
			my $lName = $lamPckg->{"pBot"}->GetTopCopperLayer();

			die "Not a inner copper layer: $lName" if ( $lName !~ /^v\d+$/ );
			push( @layers, [ $lName, CamMatrix->GetLayerPolarity( $inCAM, $jobId, $lName ) ] );

		}
		elsif (    $lamPckg->{"pTopCoreType"} eq EnumsStack->CoreType_RIGID
				&& $lamPckg->{"pBotCoreType"} eq EnumsStack->CoreType_FLEX )
		{

			# find first Cu layer in TOP package

			my $lName = $lamPckg->{"pTop"}->GetBotCopperLayer();

			die "Not a inner copper layer: $lName" if ( $lName !~ /^v\d+$/ );

			push( @layers, [ $lName, CamMatrix->GetLayerPolarity( $inCAM, $jobId, $lName ) ] );
		}
	}

	my @lNames = map { $_->[0] } @layers;
	if ( scalar(@lNames) ) {

		push( @{$lCu}, @lNames );

		CamHelper->SetStep( $inCAM, $step );

		my $CUSTRINGATT = "cu_flex_area";

		# Delete old pin marks
		my $f = FeatureFilter->new( $inCAM, $jobId, undef, \@lNames );

		$f->AddIncludeAtt( ".string", $CUSTRINGATT );

		if ( $f->Select() ) {
			CamLayer->DeleteFeatures($inCAM);
		}

		CamSymbol->ResetCurAttributes($inCAM);
		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", $CUSTRINGATT );

		foreach my $l (@layers) {

			CamLayer->WorkLayer( $inCAM, $l->[0] );

			foreach my $bendArea (@bendAreas) {

				my @points = $bendArea->GetPoints();

				#CamSymbolSurf->AddSurfaceSolidPattern( $inCAM, 1, 2000, 1 );
				CamSymbolSurf->AddSurfacePolyline( $inCAM, \@points, 1, $l->[1] );
				CamSymbol->AddPolyline( $inCAM, \@points, "r" . ( 2 * $clearance ), ( $l->[1] eq "positive" ? "negative" : "positive" ) );
			}
		}

		CamSymbol->ResetCurAttributes($inCAM);
		CamLayer->ClearLayers($inCAM);

	}

	return $result;
}

# If pcb contain soldermask an coverlay, unmask bend area in c,s
sub UnMaskBendArea {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $layer     = shift;
	my $clearance = shift // 100;    # Default clearance of solder mask from bend area

	my $UMASKSTRINGATT = "unmask_bend_area";

	my $result = 1;

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	my @bendAreas = $parser->GetBendAreas();

	CamHelper->SetStep( $inCAM, $step );

	CamLayer->WorkLayer( $inCAM, $layer );

	# Remove former unmasking if is present

	# Delete old pin marks
	my $f = FeatureFilter->new( $inCAM, $jobId, $layer );

	$f->AddIncludeAtt( ".string", $UMASKSTRINGATT );

	if ( $f->Select() ) {
		CamLayer->DeleteFeatures($inCAM);
	}

	CamSymbol->ResetCurAttributes($inCAM);

	CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", $UMASKSTRINGATT );

	foreach my $bendArea (@bendAreas) {

		my @points = $bendArea->GetPoints();

		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@points, 1 );
		CamSymbol->AddPolyline( $inCAM, \@points, "r" . ( 2 * $clearance ), "positive" );

	}

	CamSymbol->ResetCurAttributes($inCAM);

	CamLayer->ClearLayers($inCAM);

	return $result;
}

# If pcb contain soldermask an coverlay, unmask bend area in c,s
sub PrepareFlexMask {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $overlap = shift // 900;    # Overlap of flexible mask torigid part

	my $result = 1;

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step, undef, 2 * $overlap );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	my @bendAreas = $parser->GetBendAreas();

	CamHelper->SetStep( $inCAM, $step );

	my $signalL = "c";
	$signalL = "s" if ( $layer =~ /s/ && CamHelper->LayerExists( $inCAM, $jobId, $signalL ) );

	CamMatrix->DeleteLayer( $inCAM, $jobId, $layer );
	CamMatrix->CreateLayer( $inCAM, $jobId, $layer, "solder_mask", "positive", 1, $signalL, ( $signalL eq "c" ? "before" : "after" ) );

	#	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
	#	my @pointsLim = ();

	#	my $flexClearance = 2000;    # 2000?m from PCB profile
	#
	#	push( @pointsLim, { "x" => $lim{"xMin"} - $flexClearance / 1000, "y" => $lim{"yMin"} - $flexClearance / 1000 } );
	#	push( @pointsLim, { "x" => $lim{"xMin"} - $flexClearance / 1000, "y" => $lim{"yMax"} + $flexClearance / 1000 } );
	#	push( @pointsLim, { "x" => $lim{"xMax"} + $flexClearance / 1000, "y" => $lim{"yMax"} + $flexClearance / 1000 } );
	#	push( @pointsLim, { "x" => $lim{"xMax"} + $flexClearance / 1000, "y" => $lim{"yMin"} - $flexClearance / 1000 } );
	#
	#	CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsLim, 1, "positive" );
	#
	#	CamLayer->ClipAreaByProf( $inCAM, $layer, $flexClearance );
	#	CamLayer->WorkLayer( $inCAM, $layer );

	foreach my $bendArea (@bendAreas) {

		CamLayer->WorkLayer( $inCAM, $layer );

		my @pointsSurf = $bendArea->GetPoints();

		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1, "positive" );
		CamLayer->WorkLayer( $inCAM, $layer );

		# Round corners
		$inCAM->COM(
					 "sel_feat2outline",
					 "width"         => $overlap,
					 "location"      => "inner",
					 "offset"        => "0",
					 "polarity"      => "as_feature",
					 "keep_original" => "no",
					 "text2limit"    => "no"
		);
		CamLayer->Contourize( $inCAM, $layer, "x_or_y", "203200" );    # 203200 = max size of emptz space in InCAM which can be filled by surface

	}

	CamLayer->ClearLayers($inCAM);

	return $result;
}

sub UnmaskCoverlayMaskByBendArea {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $l         = shift;
	my $clearance = shift // 250;    # Default clearance of Cu from bend border is 250?m

	my $result = 1;

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	CamLayer->WorkLayer( $inCAM, $l );
	CamLayer->DeleteFeatures($inCAM);
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
	my @pointsLim = ();

	push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMin"} } );
	push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMax"} } );
	push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMax"} } );
	push( @pointsLim, { "x" => $lim{"xMax"}, "y" => $lim{"yMin"} } );
	push( @pointsLim, { "x" => $lim{"xMin"}, "y" => $lim{"yMin"} } );    # close polygon

	CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsLim, 1, "positive" );

	CamLayer->ClipAreaByProf( $inCAM, $l, 0 );
	CamLayer->WorkLayer( $inCAM, $l );

	foreach my $bendArea ( $parser->GetBendAreas() ) {

		CamLayer->WorkLayer( $inCAM, $l );

		my @points = $bendArea->GetPoints();

		#CamSymbolSurf->AddSurfaceSolidPattern( $inCAM, 1, 2000, 1 );
		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@points, 1, "negative" );
		CamSymbol->AddPolyline( $inCAM, \@points, "s" . ( 2 * $clearance ), "negative" );

	}

	CamLayer->WorkLayer( $inCAM, $l );
	CamLayer->Contourize( $inCAM, $l );

	CamLayer->ClearLayers($inCAM);

	return $result;
}

sub PrepareRoutCoverlay {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $step       = shift;
	my $sigLayer   = shift;
	my $pins       = shift;            # 0/1
	my $addRegPins = shift // $pins;

	my $coverlayOverlap = shift // 1000;    # Ovelrap of coverlay to rigid area
	my $routTool        = shift // 2000;    # 2000?m rout tool
	my $regPinSize      = shift // 1800;    # 1800?m or register pin hole
	my $pinRadius       = shift // 2000;    # Radius between PinString_SIDELINE1 and PinString_SIDELINE2

	my $result = 1;

	# coverlay mask layer must exist
	my $coverlayMaskL = "cvrl$sigLayer";
	die "Coverlay mask layer: $coverlayMaskL doesn't exist" unless ( CamHelper->LayerExists( $inCAM, $jobId, $coverlayMaskL ) );

	# put Cu only to rigid signal layer

	my $side;
	if ( $sigLayer eq "c" ) {
		$side = "top";
	}
	elsif ( $sigLayer eq "s" ) {
		$side = "bot";
	}
	else {
		# Rigid flex
		$side = StackupOperation->GetSideByLayer( $inCAM, $jobId, $sigLayer );
	}

	# Build coverlay rout name
	my $routLName = "fcvrl";
	$routLName .= $side eq "top" ? "c" : "s";

	CamMatrix->DeleteLayer( $inCAM, $jobId, $routLName );

	CamMatrix->CreateLayer( $inCAM, $jobId, $routLName, "rout", "positive", 1 );
	CamMatrix->SetNCLayerStartEnd( $inCAM, $jobId, $routLName, $coverlayMaskL, $coverlayMaskL );
	CamMatrix->SetLayerDirection( $inCAM, $jobId, $routLName, ( $side eq "top" ? "top_to_bottom" : "bottom_to_top" ) );

	my $pinParser;

	if ( $pins || $addRegPins ) {
		$pinParser = CoverlayPinParser->new( $inCAM, $jobId, $step, "CCW", 2 * $coverlayOverlap );
		my $errMess = "";
		die $errMess unless ( $pinParser->CheckBendArea( \$errMess ) );
	}

	if ($pins) {

		# Prepare bend area mask

		CamLayer->WorkLayer( $inCAM, $routLName );

		my $draw = RoutDrawing->new( $inCAM, $jobId, $step, $routLName );

		foreach my $bendArea ( $pinParser->GetBendAreas() ) {

			my @feats = $bendArea->GetFeatures();

			my $startFeat;
			for ( my $i = scalar(@feats) - 1 ; $i >= 0 ; $i-- ) {

				if (    $feats[$i]->{"att"}->{".string"} eq EnumsPins->PinString_ENDLINEIN
					 || $feats[$i]->{"att"}->{".string"} eq EnumsPins->PinString_ENDLINEOUT )
				{

					if ( !defined $startFeat ) {
						$startFeat = ( $i + 1 > scalar(@feats) - 1 ) ? $feats[0] : $feats[ $i + 1 ];
					}

					splice @feats, $i, 1;
				}
			}

			@feats =
			  grep { $_->{"att"}->{".string"} ne EnumsPins->PinString_ENDLINEIN || $_->{"att"}->{".string"} ne EnumsPins->PinString_ENDLINEOUT }
			  @feats;

			$draw->DrawRoute( \@feats, $routTool, "right", $startFeat, undef, [".string"] );

		}

		if ( $pinRadius > 0 ) {

			my $f = FeatureFilter->new( $inCAM, $jobId, $routLName );

			$f->AddIncludeAtt( ".string", EnumsPins->PinString_SIDELINE1 );
			$f->AddIncludeAtt( ".string", EnumsPins->PinString_SIDELINE2 );
			$f->SetIncludeAttrCond( FilterEnums->Logic_OR );

			if ( $f->Select() ) {
				$inCAM->COM(
							 "change_bundle_corners",
							 "corner_type" => "round",
							 "max_ang"     => "180",
							 "radius"      => $pinRadius
				);
			}

		}

	}

	if ($addRegPins) {

		my @pins = $pinParser->GetRegisterPads();

		CamSymbol->ResetCurAttributes($inCAM);
		my $REGISTERPINSTRING = "register_pin";

		# Add register pad
		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", $REGISTERPINSTRING );

		foreach my $pin (@pins) {
			CamSymbol->AddPad( $inCAM, "r$regPinSize", { "x" => $pin->{"x1"}, "y" => $pin->{"y1"} } );
		}
	}

	CamLayer->ClearLayers($inCAM);

	return $routLName;
}

# Check if mpanel contain requsted schema by customer
sub PrepareRoutPrepreg {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $prepregL  = shift;
	my $clearance = shift;            # Default clearance of prepreg from rigin/flex transition
	my $refLayer  = shift;            # bend / coverlaypins
	my $routTool  = shift // 2000;    # 2000?m rout tool
	my $pinRadius = shift // 2000;    # Radius between PinString_SIDELINE1 and PinString_SIDELINE2

	die "Clearance is not defined"       unless ( defined $clearance );
	die "Reference layer is not defined" unless ( defined $refLayer );

	my $result = 1;

	my $bendParser;

	if ( $refLayer eq "cvrlpins" ) {

		$bendParser = CoverlayPinParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW, $clearance );

	}
	elsif ( $refLayer eq "bend" ) {

		$bendParser = BendAreaParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW, $clearance );
	}

	my $errMess = "";
	die "Error during parsing layer: $refLayer. Detail" if ( !$bendParser->CheckBendArea( \$errMess ) );

	my $bendAreaL = "bend";
	unless ( CamHelper->LayerExists( $inCAM, $jobId, $bendAreaL ) ) {
		die "Benda area layer: $bendAreaL doesn't exists";
	}

	CamMatrix->DeleteLayer( $inCAM, $jobId, $prepregL );
	CamMatrix->CreateLayer( $inCAM, $jobId, $prepregL, "rout", "positive", 1 );
	CamMatrix->SetNCLayerStartEnd( $inCAM, $jobId, $prepregL, "bend", "bend" );

	foreach my $bendArea ( $bendParser->GetBendAreas() ) {

		my $lTmp = GeneralHelper->GetGUID();
		CamMatrix->CreateLayer( $inCAM, $jobId, $lTmp, "rout", "positive", 0 );
		CamLayer->WorkLayer( $inCAM, $lTmp );

		my $draw = RoutDrawing->new( $inCAM, $jobId, $step, $lTmp );
		my @feats = $bendArea->GetFeatures();
		my $routStart;

		# split arbitrary line in middle and put htere route start (to avoid cut pcb by tool)
		for ( my $i = 0 ; $i < scalar(@feats) ; $i++ ) {

			if ( $feats[$i]->{"type"} eq "L" && !defined $feats[$i]->{"att"}->{"transition_zone"} ) {

				my $midX = ( $feats[$i]->{"x1"} + $feats[$i]->{"x2"} ) / 2;
				my $midY = ( $feats[$i]->{"y1"} + $feats[$i]->{"y2"} ) / 2;

				my %featInfo;

				$featInfo{"id"}   = GeneralHelper->GetNumUID();
				$featInfo{"type"} = $feats[$i]->{"type"};

				$featInfo{"x1"} = $midX;
				$featInfo{"y1"} = $midY;
				$featInfo{"x2"} = $feats[$i]->{"x2"};
				$featInfo{"y2"} = $feats[$i]->{"y2"};

				$feats[$i]->{"x2"} = $midX;
				$feats[$i]->{"y2"} = $midY;

				splice @feats, $i + 1, 0, \%featInfo;

				$routStart = $feats[ $i + 1 ];
				last;
			}
		}

		$draw->DrawRoute( \@feats, $routTool, "right", $routStart, undef, [".string"] );

		if ( $pinRadius > 0 ) {

			my $f = FeatureFilter->new( $inCAM, $jobId, $lTmp );

			$f->AddIncludeAtt( ".string", EnumsPins->PinString_SIDELINE1 );
			$f->AddIncludeAtt( ".string", EnumsPins->PinString_SIDELINE2 );
			$f->SetIncludeAttrCond( FilterEnums->Logic_OR );

			if ( $f->Select() ) {
				$inCAM->COM(
							 "change_bundle_corners",
							 "corner_type" => "round",
							 "max_ang"     => "180",
							 "radius"      => $pinRadius
				);
			}
		}

		# Decide if area is small and milling of whole area is needed
		my @areaPoints = $bendArea->GetPoints();
		my $area       = PolygonPoints->GetPolygonArea( \@areaPoints );
		my @limits     = PolygonPoints->GetPolygonLim( \@areaPoints );

		# 400mm2
		if ( $area < 1000 || abs( $limits[0] - $limits[2] ) < 20 || abs( $limits[1] - $limits[3] ) < 20 ) {

			$inCAM->COM("sel_all_feat");
			$inCAM->COM("chain_list_reset");

			$inCAM->COM( "chain_list_add", "chain"  => 1 );
			$inCAM->COM( "chain_cancel",   "layer"  => $lTmp, "keep_surface" => "no" );
			$inCAM->COM( "sel_change_sym", "symbol" => "r10" );                           # r0 is not working for countourize, thats way r10
			CamLayer->Contourize( $inCAM, $lTmp, "x_or_y", "203200" );    # 203200 = max size of emptz space in InCAM which can be filled by surface
			CamLayer->WorkLayer( $inCAM, $lTmp );
			$inCAM->COM(
						 'chain_add',
						 "layer" => $lTmp,
						 "size"  => $routTool / 1000,
						 "comp"  => "right"
			);

			$inCAM->COM("sel_all_feat");

			$inCAM->COM(
						 "chain_pocket",
						 "layer"      => $lTmp,
						 "mode"       => "concentric",
						 "size"       => $routTool / 1000,
						 "feed"       => "0",
						 "overlap"    => $routTool / 1000 / 3,
						 "pocket_dir" => "standard"
			);
		}

		CamLayer->CopySelOtherLayer( $inCAM, [$prepregL] );
		CamLayer->WorkLayer( $inCAM, $prepregL );
		CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );
	}

	CamLayer->ClearLayers($inCAM);

	return $result;
}

sub PrepareRoutTransitionZone {
	my $self              = shift;
	my $inCAM             = shift;
	my $jobId             = shift;
	my $step              = shift;
	my $routPart          = shift;            # 1 = core depth rout, 2 = final depth rout
	my $toolSize          = shift;
	my $toolMagazineInfo  = shift;
	my $toolComp          = shift;            # right / left / none
	my $recreate          = shift // 1;       # recreate rout layer with used name
	my $routOverlapPart2  = shift // 0.25;    # 0,25mm # define depth  overlap of rout tool in transition zone
	my $extendZone        = shift // 1.0;     # 1.0mm transition rout slots will be exteneded on both ends
	my $defDepthRoutPart1 = shift // 0.33;    # Default depth for first routing (part 1)
	my $minMatRestPart1   = shift // 0.17;    # 170?m is minimal material thickness after routing
	my $minMatRestPart2   = shift // 0.08;    # 80?m is minimal material thickness after routing

	my $minRoutOverlap = 0.12;                # minimal overlap of rout 100

	die "Rout part is not defined" if ( $routPart != 1 && $routPart != 2 );
	die "Default depth of rout part 1 is not defined" if ( !defined $defDepthRoutPart1 );
	die "Rout overlap has to be at least ${minRoutOverlap}mm" if ( $routOverlapPart2 < $minRoutOverlap );

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	my %result = ( "result" => 1, "routLayers" => [], "errMess" => "" );
	my @routLayers = ();

	# Rout tool info

	my @packages = StackupOperation->GetJoinedFlexRigidProducts( $inCAM, $jobId );

	my $top2BotOrder = "";
	my $bot2TopOrder = "";

	# Take highest number of layer type plus 1
	if ( !$recreate ) {

		my @t2b = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
		my $maxt2b = max( map { ( $_->{"gROWname"} =~ /\w(\d*)/ )[0] } @t2b );

		if ( defined $maxt2b && $maxt2b > 0 ) {
			$top2BotOrder = $maxt2b + 1;
		}
		elsif (@t2b) {

			$top2BotOrder = 1;
		}

		my @b2t = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
		my $maxb2t = max( map { ( $_->{"gROWname"} =~ /\w(\d*)/ )[0] } @b2t );

		if ( defined $maxb2t && $maxb2t > 0 ) {
			$bot2TopOrder = $maxb2t + 1;
		}
		elsif (@b2t) {

			$bot2TopOrder = 1;
		}
	}

	foreach my $joinPackgs (@packages) {

		my $topProduct = $joinPackgs->{"pTop"};
		my $botProduct = $joinPackgs->{"pBot"};

		my $routDir;
		my $routStart;
		my $routEnd;
		my $routName;
		my $packageThick;

		if ( $routPart == 1 ) {

			if ( $joinPackgs->{"pTopCoreType"} eq StackEnums->CoreType_RIGID ) {

				$routName     = "jfzs" . $bot2TopOrder;
				$routDir      = "bottom_to_top";
				$routStart    = $joinPackgs->{"pTop"}->GetTopCopperLayer();
				$routEnd      = $joinPackgs->{"pTop"}->GetBotCopperLayer();
				$packageThick = $joinPackgs->{"pTop"}->GetThick();

				$bot2TopOrder++;

			}
			else {

				$routName     = "jfzc" . $top2BotOrder;
				$routDir      = "top_to_bottom";
				$routStart    = $joinPackgs->{"pBot"}->GetTopCopperLayer();
				$routEnd      = $joinPackgs->{"pBot"}->GetBotCopperLayer();
				$packageThick = $joinPackgs->{"pBot"}->GetThick();

				$top2BotOrder++;
			}

		}
		else {

			if ( $joinPackgs->{"pTopCoreType"} eq StackEnums->CoreType_RIGID ) {

				$routName     = "fzc" . $top2BotOrder;
				$routDir      = "top_to_bottom";
				$routStart    = $joinPackgs->{"pTop"}->GetTopCopperLayer();
				$routEnd      = $joinPackgs->{"pTop"}->GetBotCopperLayer();
				$packageThick = $joinPackgs->{"pTop"}->GetThick();

				$top2BotOrder++;

			}
			else {

				$routName     = "fzs" . $bot2TopOrder;
				$routDir      = "bottom_to_top";
				$routStart    = $joinPackgs->{"pBot"}->GetTopCopperLayer();
				$routEnd      = $joinPackgs->{"pBot"}->GetBotCopperLayer();
				$packageThick = $joinPackgs->{"pBot"}->GetThick();

				$bot2TopOrder++;
			}
		}

		if ( $recreate && CamHelper->LayerExists( $inCAM, $jobId, $routName ) ) {
			CamMatrix->DeleteLayer( $inCAM, $jobId, $routName );
			CamMatrix->CreateLayer( $inCAM, $jobId, $routName, "rout", "positive", 1 );
		}

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $routName ) ) {
			CamMatrix->CreateLayer( $inCAM, $jobId, $routName, "rout", "positive", 1 );
		}

		CamMatrix->SetNCLayerStartEnd( $inCAM, $jobId, $routName, $routStart, $routEnd );
		CamMatrix->SetLayerDirection( $inCAM, $jobId, $routName, $routDir );

		# Draw transition features
		CamLayer->WorkLayer( $inCAM, $routName );
		my $featIdx = 0;
		foreach my $transZone ( map { $_->GetTransitionZones() } $parser->GetBendAreas() ) {

			# transition
			my %startP = $transZone->GetStartPoint();
			my %endP   = $transZone->GetEndPoint();
			my $feat   = $transZone->GetFeature();

			CamSymbol->AddCurAttribute( $inCAM, $jobId, "transition_zone" );

			if ( $feat->{"type"} eq "L" ) {

				CamSymbol->AddLine( $inCAM, \%startP, \%endP, "r200" );

			}
			elsif ( $feat->{"type"} eq "A" ) {

				CamSymbolArc->AddArcStartCenterEnd( $inCAM, \%startP, { "x" => $feat->{"xmid"}, "y" => $feat->{"ymid"} },
													\%endP, $feat->{"newDir"}, "r200" );
			}

			CamSymbol->ResetCurAttributes( $inCAM, $jobId );
			$featIdx++;

			if ( CamFilter->SelectByFeatureIndexes( $inCAM, $jobId, [$featIdx] ) ) {

				# Add chain
				$inCAM->COM(
							 'chain_add',
							 "layer" => $routName,
							 "chain" => $featIdx,
							 "size"  => $toolSize,
							 "comp"  => $toolComp,
							 "first" => 0,
				);
			}
			else {
				die "No rout line selected";
			}

		}

		$inCAM->COM("chain_list_reset");
		$inCAM->COM( "chain_list_add", "chain" => join( "\;", ( 1 .. $featIdx ) ) );
		$inCAM->COM( "chain_merge", "layer" => $routName );

		if ($extendZone) {
			$inCAM->COM( "sel_extend_slots", "mode" => "ext_by", "size" => ( 2 * $extendZone * 1000 ), "from" => "center" );
		}

		# Set tool magazine info
		my @DTMTools = CamDTM->GetDTMTools( $inCAM, $jobId, $step, $routName );

		my $depth = 0;
		if ( $routPart == 1 ) {

			$depth = $defDepthRoutPart1;
		}
		elsif ( $routPart == 2 ) {
			$depth = $packageThick / 1000 - $defDepthRoutPart1 + $routOverlapPart2;
		}

		if ( $routPart == 1 ) {

			# Check material rest
			if ( ( $packageThick / 1000 - $depth ) < $minMatRestPart1 ) {

				my $matRest = sprintf( "%.2f", $packageThick / 1000 - $depth );
				my $computed = $packageThick / 1000 - $minMatRestPart1;

				$result{"result"} = 0;
				$result{"errMess"} =
				    "Too large rout depth ("
				  . sprintf( "%.2f", $depth ) . "mm). "
				  . "Rest of material thickness after routing would be: $matRest mm. Minimal allowed material rest is: ${minMatRestPart1}mm. "
				  . "Maximal default depth should be: ${computed}mm (now is: ${defDepthRoutPart1}mm).";
			}

			# Check minimal depth
			if ( $depth < $routOverlapPart2 / 2 ) {

				$result{"result"} = 0;
				$result{"errMess"} =
				  "Too small rout depth: ${depth}mm. Routed material thickness is too thin (" . sprintf( "%.2f", $packageThick / 1000 ) . "mm)";
			}
		}

		if ( $routPart == 2 ) {

			# Check too large depth
			my @noFlows = @{ $joinPackgs->{"layersNoflow"} };
			my $noFlowThick = 0;
			$noFlowThick += $_->GetThick() foreach (@noFlows);
		
			my $matThickness = ( $packageThick / 1000 + $noFlowThick / 1000 );

			if ( $depth > ( $matThickness - $minMatRestPart2 ) ) {

				my $newToolDepth = $matThickness - $minMatRestPart2;
				my $suggestedOverlap = $newToolDepth - ( $packageThick / 1000 - $defDepthRoutPart1 );

				$result{"result"} = 0;
				$result{"errMess"} =
				    "Too deep rout depth. Rigid material thickness is thinnner ("
				  . sprintf( "%.2f", $matThickness )
				  . "mm - reserve depth: "
				  . sprintf( "%.2f", $minMatRestPart2 )
				  . "mm to prevent rout through flex core) than rout depth (${depth}mm). "
				  . "Try to set rout overlap on value: ${suggestedOverlap}mm";
			}

		}

		$DTMTools[0]->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } = sprintf( "%.2f", $depth );
		$DTMTools[0]->{"userColumns"}->{ EnumsDrill->DTMclmn_MAGINFO } = $toolMagazineInfo if ( defined $toolMagazineInfo );

		CamDTM->SetDTMTools( $inCAM, $jobId, $step, $routName, \@DTMTools );

		push( @{ $result{"routLayers"} }, $routName );
	}

	return %result;

}

sub PrepareCoverlayTemplate {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $routName = shift // "fsoldc";
	my $toolSize = shift // 2;          # 2mm tool size
	my $diameter = shift // 9;          # 9mm size of final routed hole

	my $pinParser = CoverlayPinParser->new( $inCAM, $jobId, $step, "CCW" );
	my $errMess = "";
	die $errMess unless ( $pinParser->CheckBendArea( \$errMess ) );

	# Rout tool info

	if ( CamHelper->LayerExists( $inCAM, $jobId, $routName ) ) {
		CamMatrix->DeleteLayer( $inCAM, $jobId, $routName );
		CamMatrix->CreateLayer( $inCAM, $jobId, $routName, "rout", "positive", 1 );
	}

	unless ( CamHelper->LayerExists( $inCAM, $jobId, $routName ) ) {
		CamMatrix->CreateLayer( $inCAM, $jobId, $routName, "rout", "positive", 1 );
	}

	CamMatrix->SetNCLayerStartEnd( $inCAM, $jobId, $routName, "cvrlpins", "cvrlpins" );

	# Draw transition features
	CamLayer->WorkLayer( $inCAM, $routName );

	my $lTmp = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $lTmp, "rout", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $lTmp );

	foreach my $reg ( $pinParser->GetRegisterPads() ) {

		CamSymbol->AddPad( $inCAM, "r" . ( $diameter * 1000 ), { "x" => $reg->{"x1"}, "y" => $reg->{"y1"} } );
	}

	CamLayer->Contourize( $inCAM, $lTmp );
	CamLayer->WorkLayer( $inCAM, $lTmp );

	$inCAM->COM("sel_all_feat");
	$inCAM->COM("chain_list_reset");

	$inCAM->COM(
				 'chain_add',
				 "layer" => $lTmp,
				 "size"  => $toolSize,
				 "comp"  => "left"
	);

	$inCAM->COM("sel_all_feat");

	$inCAM->COM(
				 "chain_pocket",
				 "layer"      => $lTmp,
				 "mode"       => "concentric",
				 "size"       => $toolSize,
				 "feed"       => "0",
				 "overlap"    => $toolSize / 4,
				 "pocket_dir" => "standard"
	);
	CamLayer->CopySelOtherLayer( $inCAM, [$routName] );
	CamLayer->WorkLayer( $inCAM, $routName );
	CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );

	CamLayer->ClearLayers($inCAM);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::FlexiLayers::FlexiBendArea';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d251561";

	my $mess = "";

	my $result = FlexiBendArea->PrepareCoverlayTemplate( $inCAM, $jobId, "o+1" );

	print STDERR "Result is: $result, error message: $mess\n";

}

1;
