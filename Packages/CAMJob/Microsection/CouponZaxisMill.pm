
#-------------------------------------------------------------------------------------------#
# Description: Paclage which generate zaxis coupons
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Microsection::CouponZaxisMill;

#3th party library
use strict;
use warnings;
use JSON;
use List::Util qw[max min first];
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfFill';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePolyline';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSolidPattern';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSymbolPattern';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceDotPattern';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => 'DrawEnums';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamJob';
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

# Measurement typy

use constant CPNTYPE_MATERIALRESTVA  => "CouponType_materialRestValue";
use constant CPNTYPE_DEPTHMILLINGVAL => "CouponType_depthMillingValue";

# General step settings, coupon steps, coupon count

my $DEF_STEP_SIZE     = 50;    # 50µm difference between depth of each zaxis coupon
my $DEF_STEP_PLUSCNT  = 2;     # three coupons with greater depth than computed (increased by step size)
my $DEF_STEP_MINUSCNT = 2;     # three coupons with smaller depth than computed (decreased by step size)

# Coupon step dimension

my $CPN_W            = 8000;
my $CPN_HEADER_H     = 5000;    # Where coupon ID is placed
my $CPN_SEC_HEADER_H = 3000;    # Where coupon segment measure value placed
my $CPN_SEC_ROUT_W   = 9500;    # Rout area width
my $CPN_SEC_ROUT_H   = 9500;    #  Rout area height

# Coupon text settings
my $magicConstant = 0.00328;                 # InCAM need text width converted with this constant , took keep required width in µm
my $CPN_ID_SIZE   = 2300;                    # Coupon Id text size
my $CPN_ID_WIDTH  = 300 * $magicConstant;    # Coupon Id text width
my $CPN_VAL_SIZE  = 1500;                    # Coupon value text size
my $CPN_VAL_WIDTH = 200 * $magicConstant;    # Coupon value text width

# Depth Rout settings
my $DEPTH_ROUT_TOOL         = 2000;
my $DEPTH_ROUT_TOOL_OVERLAP = 1200;

# Rout bridges settings
my $BRIDGES_CNT_W     = 1;
my $BRIDGES_CNT_H     = 0;
my $BRIDGES_WIDTH     = 300;                 # bridges width in µm
my $OUTLINE_ROUT_TOOL = 1000;

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"step"} = "panel";

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	if ( $self->{"layerCnt"} > 2 ) {

		$self->{"stackup"} = Stackup->new( $self->{"inCAM"}, $self->{"jobId"} );
	}

	# Init holes types and compute holes positions
	#$self->{"holes"}    = [ $self->GetHoles(1) ];
	#$self->{"holesPos"} = [ $self->__GetLayoutHoles() ];
	return $self;
}

sub CheckSpecifications {
	my $self    = shift;
	my $errMess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	my @depthLayers = CamDrilling->GetNCLayersByTypes(
													   $inCAM, $jobId,
													   [
														  EnumsGeneral->LAYERTYPE_nplt_bstiffcMill, EnumsGeneral->LAYERTYPE_nplt_bstiffcMill,
														  EnumsGeneral->LAYERTYPE_nplt_bMillTop,    EnumsGeneral->LAYERTYPE_nplt_bMillBot,
													   ]
	);

	#CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@stiffL );

	my @childSteps = CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );

	foreach my $l (@depthLayers) {

		# 1) Check if there is request for depth coupon
		my $cpnRequired = 0;
		foreach my $s (@childSteps) {
			my %pnlLAtt = CamAttributes->GetLayerAttr( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"} );
			if ( defined $pnlLAtt{"depth_rout_calibration_coupon"} && $pnlLAtt{"depth_rout_calibration_coupon"} eq "yes" ) {
				$cpnRequired = 1;
				last;
			}
		}

		next unless ($cpnRequired);

		# 2) Check all total pcb thickness value per layer, there should be one if coupon request
		my @allTotPCBThick = ();

		foreach my $s (@childSteps) {

			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"}, 0 );
			next if ( $hist{"total"} == 0 );

			my %att = CamAttributes->GetLayerAttr( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"} );

			my $pcbThick = $att{"final_pcb_thickness"};

			if ( defined $pcbThick && $pcbThick ne "" && $pcbThick > 0 ) {

				push( @allTotPCBThick, $pcbThick );
			}
		}

		if ( scalar( uniq(@allTotPCBThick) ) > 1 ) {

			$result = 0;
			$$errMess .= "Only one PCB thickness is alowed for specific NC layer (through all steps) if zaxis coupon is required";

			return $result;
		}

		# 3) Check if all tools have same depth in one layer
		my @allToolDepths = ();    # check all depths per layer, there should be one if coupon request

		foreach my $s (@childSteps) {

			my $dtm = UniDTM->new( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"}, 0, 0, 0 );

			my @depth = map { $_->GetDepth() } grep { !$_->GetSpecial() && $_->GetDepth() } $dtm->GetUniqueTools();

			push( @allToolDepths, @depth ) if ( scalar(@depth) );

		}

		if ( scalar( uniq(@allToolDepths) ) > 1 ) {

			$result = 0;
			$$errMess .= "Only one tool depth is alowed for specific NC layer (through all steps) if zaxis coupon is required";

			return $result;
		}
	}

	return $result;
}

# Return array of all depth routing which sould be measured
# Request for measure is indicated by layer attribute: depth_rout_calibration_coupon
# Each array item contains:
# - layer: NC layer
# - type: CPNTYPE_MATERIALRESTVA/CPNTYPE_DEPTHMILLINGVAL
# - toolDepth: real tool depth    [um]
# - side: which side is PCB routed from
# - measureValue: value which has to be measured on final PCB
sub GetAllSpecifications {
	my $self = shift;

	my @specs = ();

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $errMess = "";

	unless ( $self->CheckSpecifications( \$errMess ) ) {

		die "Check before generate coupon specifications: " . $errMess;
	}

	my @depthLayers = CamDrilling->GetNCLayersByTypes(
													   $inCAM, $jobId,
													   [
														  EnumsGeneral->LAYERTYPE_nplt_bstiffcMill, EnumsGeneral->LAYERTYPE_nplt_bstiffcMill,
														  EnumsGeneral->LAYERTYPE_nplt_bMillTop,    EnumsGeneral->LAYERTYPE_nplt_bMillBot,
													   ]
	);

	 
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@depthLayers );
	my @childSteps = CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );

	foreach my $l (@depthLayers) {

		# 1) Check if there is request for depth coupon
		my $cpnRequired = 0;
		foreach my $s (@childSteps) {
			my %pnlLAtt = CamAttributes->GetLayerAttr( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"} );
			if ( defined $pnlLAtt{"depth_rout_calibration_coupon"} && $pnlLAtt{"depth_rout_calibration_coupon"} eq "yes" ) {
				$cpnRequired = 1;
				last;
			}
		}

		next unless ($cpnRequired);

		# 2) Check all total pcb thickness value per layer, there should be one if coupon request
		my $pcbThickValue = undef;

		foreach my $s (@childSteps) {

			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"}, 0 );
			next if ( $hist{"total"} == 0 );

			my %att = CamAttributes->GetLayerAttr( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"} );

			my $pcbThick = $att{"final_pcb_thickness"};

			if ( defined $pcbThick && $pcbThick ne "" && $pcbThick > 0 ) {

				$pcbThickValue = $pcbThick;    # only one total pcb thickness (except zero) per layer and all steps is possible
				last;
			}
		}

		# Check if all tools have same depth in one layer
		my $depthValue = undef;                # check all depths per layer, there should be one if coupon request

		foreach my $s (@childSteps) {

			my $dtm = UniDTM->new( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"}, 0, 0, 0 );

			my @depth = map { $_->GetDepth() } grep { !$_->GetSpecial() && $_->GetDepth() } $dtm->GetUniqueTools();

			if ( scalar(@depth) ) {
				$depthValue = $depth[0];       # only one depth per layer and all steps is possible
			}

		}

		# Build zaxis coupon specifications

		my %specInf = ();

		$specInf{"layer"}        = $l;
		$specInf{"type"}         = defined $pcbThickValue ? CPNTYPE_MATERIALRESTVA : CPNTYPE_DEPTHMILLINGVAL;
		$specInf{"toolDepth"}    = $depthValue * 1000;                                                          # in [um]
		$specInf{"side"}         = $l->{"gROWdrl_dir"} eq "bot2top" ? "bot" : "top";                            # which side is PCB routed from
		$specInf{"measureValue"} = defined $pcbThickValue ? $pcbThickValue : $depthValue*1000;                       # in [um]

		push( @specs, \%specInf );

	}

	return @specs;
}

# Return array of all depth routing which sould be measured
# Request for measure is indicated by layer attribute: depth_rout_calibration_coupon
# Each array item contains:
# - id: order id of coupon, starts from 1
# - stepName: full coupon step name which include depth increase as suffix
# - depthIncrease: depth increase, depands on step size and step plus/minus count
# - oriDepth: indicate if there is no depth increase - original tool depth
sub GetAllCpnSteps {
	my $self = shift;

	my @specs = ();

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @allCpns   = ();
	my @allDepths = ();

	# 1) Get negative depth steps
	for ( my $i = $DEF_STEP_MINUSCNT ; $i > 0 ; $i-- ) {

		push( @allDepths, -1 * $i * $DEF_STEP_SIZE );
	}

	# 2) Add not changed dpeth
	push( @allDepths, 0 );

	# 3) Add positive depth steps
	for ( my $i = 1 ; $i <= $DEF_STEP_PLUSCNT ; $i++ ) {

		push( @allDepths, $i * $DEF_STEP_SIZE );
	}

	for ( my $i = 0 ; $i < scalar(@allDepths) ; $i++ ) {

		my $cpnName = $self->GetCpnNameByStepDepth( $allDepths[$i] );

		push(
			  @allCpns,
			  {
				 "id"            => $i + 1,
				 "stepName"      => $cpnName,
				 "depthIncrease" => $allDepths[$i],
				 "oriDepth"      => ( $allDepths[$i] == 0 ? 1 : 0 )
			  }
		);

	}

	return @allCpns;
}

sub CreateCoupons {
	my $self = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @specs = $self->GetAllSpecifications();

	die "No zaxis specifications" unless ( scalar(@specs) );

	# Tool depth steps sorted from negative to positive (from smaller to larger value)
	my @allCPns = $self->GetAllCpnSteps();

	for ( my $i = 0 ; $i < scalar(@allCPns) ; $i++ ) {

		my $cpnId    = $allCPns[$i]->{"id"};
		my $oriDepth = $allCPns[$i]->{"oriDepth"};
		my $cpnName  = $allCPns[$i]->{"stepName"};

		# Create coupon step

		my $cpnW = $CPN_W;
		my $cpnH = $CPN_HEADER_H + scalar(@specs) * ( $CPN_SEC_HEADER_H + $CPN_SEC_ROUT_H );

		my $step = SRStep->new( $inCAM, $jobId, $cpnName );
		$step->Create( $cpnW / 1000, $cpnH / 1000, 0, 0, 0, 0 );
		CamHelper->SetStep( $inCAM, $cpnName );

		# Draw coupon

		$self->__DrawCoupon( $cpnName, $cpnW, $cpnH, \@specs, $cpnId, $oriDepth );
		 
	}

}

sub __DrawCoupon {
	my $self      = shift;
	my $step      = shift;
	my $wCpn      = shift;
	my $hCpn      = shift;
	my @spec      = @{ shift(@_) };
	my $cpnNumber = shift;
	my $oriDepth  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @outerSigL = CamJob->GetSignalLayerNames( $inCAM, $jobId, 0, 1 );
	my @innerSigL = CamJob->GetSignalLayerNames( $inCAM, $jobId, 1, 0 );

	# Define countour polyline
	my @contourP = ();
	push( @contourP, Point->new( 0,            0 ) );
	push( @contourP, Point->new( $wCpn / 1000, 0 ) );
	push( @contourP, Point->new( $wCpn / 1000, $hCpn / 1000 ) );
	push( @contourP, Point->new( 0,            $hCpn / 1000 ) );
	push( @contourP, Point->new( 0,            0 ) );

	# ------------------------------------------------------------------------------------------------
	# 1) Draw coupon header background
	# ------------------------------------------------------------------------------------------------

	my $drawBackg = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, $hCpn / 1000 - $CPN_HEADER_H / 1000 ) );

	my @headerAreaLim = ();
	push( @headerAreaLim, Point->new( 0,            0 ) );
	push( @headerAreaLim, Point->new( 0,            $CPN_HEADER_H / 1000 ) );
	push( @headerAreaLim, Point->new( $wCpn / 1000, $CPN_HEADER_H / 1000 ) );
	push( @headerAreaLim, Point->new( $wCpn / 1000, 0 ) );
	push( @headerAreaLim, Point->new( 0,            0 ) );

	my $headerAreaP = PrimitiveSurfPoly->new( \@headerAreaLim, undef, DrawEnums->Polar_POSITIVE );

	$drawBackg->AddPrimitive($headerAreaP);

	CamLayer->AffectLayers( $inCAM, \@outerSigL );

	$drawBackg->Draw();

	# ------------------------------------------------------------------------------------------------
	# 2) Draw pattern fill to inner layer
	# ------------------------------------------------------------------------------------------------

	if ( $self->{"layerCnt"} > 2 ) {

		for ( my $i = 0 ; $i < scalar(@innerSigL) ; $i++ ) {

			my $drawPattern = SymbolDrawing->new( $inCAM, $jobId );

			next if ( $self->{"stackup"}->GetCuLayer( $innerSigL[$i] )->GetUssage() == 0 );

			my $dotPattern = SurfaceDotPattern->new( 0, 0, 0, "circle", 500, 1000, ( $i % 2 == 0 ? "odd" : "even" ) );

			#my $dotPattern = SurfaceSolidPattern->new( 0, 0 );
			my $surfP = PrimitiveSurfFill->new( $dotPattern, 0, 0, 0, 0, 0, 0, DrawEnums->Polar_POSITIVE );

			$drawPattern->AddPrimitive($surfP);

			CamLayer->WorkLayer( $inCAM, $innerSigL[$i] );

			$drawPattern->Draw();

		}
	}

	# ------------------------------------------------------------------------------------------------
	# 3) Draw fake signal layer from oposite side of depth mill
	# ------------------------------------------------------------------------------------------------
	for ( my $i = 0 ; $i < scalar(@spec) ; $i++ ) {

		my $specInf = $spec[$i];

		my $drawFakeSig = SymbolDrawing->new(
			$inCAM, $jobId,
			Point->new(
				0,
				$hCpn / 1000 -
				  $CPN_HEADER_H / 1000 -
				  ( $i + 1 ) * ( $CPN_SEC_ROUT_H / 1000 + $CPN_SEC_HEADER_H / 1000 )

			)
		);

		my $dotPatternOdd  = SurfaceDotPattern->new( 0, 0, 0, "square", 800, 1300, "odd" );
		my $dotPatternEven = SurfaceDotPattern->new( 0, 0, 0, "square", 800, 1300, "even" );

		my @routAreaLim = ();
		push( @routAreaLim, Point->new( 0,            0 ) );
		push( @routAreaLim, Point->new( 0,            $CPN_SEC_ROUT_H / 1000 ) );
		push( @routAreaLim, Point->new( $wCpn / 1000, $CPN_SEC_ROUT_H / 1000 ) );
		push( @routAreaLim, Point->new( $wCpn / 1000, 0 ) );
		push( @routAreaLim, Point->new( 0,            0 ) );

		my $surfOddP  = PrimitiveSurfPoly->new( \@routAreaLim, $dotPatternOdd,  DrawEnums->Polar_POSITIVE );
		my $surfEvenP = PrimitiveSurfPoly->new( \@routAreaLim, $dotPatternEven, DrawEnums->Polar_POSITIVE );

		$drawFakeSig->AddPrimitive($surfOddP);
		$drawFakeSig->AddPrimitive($surfEvenP);

		if ( $specInf->{"side"} eq "bot" ) {

			CamLayer->WorkLayer( $inCAM, "c" );
			$drawFakeSig->Draw();

		}
		else {

			# only if s side exist
			if ( scalar( grep { $_ eq "s" } @outerSigL ) ) {

				CamLayer->WorkLayer( $inCAM, "s" );
				$drawFakeSig->Draw();
			}
		}
	}

	# ------------------------------------------------------------------------------------------------
	# 4) Draw zaxis mill
	# ------------------------------------------------------------------------------------------------
	for ( my $i = 0 ; $i < scalar(@spec) ; $i++ ) {

		my $specInf = $spec[$i];

		my $drawZaxis = SymbolDrawing->new(
			$inCAM, $jobId,
			Point->new(
				( $wCpn / 1000 - $CPN_SEC_ROUT_W / 1000 ) / 2,
				$hCpn / 1000 -
				  $CPN_HEADER_H / 1000 -
				  ( $i + 1 ) * ( $CPN_SEC_ROUT_H / 1000 + $CPN_SEC_HEADER_H / 1000 )

			)
		);

		my @routAreaLim = ();

		if ( $specInf->{"type"} eq CPNTYPE_MATERIALRESTVA ) {

			push( @routAreaLim, Point->new( 0,                      0 ) );
			push( @routAreaLim, Point->new( 0,                      $CPN_SEC_ROUT_H / 1000 ) );
			push( @routAreaLim, Point->new( $CPN_SEC_ROUT_W / 1000, $CPN_SEC_ROUT_H / 1000 ) );
			push( @routAreaLim, Point->new( $CPN_SEC_ROUT_W / 1000, 0 ) );
			push( @routAreaLim, Point->new( 0,                      0 ) );

		}
		elsif ( $specInf->{"type"} eq CPNTYPE_DEPTHMILLINGVAL ) {

			push( @routAreaLim, Point->new( $CPN_SEC_ROUT_W * 0.25 / 1000, $CPN_SEC_ROUT_H * 0.25 / 1000 ) );
			push( @routAreaLim, Point->new( $CPN_SEC_ROUT_W * 0.25 / 1000, $CPN_SEC_ROUT_H * 0.75 / 1000 ) );
			push( @routAreaLim, Point->new( $CPN_SEC_ROUT_W * 0.75 / 1000, $CPN_SEC_ROUT_H * 0.75 / 1000 ) );
			push( @routAreaLim, Point->new( $CPN_SEC_ROUT_W * 0.75 / 1000, $CPN_SEC_ROUT_H * 0.25 / 1000 ) );
			push( @routAreaLim, Point->new( $CPN_SEC_ROUT_W * 0.25 / 1000, $CPN_SEC_ROUT_H * 0.25 / 1000 ) );
		}

		my $p = PrimitiveSurfPoly->new( \@routAreaLim, undef, DrawEnums->Polar_POSITIVE );

		$p->AddAttribute( "tool_depth",             $specInf->{"toolDepth"} / 1000 );
		$p->AddAttribute( ".comp",                  "right" );
		$p->AddAttribute( ".rout_type",             "pocket" );
		$p->AddAttribute( ".rout_chain",            1 );
		$p->AddAttribute( ".rout_pocket_direction", $specInf->{"side"} eq "top" ? "standard" : "opposite" );
		$p->AddAttribute( ".rout_tool",             $DEPTH_ROUT_TOOL / 1000 );
		$p->AddAttribute( ".rout_tool2",            $DEPTH_ROUT_TOOL / 1000 );
		$p->AddAttribute( ".rout_pocket_overlap",   $DEPTH_ROUT_TOOL_OVERLAP / 1000 );
		$p->AddAttribute( ".rout_pocket_mode",      "concentric" );

		CamLayer->AffectLayers( $inCAM, [ $specInf->{"layer"}->{"gROWname"} ] );

		$drawZaxis->AddPrimitive($p);
		$drawZaxis->Draw();
	}

	# ------------------------------------------------------------------------------------------------
	# 7) Draw texts
	# ------------------------------------------------------------------------------------------------

	foreach my $l (@outerSigL) {

		CamLayer->WorkLayer( $inCAM, $l );

		my $mirror;

		if ( $l =~ /^c$/ ) {

			$mirror = 0;
		}
		elsif ( $l =~ /^s$/ ) {

			$mirror = 1;
		}

		# 1) Draw Id

		my $drawTexts = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, $hCpn / 1000 ) );

		my $pIdText =   $oriDepth ? "ORI" : $cpnNumber ;
		my $pIdOriX =
		    $mirror == 1
		  ? $wCpn / 1000 - ( $wCpn / 1000 - length($pIdText) * $CPN_ID_SIZE / 1000 ) / 2
		  : ( $wCpn / 1000 - length($pIdText) * $CPN_ID_SIZE / 1000 ) / 2;

		my $pIdOriY = ( $CPN_HEADER_H / 1000 - $CPN_ID_SIZE / 1000 ) / 2;

		my $pId = PrimitiveText->new( $pIdText,
									  Point->new( $pIdOriX, -$CPN_HEADER_H / 1000 + $pIdOriY ),
									  $CPN_ID_SIZE / 1000,
									  $CPN_ID_SIZE / 1000,
									  $CPN_ID_WIDTH, $mirror, 0, DrawEnums->Polar_NEGATIVE );

		$drawTexts->AddPrimitive($pId);

		# 2) Draw zaxis description

		for ( my $i = 0 ; $i < scalar(@spec) ; $i++ ) {

			my $specInf = $spec[$i];

			my $measureTypyTxt = sprintf( "%.2f", $specInf->{"measureValue"} / 1000 );

			#$measureTypyTxt =~ s/\./,/;

			$measureTypyTxt = "Z" . $measureTypyTxt if ( $specInf->{"type"} eq CPNTYPE_MATERIALRESTVA );
			$measureTypyTxt = "H" . $measureTypyTxt if ( $specInf->{"type"} eq CPNTYPE_DEPTHMILLINGVAL );

			my $measureTypOriX =
			    $mirror == 1
			  ? $wCpn / 1000 - ( $wCpn / 1000 - length($measureTypyTxt) * $CPN_VAL_SIZE / 1000 ) / 2
			  : ( $wCpn / 1000 - length($measureTypyTxt) * $CPN_VAL_SIZE / 1000 ) / 2;

			my $measureTypOriY = ( $CPN_SEC_HEADER_H / 1000 - $CPN_VAL_SIZE / 1000 ) / 2;

			my $txtP = PrimitiveText->new(
										   $measureTypyTxt,
										   Point->new(
													   $measureTypOriX,
													   -$CPN_HEADER_H / 1000 -
														 $i * ( $CPN_SEC_ROUT_H / 1000 + $CPN_SEC_HEADER_H / 1000 ) -
														 $CPN_SEC_HEADER_H / 1000 +
														 $measureTypOriY
										   ),
										   $CPN_VAL_SIZE / 1000,
										   $CPN_VAL_SIZE / 1000,
										   $CPN_VAL_WIDTH,
										   $mirror, 0,
										   DrawEnums->Polar_POSITIVE
			);

			$drawTexts->AddPrimitive($txtP);
		}

		$drawTexts->Draw();
	}

	# ------------------------------------------------------------------------------------------------
	# 10) Draw mask layer
	# ------------------------------------------------------------------------------------------------

	# Copy prepared mask to existing solder mask layer
	my @masksL = grep { $_->{"gROWlayer_type"} eq "solder_mask" && $_->{"gROWname"} =~ /^m[cs]\d*$/ } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	# UnMask title text

	foreach my $maskL (@masksL) {

		# Unmask text
		my $sigL = ( $maskL->{"gROWname"} =~ /^m([cs])\d?$/ )[0];

		if ( CamHelper->LayerExists( $inCAM, $jobId, $sigL ) ) {

			my $f = FeatureFilter->new( $inCAM, $jobId, $sigL );

			$f->SetFeatureTypes( "text" => 1 );
			if ( $f->Select() ) {

				my $unMaskTitleL = GeneralHelper->GetGUID();

				CamLayer->CopySelOtherLayer( $inCAM, [$unMaskTitleL] );

				CamLayer->WorkLayer( $inCAM, $unMaskTitleL );
				CamLayer->Contourize( $inCAM, $unMaskTitleL );
				CamLayer->WorkLayer( $inCAM, $unMaskTitleL );
				CamLayer->ResizeFeatures( $inCAM, 200 );
				$inCAM->COM(
							 "merge_layers",
							 "source_layer" => $unMaskTitleL,
							 "dest_layer"   => $maskL->{"gROWname"}
				);

				CamMatrix->DeleteLayer( $inCAM, $jobId, $unMaskTitleL );

			}
		}

		# Umask header

		CamLayer->WorkLayer( $inCAM, $maskL->{"gROWname"} );

		my $drawHeaderMask = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, $hCpn / 1000 - $CPN_HEADER_H / 1000 ) );

		my @headerAreaLim = ();
		push( @headerAreaLim, Point->new( 0,            0 ) );
		push( @headerAreaLim, Point->new( 0,            $CPN_HEADER_H / 1000 ) );
		push( @headerAreaLim, Point->new( $wCpn / 1000, $CPN_HEADER_H / 1000 ) );
		push( @headerAreaLim, Point->new( $wCpn / 1000, 0 ) );
		push( @headerAreaLim, Point->new( 0,            0 ) );

		my $headerAreaP = PrimitiveSurfPoly->new( \@headerAreaLim, undef, DrawEnums->Polar_POSITIVE );

		$drawHeaderMask->AddPrimitive($headerAreaP);
		$drawHeaderMask->Draw();

		# Umask contour
		my $drawUnMaskContour = SymbolDrawing->new( $inCAM, $jobId, Point->new( 0, 0 ) );
		$drawUnMaskContour->AddPrimitive( PrimitivePolyline->new( \@contourP, "r200", DrawEnums->Polar_POSITIVE ) );
		$drawUnMaskContour->Draw();

		# Unmask depth mill area
		for ( my $i = 0 ; $i < scalar(@spec) ; $i++ ) {

			my $specInf = $spec[$i];

			if ( $specInf->{"side"} eq "bot" && $maskL->{"gROWname"} =~ /s/ || $specInf->{"side"} eq "top" && $maskL->{"gROWname"} =~ /c/ ) {

				my $drawUnmaskRout = SymbolDrawing->new(
					$inCAM, $jobId,
					Point->new(
						0,
						$hCpn / 1000 -
						  $CPN_HEADER_H / 1000 -
						  ( $i + 1 ) * ( $CPN_SEC_ROUT_H / 1000 + $CPN_SEC_HEADER_H / 1000 )

					)
				);

				my @routAreaLim = ();
				push( @routAreaLim, Point->new( 0,            0 ) );
				push( @routAreaLim, Point->new( 0,            $CPN_SEC_ROUT_H / 1000 ) );
				push( @routAreaLim, Point->new( $wCpn / 1000, $CPN_SEC_ROUT_H / 1000 ) );
				push( @routAreaLim, Point->new( $wCpn / 1000, 0 ) );
				push( @routAreaLim, Point->new( 0,            0 ) );

				my $surf = PrimitiveSurfPoly->new( \@routAreaLim, undef, DrawEnums->Polar_POSITIVE );
				$drawUnmaskRout->AddPrimitive($surf);
				$drawUnmaskRout->Draw();
			}
		}

	}

	# ------------------------------------------------------------------------------------------------
	# 11) Prepare outline rout on bridges
	# ------------------------------------------------------------------------------------------------
	Helper->PrepareProfileRoutOnBridges( $inCAM, $jobId, $step, 1, 1, $BRIDGES_CNT_W, $BRIDGES_CNT_H, $BRIDGES_WIDTH, $OUTLINE_ROUT_TOOL );

	CamLayer->ClearLayers($inCAM);

	return 1;

}

#-------------------------------------------------------------------------------------------#
# Static class method
#-------------------------------------------------------------------------------------------#

sub GetCpnNameByStepDepth {
	my $class = shift;
	my $depth = shift;

	my $cpnStepName = EnumsGeneral->Coupon_ZAXIS;

	if ( $depth >= 0 ) {

		$cpnStepName .= int($depth);

	}
	else {
		$cpnStepName .= $depth * -1 + 1000;
	}

	return $cpnStepName;

}

sub GetStepDepthByCpnName {
	my $class       = shift;
	my $cpnStepName = shift;

	# Check on coupon name validity

	my $depth = undef;

	die "Wrong format of zaxis step coupon name: $cpnStepName" unless ( $class->GetIsStepZaxisCpn($cpnStepName) );

	my $cpnName = EnumsGeneral->Coupon_ZAXIS;
	if ( $cpnStepName =~ m/^$cpnName(\d+)$/i ) {

		my $stepSize = $1;

		# check if added depth is positive/negative

		if ( $stepSize > 1000 ) {

			#negative depth has expressed as depth + 1000
			$depth = $stepSize * -1 + 1000;
		}
		else {

			$depth = $stepSize;
		}
	}

	return $depth;
}

sub GetIsStepZaxisCpn {
	my $class       = shift;
	my $cpnStepName = shift;

	# Check on coupon name validity

	my $cpnName = EnumsGeneral->Coupon_ZAXIS;

	if ( $cpnStepName =~ m/^$cpnName(\d+)$/i ) {

		return 1;
	}
	else {
		return 0;
	}

}

sub GetDefStepSize {
	my $class = shift;

	return $DEF_STEP_SIZE;
}

sub GetDefStepMinusCnt {
	my $class = shift;

	return $DEF_STEP_PLUSCNT;
}

sub GetDefStepPlusCnt {
	my $class = shift;

	return $DEF_STEP_MINUSCNT;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Microsection::CouponZaxisMill';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d322952";
	my $step  = "panel";

	#my $m = CouponZaxisMill->new( $inCAM, $jobId );

	#my $cpn = EnumsGeneral->Coupon_ZAXIS . "1050";

	my $c = CouponZaxisMill->new( $inCAM, $jobId );
	$c->CreateCoupons();

	die;
}

1;

