
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers before print as pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::ImgPreview::ImgLayerPrepare;

#3th party library
use threads;
use strict;
use warnings;
use PDF::API2;
use List::Util qw[max min];
use Math::Trig;
use Image::Size;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::ImgPreview::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAMJob::OutputData::Helper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::Enums' => 'OutParserEnums';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputParserNC';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Polygon::Enums' => 'PolyEnums';
use aliased 'Packages::CAMJob::FlexiLayers::BendAreaParser::BendAreaParser';
use aliased 'Packages::Polygon::Line::LineTransform';
use aliased 'Packages::ProductionPanel::ActiveArea::ActiveArea';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"viewType"} = shift;
	$self->{"pdfStep"}  = shift;

	$self->{"profileLim"} = undef;                                       # limits of pdf step
	$self->{"pcbType"}    = JobHelper->GetPcbType( $self->{"jobId"} );

	return $self;
}

sub PrepareLayers {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# get limits of step
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $self->{"pdfStep"}, 1 );
	$self->{"profileLim"} = \%lim;

	# 1) Create special overlays which are used more than once
	$self->{"pltThroughL"} = $self->__GetPltThroughCuts($layerList);
	$self->{"bendAreaL"}   = $self->__GetOverlayBendArea($layerList);
	$self->{"cvrlsL"}      = $self->__GetOverlayCoverlays($layerList);

	# 2) Prepare PDF layers
	$self->__PrepareLayers($layerList);

	# 3) Remove special overlays
	#	# TODO Temporary, we need to fix bug. Copy layer to ori step
	#	if ( defined $self->{"bendAreaL"} ) {
	#		my $oriStep = $self->{"pdfStep"};
	#		$oriStep =~ s/pdf_//;
	#		$inCAM->COM(
	#					 'copy_layer',
	#					 "source_job"   => $jobId,
	#					 "source_step"  => $self->{"pdfStep"},
	#					 "source_layer" => $self->{"bendAreaL"},
	#					 "dest"         => 'layer_name',
	#					 "dest_step"    => $oriStep,
	#					 "dest_layer"   => "bend_area_wong_pdf",
	#					 "mode"         => 'replace',
	#					 "invert"       => 'no'
	#		);
	#	}

	CamMatrix->DeleteLayer( $inCAM, $jobId, $self->{"pltThroughL"} ) if ( defined $self->{"pltThroughL"} );    # bend area
	CamMatrix->DeleteLayer( $inCAM, $jobId, $self->{"bendAreaL"} )   if ( defined $self->{"bendAreaL"} );      # bend area
	CamMatrix->DeleteLayer( $inCAM, $jobId, $self->{"cvrlsL"}->{$_} ) foreach ( keys %{ $self->{"cvrlsL"} } ); # coverlays
}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __PrepareLayers {
	my $self      = shift;
	my $layerList = shift;

	foreach my $l ( $layerList->GetLayers() ) {

		$self->__PrepareRIGIDMAT($l)      if ( $l->GetType() eq Enums->Type_RIGIDMATOUTER );
		$self->__PrepareRIGIDMAT($l)      if ( $l->GetType() eq Enums->Type_RIGIDMATINNER );
		$self->__PrepareFLEXMAT($l)       if ( $l->GetType() eq Enums->Type_FLEXMATOUTER );
		$self->__PrepareFLEXMAT($l)       if ( $l->GetType() eq Enums->Type_FLEXMATINNER );
		$self->__PrepareVIAFILL($l)       if ( $l->GetType() eq Enums->Type_VIAFILL );
		$self->__PrepareOUTERCU($l)       if ( $l->GetType() eq Enums->Type_OUTERCU );
		$self->__PrepareOUTERSURFACE($l)  if ( $l->GetType() eq Enums->Type_OUTERSURFACE );
		$self->__PrepareINNERCU($l)       if ( $l->GetType() eq Enums->Type_INNERCU );
		$self->__PrepareGOLDFINGER($l)    if ( $l->GetType() eq Enums->Type_GOLDFINGER );
		$self->__PrepareGRAFIT($l)        if ( $l->GetType() eq Enums->Type_GRAFIT );
		$self->__PreparePEELABLE($l)      if ( $l->GetType() eq Enums->Type_PEELABLE );
		$self->__PrepareMASK($l)          if ( $l->GetType() eq Enums->Type_MASK );
		$self->__PrepareMASK($l)          if ( $l->GetType() eq Enums->Type_MASK2 );
		$self->__PrepareFLEXMASK($l)      if ( $l->GetType() eq Enums->Type_FLEXMASK );
		$self->__PrepareCOVERLAY($l)      if ( $l->GetType() eq Enums->Type_COVERLAY );
		$self->__PrepareSILK($l)          if ( $l->GetType() eq Enums->Type_SILK );
		$self->__PrepareSILK($l)          if ( $l->GetType() eq Enums->Type_SILK2 );
		$self->__PreparePLTDEPTHNC($l)    if ( $l->GetType() eq Enums->Type_PLTDEPTHNC );
		$self->__PrepareNPLTDEPTHNC($l)   if ( $l->GetType() eq Enums->Type_NPLTDEPTHNC );
		$self->__PrepareNPLTTHROUGHNC($l) if ( $l->GetType() eq Enums->Type_NPLTTHROUGHNC );
		$self->__PrepareSTIFFENER($l)     if ( $l->GetType() eq Enums->Type_STIFFENER );
		$self->__PrepareSTIFFDEPTHNC($l)  if ( $l->GetType() eq Enums->Type_STIFFDEPTHNC );
		$self->__PrepareTAPE($l)          if ( $l->GetType() eq Enums->Type_TAPE );
		$self->__PrepareTAPE($l)          if ( $l->GetType() eq Enums->Type_TAPEBACK );
	}

}

sub __PrepareRIGIDMAT {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};
	my $lName = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	$inCAM->COM(
				 "sr_fill",
				 "type"          => "solid",
				 "solid_type"    => "surface",
				 "min_brush"     => "25.4",
				 "cut_prims"     => "no",
				 "polarity"      => "positive",
				 "consider_rout" => "no",
				 "dest"          => "layer_name",
				 "layer"         => $lName,
				 "stop_at_steps" => "",
				 "step_margin_x" => -1,
				 "step_margin_y" => -1
	);

	if ( defined $self->{"pltThroughL"} ) {

		$inCAM->COM( "merge_layers", "source_layer" => $self->{"pltThroughL"}, "dest_layer" => $lName );
	}

	# Consider plated through hole
	if ( defined $self->{"bendAreaL"} ) {

		$inCAM->COM( "merge_layers", "source_layer" => $self->{"bendAreaL"}, "dest_layer" => $lName );
	}

	$layer->SetOutputLayer($lName);
}

sub __PrepareFLEXMAT {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};
	my $lName = GeneralHelper->GetGUID();

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	$inCAM->COM(
				 "sr_fill",
				 "type"          => "solid",
				 "solid_type"    => "surface",
				 "min_brush"     => "25.4",
				 "cut_prims"     => "no",
				 "polarity"      => "positive",
				 "consider_rout" => "no",
				 "dest"          => "layer_name",
				 "layer"         => $lName,
				 "stop_at_steps" => "",
				 "step_margin_x" => -1,
				 "step_margin_y" => -1
	);

	# Consider plated through hole
	if ( defined $self->{"pltThroughL"} ) {

		$inCAM->COM( "merge_layers", "source_layer" => $self->{"pltThroughL"}, "dest_layer" => $lName );
	}

	$layer->SetOutputLayer($lName);
}

sub __PrepareOUTERCU {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );

		# Consider plated through hole
		if ( defined $self->{"pltThroughL"} ) {
			$inCAM->COM( "merge_layers", "source_layer" => $self->{"pltThroughL"}, "dest_layer" => $lName );
		}

		$layer->SetOutputLayer($lName);
	}

}

sub __PrepareINNERCU {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );

		# Consider plated through hole
		if ( defined $self->{"pltThroughL"} ) {
			$inCAM->COM( "merge_layers", "source_layer" => $self->{"pltThroughL"}, "dest_layer" => $lName );
		}

		$layer->SetOutputLayer($lName);
	}
}

sub __PrepareOUTERSURFACE {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		my $lName = GeneralHelper->GetGUID();
		$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );

		my @maskLs =
		  grep { $_->{"gROWlayer_type"} eq "solder_mask" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );    #[possible mask layer]

		my $sigL = $layers[0]->{"gROWname"};
		@maskLs = grep { $_->{"gROWname"} =~ /^m$sigL(2)?(flex)?/ } @maskLs;

		foreach my $maskL ( map { $_->{"gROWname"} } @maskLs ) {

			# If mask exist,
			# 1) copy to help layer, 2) do negative and conturize
			if ( CamHelper->LayerExists( $inCAM, $jobId, $maskL ) ) {

				my $lNameMask = GeneralHelper->GetGUID();
				$inCAM->COM( "merge_layers", "source_layer" => $maskL, "dest_layer" => $lNameMask );

				CamLayer->WorkLayer( $inCAM, $lNameMask );

				if ( $maskL !~ /flex/ ) {
					CamLayer->NegativeLayerData( $inCAM, $lNameMask, $self->{"profileLim"} );
				}

				CamLayer->Contourize( $inCAM, $lNameMask );
				$inCAM->COM( "merge_layers", "source_layer" => $lNameMask, "dest_layer" => $lName, "invert" => "yes" );
				$inCAM->COM( "delete_layer", "layer" => $lNameMask );

				#CamLayer->Contourize( $inCAM, $lName );
			}
		}

		# 2) Consider overlay

		my $cvrL = "cvrl" . $layers[0]->{"gROWname"};
		if ( defined $self->{"cvrlsL"}->{$cvrL} ) {
			$inCAM->COM( "merge_layers", "source_layer" => $self->{"cvrlsL"}->{$cvrL}, "dest_layer" => $lName, "invert" => "yes" );
		}

		# 3) Consider plated through hole
		if ( defined $self->{"pltThroughL"} ) {
			$inCAM->COM( "merge_layers", "source_layer" => $self->{"pltThroughL"}, "dest_layer" => $lName );
		}

		$layer->SetOutputLayer($lName);
	}
}

sub __PrepareGOLDFINGER {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		# Prepare reference layer (gold + mask), which specifies area, where is hard gold

		my $goldL   = $layers[0]->{"gROWname"};
		my $baseCuL = ( $goldL =~ m/^gold([cs])$/ )[0];
		my $maskL   = "m" . $baseCuL;

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $maskL ) ) {
			$maskL = 0;
		}

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $goldL ) ) {
			die "Reference layer $goldL doesn't exist.";
		}

		my $resultL = Helper->FeaturesByRefLayer( $inCAM, $jobId, $baseCuL, $goldL, $maskL, $self->{"profileLim"} );

		# Consider plated through hole
		if ( defined $self->{"pltThroughL"} ) {
			$inCAM->COM( "merge_layers", "source_layer" => $self->{"pltThroughL"}, "dest_layer" => $resultL );
		}

		$layer->SetOutputLayer($resultL);

	}
}

sub __PrepareGRAFIT {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {

		my $lName = GeneralHelper->GetGUID();
		$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );

		$layer->SetOutputLayer($lName);

	}
}

sub __PreparePEELABLE {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = $layer->GetSingleLayers();

	my $isInfo = ( HegMethods->GetAllByPcbId($jobId) )[0];

	if ( $layers[0] ) {

		# Add only if Peelable is requested by customer and exist in IS
		# (sometimes Job contain only helper peelable layers)
		if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

			return 0 if ( $isInfo->{"lak_typ"} !~ /^[c2]$/i );
		}
		elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

			return 0 if ( $isInfo->{"lak_typ"} !~ /^[s2]$/i );
		}

		# Prepare layer by layer type (rout vs standard)
		my $lName = GeneralHelper->GetGUID();

		if ( CamHelper->LayerExists( $inCAM, $jobId, "f" . $layers[0]->{"gROWname"} ) ) {

			my $lTmp = CamLayer->RoutCompensation( $inCAM, $layers[0]->{"gROWname"}, "document" );
			CamLayer->Contourize( $inCAM, $lTmp, "x_or_y", "203200" );    # 203200 = max size of emptz space in InCAM which can be filled by surface

			$inCAM->COM( "merge_layers", "source_layer" => $lTmp, "dest_layer" => $lName );
			CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );

		}
		else {

			$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );
			CamLayer->Contourize( $inCAM, $lName );
		}

		CamLayer->WorkLayer( $inCAM, $lName );
		$inCAM->COM(
					 "sel_fill",
					 "type"                    => "predefined_pattern",
					 "cut_prims"               => "no",
					 "outline_draw"            => "no",
					 "outline_width"           => "0",
					 "outline_invert"          => "no",
					 "predefined_pattern_type" => "lines",
					 "indentation"             => "even",
					 "lines_angle"             => "45",
					 "lines_witdh"             => "1300",
					 "lines_dist"              => "660"
		);

		# Consider plated through hole
		if ( defined $self->{"pltThroughL"} ) {
			$inCAM->COM( "merge_layers", "source_layer" => $self->{"pltThroughL"}, "dest_layer" => $lName );
		}

		$layer->SetOutputLayer($lName);
	}
}

sub __PrepareMASK {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {
		my $lName = GeneralHelper->GetGUID();

		my $maskLayer = $layers[0]->{"gROWname"};

		# Select layer as work

		CamLayer->WorkLayer( $inCAM, $maskLayer );

		$inCAM->COM( "merge_layers", "source_layer" => $maskLayer, "dest_layer" => $lName );

		CamLayer->WorkLayer( $inCAM, $lName );

		CamLayer->NegativeLayerData( $self->{"inCAM"}, $lName, $self->{"profileLim"} );

		$layer->SetOutputLayer($lName);

		my $oRigidFlexType = JobHelper->GetORigidFlexType( $self->{"jobId"} ) if ( $self->{"pcbType"} eq EnumsGeneral->PcbType_RIGIDFLEXO );

		if (
			CamHelper->LayerExists( $inCAM, $self->{"jobId"}, "bend" )
			&& (
				$self->{"pcbType"} eq EnumsGeneral->PcbType_RIGIDFLEXI
				|| (    $self->{"pcbType"} eq EnumsGeneral->PcbType_RIGIDFLEXO
					 && $oRigidFlexType eq "flextop"
					 && $self->{"viewType"} eq Enums->View_FROMBOT )
				|| (    $self->{"pcbType"} eq EnumsGeneral->PcbType_RIGIDFLEXO
					 && $oRigidFlexType eq "flexbot"
					 && $self->{"viewType"} eq Enums->View_FROMTOP )

			)
		  )
		{
			CamLayer->WorkLayer( $inCAM, $self->{"bendAreaL"} );
			$inCAM->COM( "merge_layers", "source_layer" => $self->{"bendAreaL"}, "dest_layer" => $lName );
		}
	}
}

sub __PrepareFLEXMASK {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {
		my $lName = GeneralHelper->GetGUID();

		my $maskLayer = $layers[0]->{"gROWname"};

		# Select layer as work

		CamLayer->WorkLayer( $inCAM, $maskLayer );

		$inCAM->COM( "merge_layers", "source_layer" => $maskLayer, "dest_layer" => $lName );

		$layer->SetOutputLayer($lName);

	}
}

sub __PrepareCOVERLAY {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	my $cvrL = ( grep { $_->{"gROWname"} =~ /^cvrl/ } $layer->GetSingleLayers() )[0];

	$inCAM->COM(
				 "merge_layers",
				 "source_layer" => $self->{"cvrlsL"}->{ $cvrL->{"gROWname"} },
				 "dest_layer"   => $lName
	);
	$layer->SetOutputLayer($lName);

}

sub __PrepareSILK {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();

	if ( $layers[0] ) {
		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM( "merge_layers", "source_layer" => $layers[0]->{"gROWname"}, "dest_layer" => $lName );

		$layer->SetOutputLayer($lName);
	}
}

sub __PreparePLTDEPTHNC {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};
	my @layers = $layer->GetSingleLayers();

	my $lName = GeneralHelper->GetGUID();

	$inCAM->COM(
				 'create_layer',
				 layer     => $lName,
				 context   => 'misc',
				 type      => 'document',
				 polarity  => 'positive',
				 ins_layer => ''
	);

	# compensate
	foreach my $l (@layers) {
		my $outputParser = OutputParserNC->new( $inCAM, $jobId, $self->{"pdfStep"} );

		my $result = $outputParser->Prepare($l);

		next unless ( $result->GetResult() );

		foreach my $classResult ( $result->GetClassResults(1) ) {

			foreach my $classL ( $classResult->GetLayers() ) {

				# When angle tool, resize final tool dieameter by tool depth
				if (    $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKSURF
					 || $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKARC
					 || $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKPAD
					 || $classResult->GetType() eq OutParserEnums->Type_ZAXISSURFCHAMFER
					 || $classResult->GetType() eq OutParserEnums->Type_ZAXISSLOTCHAMFER )
				{

					my $DTMTool     = $classL->GetDataVal("DTMTool");
					my $newDiameter = tan( deg2rad( $DTMTool->GetAngle() / 2 ) ) * $DTMTool->GetDepth() * 2;

					my $resizeFeats = ( $classL->GetDataVal("DTMTool")->GetDrillSize() - $newDiameter * 1000 );

					CamLayer->WorkLayer( $inCAM, $classL->GetLayerName() );
					CamLayer->ResizeFeatures( $inCAM, -$resizeFeats );

				}

				$inCAM->COM( "merge_layers", "source_layer" => $classL->GetLayerName(), "dest_layer" => $lName );

			}
		}

		$outputParser->Clear();
	}

	# resize
	#CamLayer->WorkLayer( $inCAM, $lName );
	#$inCAM->COM( "sel_resize", "size" => -100, "corner_ctl" => "no" );

	$layer->SetOutputLayer($lName);

}

sub __PrepareSTIFFDEPTHNC {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM(
				 'create_layer',
				 layer     => $lName,
				 context   => 'misc',
				 type      => 'document',
				 polarity  => 'positive',
				 ins_layer => ''
	);

	# compensate
	foreach my $l (@layers) {

		my $outputParser = OutputParserNC->new( $inCAM, $jobId, $self->{"pdfStep"} );

		my $result = $outputParser->Prepare($l);

		next unless ( $result->GetResult() );

		foreach my $classResult ( $result->GetClassResults(1) ) {

			foreach my $classL ( $classResult->GetLayers() ) {

				# When angle tool, resize final tool dieameter by tool depth
				if (    $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKSURF
					 || $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKARC
					 || $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKPAD
					 || $classResult->GetType() eq OutParserEnums->Type_ZAXISSURFCHAMFER
					 || $classResult->GetType() eq OutParserEnums->Type_ZAXISSLOTCHAMFER )
				{

					my $DTMTool     = $classL->GetDataVal("DTMTool");
					my $newDiameter = tan( deg2rad( $DTMTool->GetAngle() / 2 ) ) * $DTMTool->GetDepth() * 2;

					my $resizeFeats = ( $classL->GetDataVal("DTMTool")->GetDrillSize() - $newDiameter * 1000 );

					CamLayer->WorkLayer( $inCAM, $classL->GetLayerName() );
					CamLayer->ResizeFeatures( $inCAM, -$resizeFeats );

				}

				$inCAM->COM( "merge_layers", "source_layer" => $classL->GetLayerName(), "dest_layer" => $lName );

			}
		}

		$outputParser->Clear();
	}

	# Copy negative of stiffener through NC to layer
	# Get all through stiffener from TOP/BOT
	my @routThrough = ();
	if ( $layers[0]->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill ) {
		
		@routThrough = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_stiffcMill ] );
		
	}
	elsif ( $layers[0]->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffsMill ) {
		
		@routThrough = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_stiffsMill ] );
		
	}

	die "No stiffener rout found" unless ( scalar(@routThrough) );

	foreach my $routL (@routThrough) {
		my $lTmp = CamLayer->RoutCompensation( $inCAM, $routL->{"gROWname"}, "document" );
		$inCAM->COM( "merge_layers", "source_layer" => $lTmp, "dest_layer" => $lName, "invert" => "yes" );

		CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );
	}

	$layer->SetOutputLayer($lName);

}

sub __PrepareNPLTDEPTHNC {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM(
				 'create_layer',
				 layer     => $lName,
				 context   => 'misc',
				 type      => 'document',
				 polarity  => 'positive',
				 ins_layer => ''
	);

	# compensate
	foreach my $l (@layers) {

		my $outputParser = OutputParserNC->new( $inCAM, $jobId, $self->{"pdfStep"} );

		my $result = $outputParser->Prepare($l);

		next unless ( $result->GetResult() );

		foreach my $classResult ( $result->GetClassResults(1) ) {

			foreach my $classL ( $classResult->GetLayers() ) {

				# When angle tool, resize final tool dieameter by tool depth
				if (    $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKSURF
					 || $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKARC
					 || $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKPAD
					 || $classResult->GetType() eq OutParserEnums->Type_ZAXISSURFCHAMFER
					 || $classResult->GetType() eq OutParserEnums->Type_ZAXISSLOTCHAMFER )
				{

					my $DTMTool     = $classL->GetDataVal("DTMTool");
					my $newDiameter = tan( deg2rad( $DTMTool->GetAngle() / 2 ) ) * $DTMTool->GetDepth() * 2;

					my $resizeFeats = ( $classL->GetDataVal("DTMTool")->GetDrillSize() - $newDiameter * 1000 );

					CamLayer->WorkLayer( $inCAM, $classL->GetLayerName() );
					CamLayer->ResizeFeatures( $inCAM, -$resizeFeats );

				}

				$inCAM->COM( "merge_layers", "source_layer" => $classL->GetLayerName(), "dest_layer" => $lName );

			}
		}

		$outputParser->Clear();
	}

	if ( defined $self->{"bendAreaL"} ) {

		CamLayer->WorkLayer( $inCAM, $self->{"bendAreaL"} );
		$inCAM->COM( "merge_layers", "source_layer" => $self->{"bendAreaL"}, "dest_layer" => $lName );
	}

	$layer->SetOutputLayer($lName);

}
#
#sub __PreparePLTTHROUGHNC {
#	my $self  = shift;
#	my $layer = shift;
#
#	unless ( $layer->HasLayers() ) {
#		return 0;
#	}
#
#	my $inCAM  = $self->{"inCAM"};
#	my $jobId  = $self->{"jobId"};
#	my @layers = $layer->GetSingleLayers();
#	my $lName  = GeneralHelper->GetGUID();
#
#	$inCAM->COM(
#				 'create_layer',
#				 layer     => $lName,
#				 context   => 'misc',
#				 type      => 'document',
#				 polarity  => 'positive',
#				 ins_layer => ''
#	);
#
#	my $pcbThick = CamJob->GetFinalPcbThick( $inCAM, $jobId );
#
#	# compensate
#	foreach my $l (@layers) {
#
#		my $outputParser = OutputParserNC->new( $inCAM, $jobId, $self->{"pdfStep"} );
#
#		my $result = $outputParser->Prepare($l);
#
#		next unless ( $result->GetResult() );
#
#		foreach my $classResult ( $result->GetClassResults(1) ) {
#
#			# When angle tool, resize final tool dieameter by tool depth
#			if (    $classResult->GetType() eq OutParserEnums->Type_ROUT
#				 || $classResult->GetType() eq OutParserEnums->Type_DRILL )
#			{
#				foreach my $classL ( $classResult->GetLayers() ) {
#
#					if ( $l->{"gROWlayer_type"} eq "rout" ) {
#
#						CamLayer->WorkLayer( $inCAM, $classL->GetLayerName() );
#						CamLayer->Contourize( $inCAM, $classL->GetLayerName(), "area", "25000" );
#					}
#
#					$inCAM->COM( "merge_layers", "source_layer" => $classL->GetLayerName(), "dest_layer" => $lName );
#				}
#
#			}
#			else {
#				foreach my $classL ( $classResult->GetLayers() ) {
#
#					my $DTMTool = $classL->GetDataVal("DTMTool");
#					next if ( $DTMTool->GetDepth() * 1000 < $pcbThick );
#
#					my $newDiameter = tan( deg2rad( $DTMTool->GetAngle() / 2 ) ) * ( $DTMTool->GetDepth() * 1000 - $pcbThick ) * 2;
#
#					my $resizeFeats = ( $classL->GetDataVal("DTMTool")->GetDrillSize() - $newDiameter );
#
#					CamLayer->WorkLayer( $inCAM, $classL->GetLayerName() );
#					CamLayer->ResizeFeatures( $inCAM, -$resizeFeats );
#
#					$inCAM->COM( "merge_layers", "source_layer" => $classL->GetLayerName(), "dest_layer" => $lName );
#				}
#			}
#		}
#
#		$outputParser->Clear();
#
#	}
#
#	# Addstifener
#	my $stiffL = undef;
#	if ( $self->{"viewType"} eq Enums->View_FROMTOP && CamHelper->LayerExists( $inCAM, $jobId, "stiffc" ) ) {
#		$stiffL = "stiffc";
#	}
#	elsif ( $self->{"viewType"} eq Enums->View_FROMBOT && CamHelper->LayerExists( $inCAM, $jobId, "stiffs" ) ) {
#		$stiffL = "stiffs";
#
#	}
#	if ( defined $stiffL ) {
#
#		my $tmp = GeneralHelper->GetGUID();
#		$inCAM->COM( "merge_layers", "source_layer" => $stiffL, "dest_layer" => $tmp, "invert" => "no" );
#		CamLayer->WorkLayer( $inCAM, $tmp );
#		CamLayer->Contourize( $inCAM, $tmp, "x_or_y", "0" );
#		$inCAM->COM( "merge_layers", "source_layer" => $tmp, "dest_layer" => $lName, "invert" => "yes" );
#		CamMatrix->DeleteLayer( $inCAM, $jobId, $tmp );
#	}
#
#	#	# Consider coverlay
#	#	my $coverlayL = undef;
#	#	if ( $self->{"viewType"} eq Enums->View_FROMTOP && CamHelper->LayerExists( $inCAM, $jobId, "cvrlc" ) ) {
#	#		$coverlayL = "cvrlc";
#	#	}
#	#	elsif ( $self->{"viewType"} eq Enums->View_FROMBOT && CamHelper->LayerExists( $inCAM, $jobId, "cvrls" ) ) {
#	#		$coverlayL = "cvrls";
#	#
#	#	}
#	#	if ( defined $self->{"cvrlsL"}->{$coverlayL} ) {
#	#		$inCAM->COM( "merge_layers", "source_layer" => $self->{"cvrlsL"}->{$coverlayL}, "dest_layer" => $lName, "invert" => "yes" );
#	#	}
#
#	#CamLayer->WorkLayer( $inCAM, $lName );
#	#$inCAM->COM( "sel_resize", "size" => -100, "corner_ctl" => "no" );
#
#	$layer->SetOutputLayer($lName);
#
#}

sub __PrepareNPLTTHROUGHNC {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM(
				 'create_layer',
				 layer     => $lName,
				 context   => 'misc',
				 type      => 'document',
				 polarity  => 'positive',
				 ins_layer => ''
	);

	my $pcbThick = CamJob->GetFinalPcbThick( $inCAM, $jobId );

	foreach my $l (@layers) {

		my %featHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $self->{"pdfStep"}, $l->{"gROWname"} );
		next if ( $featHist{"total"} == 0 );

		my $outputParser = OutputParserNC->new( $inCAM, $jobId, $self->{"pdfStep"} );

		my $result = $outputParser->Prepare($l);

		next unless ( $result->GetResult() );

		foreach my $classResult ( $result->GetClassResults(1) ) {

			# When angle tool, resize final tool dieameter by tool depth
			if (    $classResult->GetType() eq OutParserEnums->Type_DRILL
				 || $classResult->GetType() eq OutParserEnums->Type_ROUT )
			{
				foreach my $classL ( $classResult->GetLayers() ) {
					$inCAM->COM( "merge_layers", "source_layer" => $classL->GetLayerName(), "dest_layer" => $lName );
				}

			}
			else {
				foreach my $classL ( $classResult->GetLayers() ) {

					my $DTMTool = $classL->GetDataVal("DTMTool");
					next if ( $DTMTool->GetDepth() * 1000 < $pcbThick );

					my $newDiameter = tan( deg2rad( $DTMTool->GetAngle() / 2 ) ) * ( $DTMTool->GetDepth() * 1000 - $pcbThick ) * 2;

					my $resizeFeats = ( $classL->GetDataVal("DTMTool")->GetDrillSize() - $newDiameter );

					CamLayer->WorkLayer( $inCAM, $classL->GetLayerName() );
					CamLayer->ResizeFeatures( $inCAM, -$resizeFeats );

					$inCAM->COM( "merge_layers", "source_layer" => $classL->GetLayerName(), "dest_layer" => $lName );

				}
			}
		}

		$outputParser->Clear();

		# There can by small remains of pcb material, which is not milled
		# We don't want see this pieces in pdf, so delete tem from layer $lName
		# (pieces larger than 20% of total step area will be keepd)

		next unless ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill );

		CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );

		#$inCAM->COM( "merge_layers", "source_layer" => $lName, "dest_layer" => $lTmp );

		my $unitRTM = UniRTM->new( $inCAM, $self->{"jobId"}, $self->{"pdfStep"}, $l->{"gROWname"}, 0, 0, 1 );

		my @t1 = $unitRTM->GetMultiChainSeqList();

		grep { $_->GetChains() } @t1;

		my @t = grep { $_->GetCyclic() } @t1;

		my @outFeatsId =
		  map { $_->{"id"} } map { $_->GetOriFeatures() } grep { $_->GetCyclic() && !$_->GetIsInside() } $unitRTM->GetMultiChainSeqList();

		#my @outline = $unitRTM->GetOutlineChainSeqs();
		#my @outFeatsId =  map {$_->{"id"}} map { $_->GetOriFeatures() } @outline;

		CamFilter->SelectByFeatureIndexes( $inCAM, $self->{"jobId"}, \@outFeatsId );

		$inCAM->COM("sel_reverse");
		my $tmpRout = GeneralHelper->GetGUID();
		$inCAM->COM(
					 "sel_copy_other",
					 "dest"         => "layer_name",
					 "target_layer" => $tmpRout,
					 "invert"       => "no"
		);

		my $lTmp = CamLayer->RoutCompensation( $inCAM, $tmpRout, "document" );
		$inCAM->COM( 'delete_layer', "layer" => $tmpRout );

		# 1) do negative of prepared rout layer
		CamLayer->NegativeLayerData( $inCAM, $lTmp, $self->{"profileLim"} );
		CamLayer->WorkLayer( $inCAM, $lTmp );

		# 2) Select all 'small pieces'/surfaces and copy them negative to $lName
		CamLayer->Contourize( $inCAM, $lTmp );
		CamLayer->WorkLayer( $inCAM, $lTmp );

		# Select 'surface pieces'

		my $profileArea =
		  abs( $self->{"profileLim"}->{"xMin"} - $self->{"profileLim"}->{"xMax"} ) *
		  abs( $self->{"profileLim"}->{"yMin"} - $self->{"profileLim"}->{"yMax"} );

		my $maxArea = $profileArea / 2;    # pieces smaller than 10% of totalaarea will be keeped in pictore

		if ( CamFilter->BySurfaceArea( $inCAM, 0, $maxArea ) > 0 ) {
			CamLayer->CopySelOtherLayer( $inCAM, [$lName], 0, 2 );    # Resize features prevent ilegal surface after copy
		}

		$inCAM->COM( 'delete_layer', "layer" => $lTmp );

	}

	$layer->SetOutputLayer($lName);
}

sub __PrepareVIAFILL {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM  = $self->{"inCAM"};
	my @layers = $layer->GetSingleLayers();
	my $lName  = GeneralHelper->GetGUID();

	$inCAM->COM(
				 'create_layer',
				 layer     => $lName,
				 context   => 'misc',
				 type      => 'document',
				 polarity  => 'positive',
				 ins_layer => ''
	);

	# compensate
	foreach my $l (@layers) {

		$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );
	}

	CamLayer->WorkLayer( $inCAM, $lName );
	$inCAM->COM(
				 "sel_resize",
				 "size"       => -100,
				 "corner_ctl" => "no"
	);

	$layer->SetOutputLayer($lName);

}

sub __PrepareSTIFFENER {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 2) Copy negative of stiffener rout
	# layers can contain also tp layer and NC layer tpbr which define stiffener area too
	my $stiffL = ( grep { $_->{"gROWlayer_type"} eq "stiffener" } $layer->GetSingleLayers() )[0];

	# 1) Create full surface by profile
	my $lName = CamLayer->FilledProfileLim( $inCAM, $jobId, $self->{"pdfStep"}, 7000, $self->{"profileLim"} );

	return 0 unless ( defined $stiffL );

	my $tapeL = ( grep { $_->{"gROWname"} =~ /^tp[cs]$/ } $layer->GetSingleLayers() )[0];
	my @stiffRoutLs = CamDrilling->GetNCLayersByTypes(
													   $inCAM, $jobId,
													   [
														  EnumsGeneral->LAYERTYPE_nplt_stiffcAdhMill, EnumsGeneral->LAYERTYPE_nplt_stiffsAdhMill,
														  EnumsGeneral->LAYERTYPE_nplt_stiffcMill,    EnumsGeneral->LAYERTYPE_nplt_stiffsMill,
														  EnumsGeneral->LAYERTYPE_nplt_tapecMill,     EnumsGeneral->LAYERTYPE_nplt_tapesMill,
													   ]
	);
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@stiffRoutLs );
	my @stiffRoutL = grep { $_->{"gROWdrl_start"} eq $stiffL->{"gROWname"} && $_->{"gROWdrl_end"} eq $stiffL->{"gROWname"} } @stiffRoutLs;
	if ( defined $tapeL ) {
		my @tapeRoutL = grep { $_->{"gROWdrl_start"} eq $tapeL->{"gROWname"} && $_->{"gROWdrl_end"} eq $tapeL->{"gROWname"} } @stiffRoutLs;
		push( @stiffRoutL, @tapeRoutL ) if ( scalar(@tapeRoutL) );

		my @tapeBrRoutL = grep { $_->{"gROWname"} eq "ftpbr" } $layer->GetSingleLayers();
		push( @stiffRoutL, @tapeBrRoutL ) if ( scalar(@tapeBrRoutL) );
	}

	my $lNeg = GeneralHelper->GetGUID();
	CamMatrix->CreateLayer( $inCAM, $jobId, $lNeg, "document", "positive", 0 );
	foreach my $stiffRoutL (@stiffRoutL) {
		my $lTmp = CamLayer->RoutCompensation( $inCAM, $stiffRoutL->{"gROWname"}, "document" );
		$inCAM->COM(
					 "merge_layers",
					 "source_layer" => $lTmp,
					 "dest_layer"   => $lNeg,
					 "invert"       => "yes"
		);
		CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );
	}

	CamLayer->Contourize( $inCAM, $lNeg, "x_or_y", "203200" );    # 203200 = max size of emptz space in InCAM which can be filled by surface
	$inCAM->COM(
				 "merge_layers",
				 "source_layer" => $lNeg,
				 "dest_layer"   => $lName,
				 "invert"       => "no"
	);
	CamMatrix->DeleteLayer( $inCAM, $jobId, $lNeg );

	$layer->SetOutputLayer($lName);

}

sub __PrepareTAPE {
	my $self  = shift;
	my $layer = shift;

	unless ( $layer->HasLayers() ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Create full surface by profile
	my $lName = CamLayer->FilledProfileLim( $inCAM, $jobId, $self->{"pdfStep"}, 7000, $self->{"profileLim"} );

	# 2) Copy negative of stiffener rout
	my $tapeL = ( grep { $_->{"gROWname"} =~ /^tp(stiff)?[cs]/ } $layer->GetSingleLayers() )[0];
	my @tapeRoutLs =
	  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_tapecMill, EnumsGeneral->LAYERTYPE_nplt_tapesMill ] );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@tapeRoutLs );

	my $routL = GeneralHelper->GetGUID();

	my $tapeRoutL = ( grep { $_->{"gROWdrl_start"} eq $tapeL->{"gROWname"} && $_->{"gROWdrl_end"} eq $tapeL->{"gROWname"} } @tapeRoutLs )[0];
	my $lTmp1 = CamLayer->RoutCompensation( $inCAM, $tapeRoutL->{"gROWname"}, "document" );
	$inCAM->COM(
				 "merge_layers",
				 "source_layer" => $lTmp1,
				 "dest_layer"   => $routL
	);
	CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp1 );

	#	if ( CamHelper->LayerExists( $inCAM, $jobId, "ftapebr" ) ) {
	#
	#		my $lTmp2 = CamLayer->RoutCompensation( $inCAM, "ftapebr", "document" );
	#
	#		$inCAM->COM(
	#					 "merge_layers",
	#					 "source_layer" => $lTmp2,
	#					 "dest_layer"   => $routL
	#		);
	#		CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp2 );
	#	}

	CamLayer->Contourize( $inCAM, $routL, "x_or_y", "203200" );    # 203200 = max size of empty space in InCAM which can be filled by surface
	$inCAM->COM(
				 "merge_layers",
				 "source_layer" => $routL,
				 "dest_layer"   => $lName,
				 "invert"       => "yes"
	);
	CamMatrix->DeleteLayer( $inCAM, $jobId, $routL );

	$layer->SetOutputLayer($lName);
}

# Prepare negative data of bend area shape to special layer
# This layer can be used by another function which prepare standard layers
sub __GetOverlayBendArea {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $bendNegL = undef;

	if ( CamHelper->LayerExists( $inCAM, $jobId, "bend" )
		 && ( $self->{"pcbType"} eq EnumsGeneral->PcbType_RIGIDFLEXO || $self->{"pcbType"} eq EnumsGeneral->PcbType_RIGIDFLEXI ) )
	{

		$bendNegL = GeneralHelper->GetGUID();

		# 1) Create negative full surface from pure bend area

		$inCAM->COM( "merge_layers", "source_layer" => "bend", "dest_layer" => $bendNegL, "invert" => "yes" );
		CamLayer->WorkLayer( $inCAM, $bendNegL );

		# remove everythink (there could be text from schema) beyond active area if panel
		if ( $self->{"pdfStep"} eq "pdf_panel" ) {

			my $aa = ActiveArea->new( $inCAM, $jobId );

			my %pnlLim = ();
			$pnlLim{"xMin"} = 0 + $aa->BorderL();
			$pnlLim{"yMin"} = 0 + $aa->BorderB();
			$pnlLim{"xMax"} = $self->{"profileLim"}->{"xMax"} - $aa->BorderR();
			$pnlLim{"yMax"} = $self->{"profileLim"}->{"yMax"} - $aa->BorderT();

			CamLayer->ClipLayerData( $self->{"inCAM"}, $bendNegL, \%pnlLim );
			CamLayer->WorkLayer( $inCAM, $bendNegL );
		}

		$inCAM->COM( "sel_change_sym", "symbol" => "r10", "reset_angle" => "no" );   # r10 because when smaller diemater, countourze not work properly
		CamLayer->Contourize( $inCAM, $bendNegL, "x_or_y", "203200" );    # 203200 = max size of emptz space in InCAM which can be filled by surface
		CamLayer->WorkLayer( $inCAM, $bendNegL );

		# 2) Add depth nplt milling (which is responsible for milling bend area) as negative surface

		my @layers = $layerList->GetLayers( Enums->Type_NPLTDEPTHNC,
											( $self->{"viewType"} eq Enums->View_FROMTOP ? Enums->Visible_FROMTOP : Enums->Visible_FROMBOT ) );

		# compensate
		foreach my $l ( map { $_->GetSingleLayers() } @layers ) {

			my $outputParser = OutputParserNC->new( $inCAM, $jobId, $self->{"pdfStep"} );

			my $result = $outputParser->Prepare($l);

			next unless ( $result->GetResult() );

			foreach my $classResult ( $result->GetClassResults(1) ) {

				foreach my $classL ( $classResult->GetLayers() ) {

					# When angle tool, resize final tool dieameter by tool depth
					if (    $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKSURF
						 || $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKARC
						 || $classResult->GetType() eq OutParserEnums->Type_COUNTERSINKPAD
						 || $classResult->GetType() eq OutParserEnums->Type_ZAXISSURFCHAMFER
						 || $classResult->GetType() eq OutParserEnums->Type_ZAXISSLOTCHAMFER )
					{

						my $DTMTool     = $classL->GetDataVal("DTMTool");
						my $newDiameter = tan( deg2rad( $DTMTool->GetAngle() / 2 ) ) * $DTMTool->GetDepth() * 2;

						my $resizeFeats = ( $classL->GetDataVal("DTMTool")->GetDrillSize() - $newDiameter * 1000 );

						CamLayer->WorkLayer( $inCAM, $classL->GetLayerName() );
						CamLayer->ResizeFeatures( $inCAM, -$resizeFeats );

					}

					CamLayer->WorkLayer( $inCAM, $classL->GetLayerName() );
					if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, "transition_zone", "" ) ) {
						$inCAM->COM(
									 "merge_layers",
									 "source_layer" => $classL->GetLayerName(),
									 "dest_layer"   => $bendNegL,
									 "invert"       => "yes"
						);
					}
				}
			}

			$outputParser->Clear();
		}
	}

	return $bendNegL;

}

# Prepare positive data of covelay area shape to special layer
# This layer can be used by another function which prepare standard layers
sub __GetOverlayCoverlays {
	my $self      = shift;
	my $layerlist = shift;

	my %coverLayers = ();

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @covelays = $layerlist->GetLayers( Enums->Type_COVERLAY );

	return \%coverLayers if ( !scalar(@covelays) );

	foreach my $layer (@covelays) {

		next unless ( $layer->HasLayers() );

		my @layers = $layer->GetSingleLayers();

		# 1) Create full surface by profile
		my $lName = CamLayer->FilledProfileLim( $inCAM, $jobId, $self->{"pdfStep"}, 7000, $self->{"profileLim"} );

		# 2) Copy coverlay milling
		my $cvrL = ( grep { $_->{"gROWname"} =~ /^cvrl/ } $layer->GetSingleLayers() )[0];
		my @cvrRoutLs =
		  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_cvrlycMill, EnumsGeneral->LAYERTYPE_nplt_cvrlysMill ] );
		CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@cvrRoutLs );

		my $cvrRoutL = ( grep { $_->{"gROWdrl_start"} eq $cvrL->{"gROWname"} && $_->{"gROWdrl_end"} eq $cvrL->{"gROWname"} } @cvrRoutLs )[0];
		my $lTmp = CamLayer->RoutCompensation( $inCAM, $cvrRoutL->{"gROWname"}, "document" );
		CamLayer->Contourize( $inCAM, $lTmp, "x_or_y", "203200" );    # 203200 = max size of emptz space in InCAM which can be filled by surface
		$inCAM->COM( "merge_layers", "source_layer" => $lTmp, "dest_layer" => $lName, "invert" => "yes" );
		CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );

		# 3) If exist coverlay pins, final shape of coverlay depands on NPLT rout layers
		if ( CamHelper->LayerExists( $inCAM, $jobId, "cvrlpins" ) ) {

			my @NPLTNClayers = grep { defined $_->{"type"} && $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill } $layer->GetSingleLayers();

			foreach my $npltL (@NPLTNClayers) {

				my $routL = CamLayer->RoutCompensation( $inCAM, $npltL->{"gROWname"}, "document" );
				$inCAM->COM( "merge_layers", "source_layer" => $routL, "dest_layer" => $lName, "invert" => "yes" );
				CamMatrix->DeleteLayer( $inCAM, $jobId, $routL );
			}

			# Countourize whole layers and keep surfaces in bend area only
			CamLayer->Contourize( $inCAM, $lName, "x_or_y", "0" );
			CamLayer->WorkLayer( $inCAM, $lName );

			if ( CamFilter->SelectByReferenece( $inCAM, $jobId, "touch", $lName, undef, undef, undef, "bend" ) ) {

				$inCAM->COM('sel_reverse');
				if ( CamLayer->GetSelFeaturesCnt($inCAM) ) {
					CamLayer->DeleteFeatures($inCAM);
				}
			}
		}

		CamLayer->WorkLayer( $inCAM, $lName );
		CamLayer->Contourize( $inCAM, $lName, "x_or_y", "0" );

		$coverLayers{ $cvrL->{"gROWname"} } = $lName;
	}

	return \%coverLayers;

}

# Prepare negative data of all plt through holes
# This layer can be used for create cutouts in material layer, copper layer , solder mask layer etc
sub __GetPltThroughCuts {
	my $self      = shift;
	my $layerList = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @troughLayers = map { $_->GetSingleLayers() } grep { $_->GetType() eq Enums->Type_PLTTHROUGHNC } $layerList->GetLayers();

	my $pcbThick = undef;
	my $lName    = undef;

	if (@troughLayers) {

		$pcbThick = CamJob->GetFinalPcbThick( $inCAM, $jobId );
		$lName = GeneralHelper->GetGUID();

		$inCAM->COM(
					 'create_layer',
					 layer     => $lName,
					 context   => 'misc',
					 type      => 'document',
					 polarity  => 'positive',
					 ins_layer => ''
		);
	}

	foreach my $l (@troughLayers) {

		my $outputParser = OutputParserNC->new( $inCAM, $jobId, $self->{"pdfStep"} );

		my $result = $outputParser->Prepare($l);

		next unless ( $result->GetResult() );

		foreach my $classResult ( $result->GetClassResults(1) ) {

			# When angle tool, resize final tool dieameter by tool depth
			if (    $classResult->GetType() eq OutParserEnums->Type_ROUT
				 || $classResult->GetType() eq OutParserEnums->Type_DRILL )
			{
				foreach my $classL ( $classResult->GetLayers() ) {

					if ( $l->{"gROWlayer_type"} eq "rout" ) {

						CamLayer->WorkLayer( $inCAM, $classL->GetLayerName() );
						CamLayer->Contourize( $inCAM, $classL->GetLayerName(), "area", "25000" );
					}

					$inCAM->COM( "merge_layers", "source_layer" => $classL->GetLayerName(), "dest_layer" => $lName, "invert" => "yes" );
				}

			}
			else {
				foreach my $classL ( $classResult->GetLayers() ) {

					my $DTMTool = $classL->GetDataVal("DTMTool");
					next if ( $DTMTool->GetDepth() * 1000 < $pcbThick );

					my $newDiameter = tan( deg2rad( $DTMTool->GetAngle() / 2 ) ) * ( $DTMTool->GetDepth() * 1000 - $pcbThick ) * 2;

					my $resizeFeats = ( $classL->GetDataVal("DTMTool")->GetDrillSize() - $newDiameter );

					CamLayer->WorkLayer( $inCAM, $classL->GetLayerName() );
					CamLayer->ResizeFeatures( $inCAM, -$resizeFeats );

					$inCAM->COM( "merge_layers", "source_layer" => $classL->GetLayerName(), "dest_layer" => $lName, "invert" => "yes" );
				}
			}
		}

		$outputParser->Clear();

	}

	return $lName;

}

sub __CountersinkCheck {
	my $self      = shift;
	my $layer     = shift;
	my $layerComp = shift;

	if (    $layer->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bMillTop
		 && $layer->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_bMillTop
		 && $layer->{"type"} ne EnumsGeneral->LAYERTYPE_plt_bMillBot
		 && $layer->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_bMillBot )
	{
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stepName = $self->{"pdfStep"};
	$stepName =~ s/pdf_//;
	my $lName = $layer->{"gROWname"};

	my $result = 1;

	#get depths for all diameter

	# load UniDTM for layer
	my $unitDTM = UniDTM->new( $inCAM, $jobId, $stepName, $lName, 1 );

	# 2) check if tool depth is set
	foreach my $t ( $unitDTM->GetUniqueTools() ) {

		if ( $t->GetSpecial() && defined $t->GetAngle() && $t->GetAngle() > 0 ) {

			#vypocitej realne odebrani materialu na zaklade hloubky pojezdu/vrtani

			my $toolAngl = $t->GetAngle();

			my $newDiameter = tan( deg2rad( $toolAngl / 2 ) ) * $t->GetDepth();
			$newDiameter *= 2;       #whole diameter
			$newDiameter *= 1000;    #um
			$newDiameter = int($newDiameter);

			# now change old diameter to new diameter
			CamLayer->WorkLayer( $inCAM, $layerComp );
			my @syms = ( "r" . $t->GetDrillSize() );
			CamFilter->BySymbols( $inCAM, \@syms );
			$inCAM->COM( "sel_change_sym", "symbol" => "r" . $newDiameter, "reset_angle" => "no" );
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
