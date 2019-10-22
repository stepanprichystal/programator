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
	my $clearance = shift // 250;    # Default clearance of Cu from bend border is 250µm
	my $lCu       = shift;           # ref where array of affected signal layer name will be stored

	my $result = 1;

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	my @bendAreas = $parser->GetBendAreas();

	# put Cu only to rigid signal layer
	my @layers = ();

	my @lamPackages = StackupOperation->GetJoinedFlexRigidPackages($jobId);

	foreach my $lamPckg (@lamPackages) {

		if (    $lamPckg->{"packageTop"}->{"coreType"} eq EnumsStack->CoreType_FLEX
			 && $lamPckg->{"packageBot"}->{"coreType"} eq EnumsStack->CoreType_RIGID )
		{

			# find first Cu layer in BOT package
			my $lName = undef;

			for ( my $i = 0 ; $i < scalar( @{ $lamPckg->{"packageBot"}->{"layers"} } ) ; $i++ ) {
				if ( $lamPckg->{"packageBot"}->{"layers"}->[$i]->GetType() eq EnumsStack->MaterialType_COPPER ) {
					$lName = $lamPckg->{"packageBot"}->{"layers"}->[$i]->GetCopperName();
					last;
				}
			}

			die "Not a inner copper layer: $lName" if ( $lName !~ /^v\d+$/ );
			push( @layers, [ $lName, CamMatrix->GetLayerPolarity( $inCAM, $jobId, $lName ) ] );

		}
		elsif (    $lamPckg->{"packageTop"}->{"coreType"} eq EnumsStack->CoreType_RIGID
				&& $lamPckg->{"packageBot"}->{"coreType"} eq EnumsStack->CoreType_FLEX )
		{

			# find first Cu layer in TOP package
			my $lName = undef;

			for ( my $i = scalar( @{ $lamPckg->{"packageTop"}->{"layers"} } ) - 1 ; $i >= 0 ; $i-- ) {
				if ( $lamPckg->{"packageTop"}->{"layers"}->[$i]->GetType() eq EnumsStack->MaterialType_COPPER ) {
					$lName = $lamPckg->{"packageTop"}->{"layers"}->[$i]->GetCopperName();
					last;
				}
			}

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

				my @points = map { { "x" => $_->[0], "y" => $_->[1] } } $bendArea->GetPoints();
				my @pointsSurf = @points[ 0 .. scalar(@points) - 2 ];

				#CamSymbolSurf->AddSurfaceSolidPattern( $inCAM, 1, 2000, 1 );
				CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1, $l->[1] );
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

		my @points = map { { "x" => $_->[0], "y" => $_->[1] } } $bendArea->GetPoints();
		my @pointsSurf = @points[ 0 .. scalar(@points) - 2 ];

		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1 );
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
	my $overlap = shift // 400;    # Overlap of flexible mask torigid part

	my $result = 1;

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	my @bendAreas = $parser->GetBendAreas();

	CamHelper->SetStep( $inCAM, $step );

	my $signalL = "c";
	$signalL = "s" if ( $layer =~ /s/ && CamHelper->LayerExists( $inCAM, $jobId, $signalL ) );

	CamMatrix->DeleteLayer( $inCAM, $jobId, $layer );
	CamMatrix->CreateLayer( $inCAM, $jobId, $layer, "solder_mask", "positive", 1, $signalL, ( $signalL eq "c" ? "before" : "after" ) );

	CamLayer->WorkLayer( $inCAM, $layer );

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
	my @pointsLim = ();

	my $flexClearance = 2000;    # 2000µm from PCB profile

	push( @pointsLim, { "x" => $lim{"xMin"} - $flexClearance / 1000, "y" => $lim{"yMin"} - $flexClearance / 1000 } );
	push( @pointsLim, { "x" => $lim{"xMin"} - $flexClearance / 1000, "y" => $lim{"yMax"} + $flexClearance / 1000 } );
	push( @pointsLim, { "x" => $lim{"xMax"} + $flexClearance / 1000, "y" => $lim{"yMax"} + $flexClearance / 1000 } );
	push( @pointsLim, { "x" => $lim{"xMax"} + $flexClearance / 1000, "y" => $lim{"yMin"} - $flexClearance / 1000 } );

	CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsLim, 1, "positive" );

	CamLayer->ClipAreaByProf( $inCAM, $layer, $flexClearance );
	CamLayer->WorkLayer( $inCAM, $layer );

	foreach my $bendArea (@bendAreas) {

		my @points = map { { "x" => $_->[0], "y" => $_->[1] } } $bendArea->GetPoints();
		my @pointsSurf = @points[ 0 .. scalar(@points) - 2 ];

		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1, "negative" );
		CamSymbol->AddPolyline( $inCAM, \@points, "r" . ( 2 * $overlap ), "negative" );
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
	my $clearance = shift // 250;    # Default clearance of Cu from bend border is 250µm

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

	CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsLim, 1, "positive" );

	CamLayer->ClipAreaByProf( $inCAM, $l, 0 );
	CamLayer->WorkLayer( $inCAM, $l );

	foreach my $bendArea ( $parser->GetBendAreas() ) {

		CamLayer->WorkLayer( $inCAM, $l );

		my @points = map { { "x" => $_->[0], "y" => $_->[1] } } $bendArea->GetPoints();
		my @pointsSurf = @points[ 0 .. scalar(@points) - 2 ];

		#CamSymbolSurf->AddSurfaceSolidPattern( $inCAM, 1, 2000, 1 );
		CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsSurf, 1, "negative" );
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

	my $coverlayOverlap = shift // 500;     # Ovelrap of coverlay to rigid area
	my $routTool        = shift // 2000;    # 2000µm rout tool
	my $regPinSize      = shift // 1800;    # 1800µm or register pin hole
	my $pinRadius       = shift // 2000;    # Radius between PinString_SIDELINE1 and PinString_SIDELINE2

	my $result = 1;

	# coverlay mask layer must exist
	my $coverlayMaskL = "coverlay$sigLayer";
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
		$side = StackupOperation->GetSideByLayer( $jobId, $sigLayer );
	}

	# Build coverlay rout name
	my $routLName = "fcoverlay";
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

				if ( $feats[$i]->{"att"}->{".string"} eq EnumsPins->PinString_ENDLINE ) {

					if ( !defined $startFeat ) {
						$startFeat = ( $i + 1 > scalar(@feats) - 1 ) ? $feats[0] : $feats[ $i + 1 ];
					}

					splice @feats, $i, 1;
				}
			}

			@feats = grep { $_->{"att"}->{".string"} ne EnumsPins->PinString_ENDLINE } @feats;

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
	my $routTool  = shift // 2000;    # 2000µm rout tool
	my $pinRadius = shift // 2000;    # Radius between PinString_SIDELINE1 and PinString_SIDELINE2

	die "Clearance is not defined"       unless ( defined $clearance );
	die "Reference layer is not defined" unless ( defined $refLayer );

	my $result = 1;

	my $bendParser;

	if ( $refLayer eq "coverlaypins" ) {

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
			$inCAM->COM( "sel_change_sym", "symbol" => "r0" );
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
	my $roolOverlap       = shift // 0.25;    # 0,25mm # define depth  overlap of rout tool in transition zone
	my $extendZone        = shift // 0.5;     # 0,5mm transition rout slots will be exteneded on both ends
	my $defDepthRoutPart1 = shift // 0.23;    # Default depth for first routing (part 1). If package is to thin, rout to half of package
	my $minMatRest        = shift // 0.15;    # 150µm is minimal material thickness after routing

	die "Rout part is not defined" if ( $routPart != 1 && $routPart != 2 );

	my $parser = BendAreaParser->new( $inCAM, $jobId, $step, PolyEnums->Dir_CW );
	my $errMess = "";
	die $errMess unless ( $parser->CheckBendArea( \$errMess ) );

	my @routLayers = ();

	# Rout tool info

	my @packages = StackupOperation->GetJoinedFlexRigidPackages($jobId);

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

		my $topPckgs = $joinPackgs->{"packageTop"};
		my $botPckgs = $joinPackgs->{"packageBot"};

		my $routDir;
		my $routStart;
		my $routEnd;
		my $routName;
		my $packageThick;

		if ( $routPart == 1 ) {

			if ( $topPckgs->{"coreType"} eq StackEnums->CoreType_RIGID ) {

				$routName  = "jfzs" . $bot2TopOrder;
				$routDir   = "bottom_to_top";
				$routStart = $topPckgs->{"topCopperName"};
				$routEnd   = $topPckgs->{"botCopperName"};
				$packageThick += $_->GetThick() foreach ( @{ $topPckgs->{"layers"} } );

				$bot2TopOrder++;

			}
			else {

				$routName  = "jfzc" . $top2BotOrder;
				$routDir   = "top_to_bottom";
				$routStart = $botPckgs->{"topCopperName"};
				$routEnd   = $botPckgs->{"botCopperName"};
				$packageThick += $_->GetThick() foreach ( @{ $botPckgs->{"layers"} } );

				$top2BotOrder++;
			}
		}
		else {

			if ( $topPckgs->{"coreType"} eq StackEnums->CoreType_RIGID ) {

				$routName  = "fzc" . $top2BotOrder;
				$routDir   = "top_to_bottom";
				$routStart = $topPckgs->{"topCopperName"};
				$routEnd   = $topPckgs->{"botCopperName"};
				$packageThick += $_->GetThick() foreach ( @{ $topPckgs->{"layers"} } );

				$top2BotOrder++;

			}
			else {

				$routName  = "fzs" . $bot2TopOrder;
				$routDir   = "bottom_to_top";
				$routStart = $botPckgs->{"topCopperName"};
				$routEnd   = $botPckgs->{"botCopperName"};
				$packageThick += $_->GetThick() foreach ( @{ $botPckgs->{"layers"} } );

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

			CamSymbol->AddCurAttribute($inCAM, $jobId, "transition_zone");
			CamSymbol->AddLine( $inCAM, \%startP, \%endP, "r200" );
			CamSymbol->ResetCurAttributes($inCAM, $jobId);
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

		my $depth = ( $packageThick / 2 ) / 1000 + $roolOverlap / 2;    # default depth is to half of package thickness + overlap

		# if half of packkage thickness is thicker than default rout from bot + overlap/2, ude default rout depth
		# - rout part 1: 0.35mm (including overlap)
		# - rout part 2: package thickness - 0.35mm
		if ( $defDepthRoutPart1 < $packageThick / 1000 / 2 ) {

			if ( $routPart == 1 ) {

				$depth = $defDepthRoutPart1 + $roolOverlap / 2;
			}
			elsif ( $routPart == 2 ) {
				$depth = $packageThick / 1000 - $defDepthRoutPart1 + $roolOverlap / 2;
			}
		}

		$depth = sprintf( "%.2f", $depth );

		if ( $depth > $packageThick - $minMatRest ) {

			my $matRest = $packageThick - $depth;

			die "Too large routh depth ($depth mm). "
			  . "Rest of material thickness after routing would be: $matRest mm. Minimal allowed material rest is: $minMatRest mm.";

		}

		$DTMTools[0]->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } = $depth;
		$DTMTools[0]->{"userColumns"}->{ EnumsDrill->DTMclmn_MAGINFO } = $toolMagazineInfo if ( defined $toolMagazineInfo );

		CamDTM->SetDTMTools( $inCAM, $jobId, $step, $routName, \@DTMTools );

		push( @routLayers, $routName );
	}

	return @routLayers;

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

	CamMatrix->SetNCLayerStartEnd( $inCAM, $jobId, $routName, "coverlaypins", "coverlaypins" );

	# Draw transition features
	CamLayer->WorkLayer( $inCAM, $routName );

	my $lTmp = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $lTmp, "rout", "positive", 0 );
	CamLayer->WorkLayer( $inCAM, $lTmp );

 
	foreach my $reg ( $pinParser->GetRegisterPads() ) {
		
		CamSymbol->AddPad($inCAM, "r" . ( $diameter * 1000 ), { "x" => $reg->{"x1"}, "y" => $reg->{"y1"} } );
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
				 "overlap"    => $toolSize/4,
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
