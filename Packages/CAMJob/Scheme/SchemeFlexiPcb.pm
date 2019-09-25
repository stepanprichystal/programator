#-------------------------------------------------------------------------------------------#
# Description: Adjustment of customer schema
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Scheme::SchemeFlexiPcb;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamNCHooks';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::CAMJob::Scheme::SchemeFrame::SchemeFrame';
use aliased 'Packages::CAMJob::Scheme::SchemeFrame::Enums' => 'SchemeFrEnums';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums'                     => 'FilterEnums';
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::Enums' => 'EnumsPins';
use aliased 'CamHelpers::CamStepRepeatPnl';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Check if mpanel contain requsted schema by customer
sub AddFlexiHoles {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $flexType = JobHelper->GetPcbFlexType($jobId);

	return unless ($flexType);

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );

	my @layers = ();

	#flex
	if ( $flexType eq EnumsGeneral->PcbFlexType_FLEX ) {
		push( @layers, "v" );
	}

	# rigid flex
	else {

		push( @layers, "v1" );
	}

	my @lOther =
	  CamDrilling->GetNCLayersByTypes(
									   $inCAM, $jobId,
									   [
										  EnumsGeneral->LAYERTYPE_nplt_cvrlycMill, EnumsGeneral->LAYERTYPE_nplt_cvrlysMill,
										  EnumsGeneral->LAYERTYPE_nplt_prepregMill
									   ]
	  );

	push( @layers, map { $_->{"gROWname"} } @lOther ) if (@lOther);

	foreach my $layer (@layers) {

		my $sym       = ( $layer =~ /^v|v1$/ ) ? "r3500" : "r4000";
		my $holePitch = 220;
		my $framDist  = 5;

		CamLayer->WorkLayer( $inCAM, $layer );
		if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".pnl_place", "flexi_holes" ) ) {
			$inCAM->COM("sel_delete");
		}

		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".pnl_place", "flexi_holes" );

		CamHelper->SetStep( $inCAM, "panel" );
		CamLayer->WorkLayer( $inCAM, $layer );

		my $h = $lim{"yMax"};
		my $w = $lim{"xMax"} - $lim{"xMin"};

		# LT
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w / 2 - $holePitch / 2, "y" => $lim{"yMax"} - $framDist } );

		# RT
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w - ( $w / 2 - $holePitch / 2 ), "y" => $lim{"yMax"} - $framDist } );

		# LB
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w / 2 - $holePitch / 2, "y" => $framDist } );

		# RB
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w - ( $w / 2 - $holePitch / 2 ), "y" => $framDist } );

		CamSymbol->ResetCurAttributes($inCAM);

	}

	return $result;
}

sub AddHolesCoverlay {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my $result = 1;

	return 0 if ( $stepName ne "panel" );

	my $flexType = JobHelper->GetPcbFlexType($jobId);

	return 0 if ( $flexType ne EnumsGeneral->PcbFlexType_RIGIDFLEXI && $flexType ne EnumsGeneral->PcbFlexType_RIGIDFLEXO );

	my @coverlay =
	  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_cvrlycMill, EnumsGeneral->LAYERTYPE_nplt_cvrlysMill ] );

	my @scanMarks = CamNCHooks->GetLayerCamMarks( $inCAM, $jobId, $stepName, "v1" );

	# press holes
	my %pressBot = CamNCHooks->GetScanMarkPoint( \@scanMarks, "3-15mm-IN-left-bot" );
	my %pressTop = CamNCHooks->GetScanMarkPoint( \@scanMarks, "3-15mm-IN-left-top" );

	my %olecLT = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Inner-left-top" );
	my %olecRT = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Inner-right-top" );
	my %olecRB = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Inner-right-bot" );
	my %olecLB = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Inner-left-bot" );

	foreach my $layer (@coverlay) {

		CamLayer->WorkLayer( $inCAM, $layer->{"gROWname"} );
		if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".pnl_place", "coverlay_press" ) ) {
			$inCAM->COM("sel_delete");
		}

		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".pnl_place", "coverlay_press" );

		CamSymbol->AddPad( $inCAM, "r4000", \%pressTop );
		CamSymbol->AddPad( $inCAM, "r4000", \%pressBot );

		CamSymbol->ResetCurAttributes($inCAM);

		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".pnl_place", "coverlay_olec_vv" );

		CamSymbol->AddPad( $inCAM, "r4000", \%olecLT );
		CamSymbol->AddPad( $inCAM, "r4000", \%olecRT );
		CamSymbol->AddPad( $inCAM, "r4000", \%olecRB );
		CamSymbol->AddPad( $inCAM, "r4000", \%olecLB );

		CamSymbol->ResetCurAttributes($inCAM);
	}

}

sub AddFlexiCoreHoles {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my $result = 1;

	return 0 if ( $stepName ne "panel" );

	my $flexType = JobHelper->GetPcbFlexType($jobId);

	return 0 if ( $flexType ne EnumsGeneral->PcbFlexType_RIGIDFLEXI && $flexType ne EnumsGeneral->PcbFlexType_RIGIDFLEXO );

	my $l = "v1";

	my @scanMarks = CamNCHooks->GetLayerCamMarks( $inCAM, $jobId, $stepName, "c" );
	my %lt = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Outer_VV-left-top" );
	my %rt = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Outer_VV-right-top" );
	my %lb = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Outer_VV-left-bot" );
	my %rb = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Outer_VV-right-bot" );

	CamLayer->WorkLayer( $inCAM, $l );
	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".pnl_place", "flexi_olec" ) ) {
		$inCAM->COM("sel_delete");
	}

	CamSymbol->AddCurAttribute( $inCAM, $jobId, ".pnl_place", "flexi_olec" );

	CamSymbol->AddPad( $inCAM, "r3000", \%lt );
	CamSymbol->AddPad( $inCAM, "r3000", \%rt );
	CamSymbol->AddPad( $inCAM, "r3000", \%lb );
	CamSymbol->AddPad( $inCAM, "r3000", \%rb );

	CamSymbol->ResetCurAttributes($inCAM);
	CamLayer->ClearLayers( $inCAM, $l );

}

# Frame is prevention from bending panel corner in machines.
# The copper frame on flexi core does flex more rigid and resistant to deformation
sub AddFlexiCoreFrame {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $frameAttr    = "flexicore_frame";
	my $frameWidthLR = 18;                  # 18mm of copper frame on left and right
	my $frameWidthTB = 25;                  # 25 mm of copper frame on top and bot

	my $schemeFrame = SchemeFrame->new( $inCAM, $jobId );

	my $type = JobHelper->GetPcbFlexType($jobId);

	if ( !( defined $type && ( $type eq EnumsGeneral->PcbFlexType_RIGIDFLEXO || $type eq EnumsGeneral->PcbFlexType_RIGIDFLEXI ) ) ) {
		return 0;
	}

	my $stackup = Stackup->new($jobId);
	my @layers  = ();

	foreach my $c ( grep { $_->GetCoreRigidType() eq StackEnums->CoreType_FLEX } $stackup->GetAllCores() ) {

		push( @layers, $c->GetTopCopperLayer()->GetCopperName() );
		push( @layers, $c->GetBotCopperLayer()->GetCopperName() );
	}

	foreach my $l (@layers) {

		# look for

		my $polarity = CamMatrix->GetLayerPolarity( $inCAM, $jobId, $l );

		$inCAM->COM(
					 "sr_fill",
					 "type"            => "solid",
					 "solid_type"      => "surface",
					 "polarity"        => $polarity,
					 "step_max_dist_x" => $frameWidthLR,
					 "step_max_dist_y" => $frameWidthTB,
					 "consider_feat"   => "yes",
					 "feat_margin"     => "0",
					 "dest"            => "layer_name",
					 "layer"           => $l,
					 "attributes"      => "yes"
		);

		CamLayer->WorkLayer( $inCAM, $l );

		# Set core frame attribute
		# surface area has about 20000mm2
		if ( CamFilter->BySurfaceArea( $inCAM, 1000, 30000 ) ) {

			CamAttributes->SetFeatuesAttribute( $inCAM, $frameAttr, "" );

		}
		else {
			die "Copper frame for flex core was not detected for layer:$l";
		}

		# look for place for drilled pcb without copper and add coper

		if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".pnl_place", "negativ_for_drilled_pcbId_v2" ) ) {

			$inCAM->COM("sel_invert");
		}

	}

	CamLayer->ClearLayers($inCAM);

}

# If any flex inner layer contain coverlay, remove pattern fill from copper layer
sub ReplacePatternFillFlexiCore {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $flexType = JobHelper->GetPcbFlexType($jobId);

	return 0 unless ($flexType);

	return 0 if ( !( $flexType eq EnumsGeneral->PcbFlexType_RIGIDFLEXO || $flexType eq EnumsGeneral->PcbFlexType_RIGIDFLEXI ) );

	CamHelper->SetStep( $inCAM, "panel" );

	my @nestStep = map { $_->{"stepName"} } CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "panel" );

	my $stackup = Stackup->new($jobId);
	my @layers  = ();

	foreach my $c ( grep { $_->GetCoreRigidType() eq StackEnums->CoreType_FLEX } $stackup->GetAllCores() ) {

		push( @layers, $c->GetTopCopperLayer()->GetCopperName() );
		push( @layers, $c->GetBotCopperLayer()->GetCopperName() );
	}

	foreach my $l (@layers) {

		# Inner layer with coverlay
		if ( $l =~ /^v\d$/ && CamHelper->LayerExists( $inCAM, $jobId, "coverlay" . $l ) ) {

			CamLayer->WorkLayer( $inCAM, $l );

			my $f = FeatureFilter->new( $inCAM, $jobId, $l );

			$f->AddIncludeAtt(".pattern_fill");
			$f->AddExcludeAtt("flexicore_frame");    # there is fcopper core at flexi cores - do not delete it

			if ( CamMatrix->GetLayerPolarity( $inCAM, $jobId, $l ) eq "positive" ) {
				$f->SetPolarity( FilterEnums->Polarity_POSITIVE );
			}
			else {
				$f->SetPolarity( FilterEnums->Polarity_NEGATIVE );
			}

			if ( $f->Select() ) {
				$inCAM->COM("sel_delete");


				# Put new special schema "Cross hatch" for flex layer
				$inCAM->COM(
							 "sr_fill",
							 "type"                    => "predefined_pattern",
							 "predefined_pattern_type" => "cross_hatch",
							 "indentation"             => "even",
							 "cross_hatch_angle"       => "45",
							 "cross_hatch_witdh"       => "500",
							 "cross_hatch_dist"        => "2000",
							 "step_margin_x"           => "8",
							 "step_margin_y"           => "27",
							 "step_max_dist_x"         => "555",
							 "step_max_dist_y"         => "555",
							 "sr_margin_x"             => "2.5",
							 "sr_margin_y"             => "2.5",
							 "sr_max_dist_x"           => "555",
							 "sr_max_dist_y"           => "555",
							 "consider_feat"           => "yes",
							 "feat_margin"             => "1",
							 "consider_drill"          => "yes",
							 "drill_margin"            => "1",
							 "consider_rout"           => "no",
							 "dest"                    => "layer_name",
							 "layer"                   => $l,
							 "stop_at_steps"           => join( ";", @nestStep )
				);
			}
			else {

				die "No pattern fill was found in inner layer:$l, step panel: panel";
			}

		}
	}

}

sub AddCoverlayRegisterHoles {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $flexType = JobHelper->GetPcbFlexType($jobId);

	return unless ($flexType);

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );

	my @layers = ("v");
	push( @layers, "v1" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "v1" ) );

	my @lOther = CamDrilling->GetNCLayersByTypes(
												  $inCAM, $jobId,
												  [
													 EnumsGeneral->LAYERTYPE_nplt_cvrlycMill, EnumsGeneral->LAYERTYPE_nplt_cvrlysMill,
													 EnumsGeneral->LAYERTYPE_nplt_soldcMill,EnumsGeneral->LAYERTYPE_nplt_soldsMill,
													EnumsGeneral->LAYERTYPE_nplt_stiffcMill, EnumsGeneral->LAYERTYPE_nplt_stiffsMill
												  ]
	);

	push( @layers, map { $_->{"gROWname"} } @lOther ) if (@lOther);

	my @sigLayers = CamJob->GetSignalLayerNames( $inCAM, $jobId );

	foreach my $layer ( ( @layers, @sigLayers ) ) {

		my $polarity = "positive";
		my $sym      = "r3300";

		if ( $layer =~ /^[cs]$/ || $layer =~ /^v[2-]$/) {

			$sym = "r4200";

			if ( CamMatrix->GetLayerPolarity( $inCAM, $jobId, $layer ) eq "positive" ) {
				$polarity = "negative";
			}
		}

		# Six holes

		my $holePitchX = 265 + 10;
		my $holePitchY = 324 + 10;

		CamLayer->WorkLayer( $inCAM, $layer );
		if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".pnl_place", "coverlay_register_holes" ) ) {
			$inCAM->COM("sel_delete");
		}

		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".pnl_place", "coverlay_register_holes" );

		CamHelper->SetStep( $inCAM, "panel" );
		CamLayer->WorkLayer( $inCAM, $layer );

		my $h = $lim{"yMax"};
		my $w = $lim{"xMax"} - $lim{"xMin"};

		# Temporary add 850 hole in order insert drilled number
		if ( $layer =~ /^fstiff[cs]\d?$/ || $layer =~ /^fsold[cs]\d?$/ ) {
			CamSymbol->AddPad( $inCAM, "r850", { "x" => $w / 2 - $holePitchX / 2, "y" => $h / 2 + $holePitchY / 2 }, undef, $polarity );
		}

		# LT
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w / 2 - $holePitchX / 2, "y" => $h / 2 + $holePitchY / 2 }, undef, $polarity );

		# RT
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w - ( $w / 2 - $holePitchX / 2 ), "y" => $h / 2 + $holePitchY / 2 }, undef, $polarity );

		# RB
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w - ( $w / 2 - $holePitchX / 2 ), "y" => $h / 2 - $holePitchY / 2 }, undef, $polarity );

		# LB
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w / 2 - $holePitchX / 2, "y" => $h / 2 - $holePitchY / 2 }, undef, $polarity );

		#LCenter
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w / 2 - $holePitchX / 2, "y" => $h / 2 }, undef, $polarity );

		#RCenter
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w - ( $w / 2 - $holePitchX / 2 ), "y" => $h / 2 }, undef, $polarity );

		#T 1/3of Width
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w/2 - 46, "y" => $h / 2 + $holePitchY / 2 }, undef, $polarity );
		
		#T 2/3of Width
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w/2 + 46, "y" => $h / 2 + $holePitchY / 2 }, undef, $polarity );

		#B 1/3of Width
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w/2 - 46, "y" => $h / 2 - $holePitchY / 2 }, undef, $polarity );
		
		#B 2/3of Width
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w/2 + 46, "y" => $h / 2 - $holePitchY / 2 }, undef, $polarity );

		CamSymbol->ResetCurAttributes($inCAM);

	}

	return $result;
}

# Move coverlaz register marks from nested steps to panel step
# In order fill not cover theses marks in signal layers
sub AddCoverlayRegisterMarks {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my $result = 1;

	return 0 if ( $stepName ne "panel" &&  $stepName ne "mpanel" );

	my $flexType = JobHelper->GetPcbFlexType($jobId);

	return 0 if ( $flexType ne EnumsGeneral->PcbFlexType_RIGIDFLEXI && $flexType ne EnumsGeneral->PcbFlexType_RIGIDFLEXO );

	my @coverLay =
	  grep { $_->{"gROWname"} =~ /^coverlay([cs])$/ || $_->{"gROWname"} =~ /^coverlay(v\d+)$/ } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	return 0 unless (@coverLay);

	CamHelper->SetStep( $inCAM, $stepName );

	foreach my $cvrLayer (@coverLay) {

		my ($sigLayer) = $cvrLayer->{"gROWname"} =~ m/^coverlay(.*)$/;

		my $tmp = GeneralHelper->GetGUID();

		$inCAM->COM( 'flatten_layer', "source_layer" => $sigLayer, "target_layer" => $tmp );
		CamLayer->WorkLayer( $inCAM, $tmp );

		my $f = FeatureFilter->new( $inCAM, $jobId, $tmp );

		$f->AddIncludeAtt( ".string", EnumsPins->PinString_SIGLAYERMARKS );


		if ( $f->Select() ) {
			$inCAM->COM('sel_reverse');
			$inCAM->COM("sel_delete");

			# Set pnl_place in order action "delete schema" remove theses features too
			CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, ".pnl_place", "" );

			CamLayer->CopySelOtherLayer( $inCAM, [$sigLayer] );
		}

		CamLayer->ClearLayers($inCAM);
		CamMatrix->DeleteLayer( $inCAM, $jobId, $tmp );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Scheme::SchemeFlexiPcb';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152456";

	my $mess = "";

	my $result = SchemeFlexiPcb->AddCoverlayRegisterMarks( $inCAM, $jobId, "panel" );

	print STDERR "Result is: $result, error message: $mess\n";

}

1;
