
#-------------------------------------------------------------------------------------------#
# Description: Module create image preview of pcb based on physical layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::FinalPreview;

#3th party library
use strict;
use warnings;
use List::Util qw(first);
use Scalar::Util qw(blessed);
use Storable qw(dclone);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::LayerData::LayerDataList';
use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerColor';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::OutputPdf';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::OutputPrepare';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::Helper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::Enums';
use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::Enums' => 'PrevEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"step"}     = shift;
	$self->{"viewType"} = shift;         # TOP/BOT
	$self->{"default"}  = shift;         # indicate this class/pdf step is d
	$self->{"cloned"}   = shift // 0;    # Fell if this object is cloned;

	$self->{"pdfStep"} = ( $self->{"default"} ? "default" : $self->{"step"} ) . "_pdf";
	$self->{"outputPdf"} = OutputPdf->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"} );
	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".png";

	$self->{"stepPrepared"} = 0;

	return $self;
}

# Create image preview
sub Prepare {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $parent = first { $_->{"type"} eq 'parent' } @{ $self->{"steps"} };
	my @layerFilter = map { $_->{"gROWname"} } CamJob->GetBoardLayers( $inCAM, $jobId );
	CamStep->CreateFlattenStep( $inCAM, $jobId, $self->{"step"}, $self->{"pdfStep"}, 1, \@layerFilter );

	CamHelper->SetStep( $self->{"inCAM"}, $self->{"pdfStep"} );

	# get all board layers
	my @layers = CamJob->GetBoardLayers( $self->{"inCAM"}, $self->{"jobId"} );

	# check if gold plating exist - layer c, s and set indicator gold_plating => 1 to layer
	$self->__SetGoldPlating( \@layers );

	# add nc info to nc layers
	my @nclayers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;
	CamDrilling->AddNCLayerType( \@nclayers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@nclayers );

	$self->{"layerList"} = LayerDataList->new( $self->{"viewType"} );
	$self->{"layerList"}->InitLayers( $self->{"inCAM"}, $self->{"jobId"}, \@layers );
	$self->{"layerList"}->InitSurfaces( $self->__DefineSurfaces() );

	# set layer list

	my $OutputPrepare = OutputPrepare->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"viewType"}, $self->{"pdfStep"} );
	$OutputPrepare->PrepareLayers( $self->{"layerList"} );

	$self->{"stepPrepared"} = 1;

	return 1;
}

# Create image preview
sub Create {
	my $self           = shift;
	my $message        = shift;
	my $reducedQuality = shift;

	CamHelper->SetStep( $self->{"inCAM"}, $self->{"pdfStep"} );

	$self->{"outputPdf"}->Output( $self->{"layerList"}, $reducedQuality );

	return 1;
}

# Return path of image
sub GetOutput {
	my $self = shift;
	
	die "Layers are not prepared" unless($self->{"stepPrepared"});

	return $self->{"outputPdf"}->GetOutput();
}

# Clone thic objcet + prepared step
# 1) Copy prepared step to new step
# 2) If new setep is nested step od current step, pick 1 arbitrary nested step, cut data around this step
# 3) Clone and return thic object
sub ClonePrepared {
	my $self         = shift;
	my $newStep      = shift;
	my $cutByProfile = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $newPdftep = $newStep . "_pdf";

	# 1) Copy prepared step to new step
	CamStep->CopyStep( $inCAM, $jobId, $self->{"pdfStep"}, $jobId, $newPdftep );

	# 2) Remove all behind new step profile
	if ($cutByProfile) {
		my $prof = GeneralHelper->GetGUID();
		my $sr = first { $_->{"stepName"} eq $newStep } CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $self->{"step"} );

		CamHelper->SetStep( $inCAM, $newPdftep );
		CamStepRepeat->AddStepAndRepeat( $inCAM, $newPdftep, $sr->{"stepName"}, $sr->{"originX"}, $sr->{"originY"}, $sr->{"angle"} );
		CamHelper->SetStep( $inCAM, $newStep );
		$inCAM->COM( "profile_to_rout", "layer" => $prof, "width" => 200 );
		CamHelper->SetStep( $inCAM, $newPdftep );
		CamLayer->FlatternLayer( $inCAM, $jobId, $newPdftep, $prof );
		CamStep->CreateProfileByLayer( $inCAM, $newPdftep, $prof );
		$inCAM->COM('sredit_del_steps');

		foreach my $lData ( $self->{"layerList"}->GetOutputLayers() ) {
			CamLayer->ClipAreaByProf( $inCAM, $lData->GetOutputLayer(), 0, 0, 1 );    # do not clip outline rout 3mm behuind profile
		}

		CamMatrix->DeleteLayer( $inCAM, $jobId, $prof );
	}

	# 3) Clone this object (by creating new)

	my $className = blessed $self;
	my $finPreview = $className->new( $inCAM, $jobId, $newStep, $self->{"viewType"}, 0, 1 );
	$finPreview->{"stepPrepared"} = $self->{"stepPrepared"};
	$finPreview->{"layerList"}    = dclone( $self->{"layerList"} );

	return $finPreview;
}

sub Clean {
	my $self        = shift;
	my $cleanLayers = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamStep->DeleteStep( $inCAM, $jobId, $self->{"pdfStep"} );

	if ( !$self->{"cloned"} ) {

		# delete helper layers
		foreach my $lData ( $self->{"layerList"}->GetOutputLayers() ) {

			$inCAM->COM( 'delete_layer', "layer" => $lData->GetOutputLayer() );
		}
	}

}

#sub __ConvertPdfToPng {
#	my $self       = shift;
#	my $outputPath = shift;
#
#	my $result = 1;
#
#	my @cmd = ( EnumsPaths->InCAM_3rdScripts . "im\\convert.exe" );
#	push( @cmd, "-density 200" );
#	push( @cmd, $outputPath );
#	push( @cmd, "-shave 20x20 -trim -shave 5x5" );
#	push( @cmd, "--alpha off" );
#
#	push( @cmd, $self->{"outputPath"} );
#
#	my $cmdStr = join( " ", @cmd );
#
#	my $systeMres = system($cmdStr);
#
#	unlink($outputPath);
#
#	if ( $systeMres > 0 ) {
#		$result = 0;
#	}
#
#	return;
#}

sub __InitLayers {
	my $self  = shift;
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = CamJob->GetBoardLayers( $self->{"inCAM"}, $self->{"jobId"} );

	# check if gold plating exist - layer c, s and set indicator gold_plating => 1 to layer
	$self->__SetGoldPlating( \@layers );

	# add nc info to nc layers
	my @nclayers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;
	CamDrilling->AddNCLayerType( \@nclayers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@nclayers );

	$self->{"layerList"} = LayerDataList->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"viewType"}, );
	$self->{"layerList"}->InitLayers( \@layers );
	$self->{"layerList"}->InitSurfaces( $self->__DefineSurfaces() );

}

# Each pcb layer is represent bz color/texture
# this method is responsible for choose this color/texture, transparency, 3d effects, etc..
sub __DefineSurfaces {
	my $self = shift;
	my %clrs = ();

	# final surface of pcb
	my $surface  = HegMethods->GetPcbSurface( $self->{"jobId"} );
	my $flex     = JobHelper->GetIsFlex( $self->{"jobId"} );
	my $flexType = JobHelper->GetPcbType( $self->{"jobId"} );
	my $layerCnt = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	# Pcb Rigid material

	my $rigidMatClr = LayerColor->new( PrevEnums->Surface_COLOR, ( $layerCnt > 2 ? "193,201,128" : "212,220,140" ) );
	$clrs{ Enums->Type_RIGIDMATOUTER } = $rigidMatClr;
	$clrs{ Enums->Type_RIGIDMATINNER } = $rigidMatClr;

	my $mat = HegMethods->GetMaterialKind( $self->{"jobId"} );
	if ( $mat =~ /al_core/i ) {

		if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {
			$rigidMatClr->SetType( PrevEnums->Surface_COLOR );
			$rigidMatClr->SetColor("240, 240, 240");
		}
		elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

			$rigidMatClr->SetType( PrevEnums->Surface_TEXTURE );
			$rigidMatClr->SetTexture( Enums->Texture_CHEMTINALU );
		}
	}
	elsif ( $mat =~ /cu_core/i ) {

		if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {
			$rigidMatClr->SetType( PrevEnums->Surface_COLOR );
			$rigidMatClr->SetColor("240, 240, 240");
		}
		elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

			$rigidMatClr->SetType( PrevEnums->Surface_TEXTURE );
			$rigidMatClr->SetTexture( Enums->Texture_CU );
		}
	}

	# Pcb Flex material

	my $flexMatClr = LayerColor->new( PrevEnums->Surface_COLOR, "220,191,0" );
	$clrs{ Enums->Type_FLEXMATOUTER } = $flexMatClr;
	$clrs{ Enums->Type_FLEXMATINNER } = $flexMatClr;

	$flexMatClr->SetOpaque(60);

	# Via fill
	my $viaFillClr = LayerColor->new( PrevEnums->Surface_COLOR, "97,47,4" );
	$clrs{ Enums->Type_VIAFILL } = $viaFillClr;

	# Outer cu
	my $outerCuClr = LayerColor->new( PrevEnums->Surface_COLOR, "232,141,77" );

	$clrs{ Enums->Type_OUTERCU } = $outerCuClr;

	# Inner cu
	my $innerCuClr = LayerColor->new( PrevEnums->Surface_COLOR, "232,141,77" );
	$clrs{ Enums->Type_INNERCU } = $innerCuClr;

	# Outer surface

	my $outerSurfaceClr = LayerColor->new( PrevEnums->Surface_TEXTURE, Enums->Texture_CU );
	$clrs{ Enums->Type_OUTERSURFACE } = $outerSurfaceClr;

	if ( $surface =~ /^[ab]$/i ) {

		# HAL + HAL Pbfree
		$outerSurfaceClr->SetTexture( Enums->Texture_HAL );
	}
	elsif ( $surface =~ /^[cj]$/i ) {

		# Chemical tin + chemical silver
		$outerSurfaceClr->SetTexture( Enums->Texture_CHEMTINALU );
	}
	elsif ( $surface =~ /^[ig]$/i ) {

		# Chemical gold + hard gold
		$outerSurfaceClr->SetTexture( Enums->Texture_GOLD );

	}
	else {

		$outerSurfaceClr->SetTexture( Enums->Texture_CU );
	}

	# Gold fingers

	my $goldFingerClr = LayerColor->new( PrevEnums->Surface_TEXTURE, Enums->Texture_GOLD );
	$clrs{ Enums->Type_GOLDFINGER } = $goldFingerClr;

	# Peelable mask

	my $peelableClr = LayerColor->new( PrevEnums->Surface_TEXTURE, Enums->Texture_PEELABLE );
	$clrs{ Enums->Type_PEELABLE } = $peelableClr;

	# Grafit paste

	my $grafitClr = LayerColor->new( PrevEnums->Surface_TEXTURE, Enums->Texture_GRAFIT );
	$clrs{ Enums->Type_GRAFIT } = $grafitClr;

	# Mask color
	my ( $clrKey, $clrRGB ) = $self->__GetMaskColor();
	my $maskClr = LayerColor->new( PrevEnums->Surface_COLOR );
	$clrs{ Enums->Type_MASK } = $maskClr;

	if ( defined $clrKey ) {

		$maskClr->SetColor($clrRGB);

		# Set opaque for different color
		if ( $clrKey eq "W" ) {

			# White

			$maskClr->SetOpaque(92);
		}
		elsif ( $clrKey eq "B" ) {

			# Black

			$maskClr->SetOpaque(89);
		}
		elsif ( $clrKey eq "M" ) {

			# Blue

			$maskClr->SetOpaque(85);
		}
		elsif ( $clrKey eq "G" ) {

			# Green SMD Flex

			$maskClr->SetOpaque(45);
		}
		else {
			# other

			$maskClr->SetOpaque(70);
		}

	}

	# Pcb Flex Mask color

	my $flexMaskClr = LayerColor->new( PrevEnums->Surface_COLOR, "0,132,0" );
	$clrs{ Enums->Type_FLEXMASK } = $flexMaskClr;
	$clrs{ Enums->Type_FLEXMASK } = $flexMaskClr;

	$flexMaskClr->SetOpaque(70);

	# Coverlay color

	my $coverlayClr = LayerColor->new( PrevEnums->Surface_COLOR, "212,113,0" );
	$clrs{ Enums->Type_COVERLAY } = $coverlayClr;

	$coverlayClr->SetOpaque(45);

	#$coverlayClr->Set3DEdges(2);

	# Silk color

	my ( $silkClrKey, $silkClrRGB ) = $self->__GetSilkColor();
	my $silkClr = LayerColor->new( PrevEnums->Surface_COLOR );
	$clrs{ Enums->Type_SILK } = $silkClr;

	if ( defined $silkClrKey ) {
		$silkClr->SetColor($silkClrRGB);
	}

	# Silk color 2 (second selkscreen)

	my ( $silk2ClrKey, $silk2ClrRGB ) = $self->__GetSilkColor(1);
	my $silk2Clr = LayerColor->new( PrevEnums->Surface_COLOR );
	$clrs{ Enums->Type_SILK2 } = $silk2Clr;

	if ( defined $silk2ClrKey ) {
		$silk2Clr->SetColor($silk2ClrRGB);
	}

	# Depth NC plated - same as surface but dareker

	my $pltDepthClr = LayerColor->new();
	$clrs{ Enums->Type_PLTDEPTHNC } = $pltDepthClr;

	$pltDepthClr->SetType( $outerSurfaceClr->GetType() );
	$pltDepthClr->SetBrightness( $outerSurfaceClr->GetBrightness() + 10 );

	if ( $outerSurfaceClr->GetType() eq PrevEnums->Surface_COLOR ) {
		$pltDepthClr->SetColor( $outerSurfaceClr->GetColor() );
	}
	else {
		$pltDepthClr->SetTexture( $outerSurfaceClr->GetTexture() );
	}

	# Depth NC nonplated - same as material pcb but darker

	my $npltDepthClr = LayerColor->new();
	$clrs{ Enums->Type_NPLTDEPTHNC } = $npltDepthClr;

	$npltDepthClr->SetType( $rigidMatClr->GetType() );
	$npltDepthClr->SetBrightness( $rigidMatClr->GetBrightness() + 5 );

	if ( $rigidMatClr->GetType() eq PrevEnums->Surface_COLOR ) {

		$npltDepthClr->SetColor( $rigidMatClr->GetColor() );
		$npltDepthClr->SetOverlayTexture( Enums->TextureOverlay_MILLING );
	}
	else {

		$npltDepthClr->SetTexture( $rigidMatClr->GetTexture() );
	}

	# Al if Al core and depth milling from top, set AL texture
	if ( $mat =~ /al_core/i && $self->{"viewType"} eq Enums->View_FROMTOP ) {

		$npltDepthClr->SetType( PrevEnums->Surface_TEXTURE );
		$npltDepthClr->SetTexture( Enums->Texture_CHEMTINALU );
	}

	# Stiffener
	my $stiffClr = LayerColor->new( PrevEnums->Surface_COLOR, "185,193,123" );
	$clrs{ Enums->Type_STIFFENER } = $stiffClr;

	# PLT Through NC

	my $pltThroughNcClr = LayerColor->new( PrevEnums->Surface_COLOR );
	$clrs{ Enums->Type_PLTTHROUGHNC } = $pltThroughNcClr;

	# NPLT Through NC

	my $npltThroughNcClr = LayerColor->new( PrevEnums->Surface_COLOR );
	$clrs{ Enums->Type_NPLTTHROUGHNC } = $npltThroughNcClr;

	return \%clrs;

}

sub __GetMaskColor {
	my $self = shift;

	my %pcbMask = Helper->GetMaskColor( $self->{"inCAM"}, $self->{"jobId"} );
	my %pcbMask2 = Helper->GetMaskColor( $self->{"inCAM"}, $self->{"jobId"}, 1 );    # return second color mask

	# Decide which mask color is on top
	my $pcbMaskVal;
	if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

		$pcbMaskVal = defined $pcbMask2{"top"} && $pcbMask2{"top"} ne "" ? $pcbMask2{"top"} : $pcbMask{"top"};

	}
	elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

		$pcbMaskVal = defined $pcbMask2{"bot"} && $pcbMask2{"bot"} ne "" ? $pcbMask2{"bot"} : $pcbMask{"bot"};
	}

	unless ($pcbMaskVal) {
		return ();
	}

	my %colorMap = ();
	$colorMap{"Z"} = "0,115,42";       # green
	$colorMap{"B"} = "59,59,59";       # black
	$colorMap{"W"} = "250,250,250";    # white
	$colorMap{"M"} = "0,70,113";       # blue
	$colorMap{"T"} = "255,255,255";    # ??
	$colorMap{"R"} = "196,0,28";       # red
	$colorMap{"G"} = "0,100,11";       # green SD

	die "Not defined mask color: $pcbMaskVal" unless ( defined $colorMap{$pcbMaskVal} );

	return ( $pcbMaskVal, $colorMap{$pcbMaskVal} );
}

sub __GetSilkColor {
	my $self       = shift;
	my $secondSilk = shift;            # return color for scend silkscreen

	my %pcbSilk = Helper->GetSilkColor( $self->{"inCAM"}, $self->{"jobId"}, $secondSilk );
	my $pcbSilkVal;

	if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

		$pcbSilkVal = $pcbSilk{"top"};

	}
	elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

		$pcbSilkVal = $pcbSilk{"bot"};
	}

	unless ($pcbSilkVal) {
		return ();
	}

	my %colorMap = ();
	$colorMap{"B"} = "241,241,228";    #white
	$colorMap{"Z"} = "255,247,0";      #yellow
	$colorMap{"C"} = "74,74,74";       # black

	return ( $pcbSilkVal, $colorMap{$pcbSilkVal} );
}

# go through board layers, and if there is gold_plating attribute, add .gold_plating => 1, to layer
sub __SetGoldPlating {
	my $self        = shift;
	my @boardLayers = @{ shift(@_) };

	if ( HegMethods->GetTypeOfPcb( $self->{"jobId"} ) ne "Neplatovany" ) {

		my $c = ( grep { $_->{"gROWname"} eq "c" } @boardLayers )[0];
		my $s = ( grep { $_->{"gROWname"} eq "s" } @boardLayers )[0];

		foreach my $l ( ( $c, $s ) ) {

			unless ($l) {
				next;
			}

			my %hist = CamHistogram->GetAttHistogram( $self->{"inCAM"}, $self->{"jobId"}, "panel", $l->{"gROWname"} );
			if ( $hist{".gold_plating"} ) {
				$l->{".gold_plating"} = 1;
			}
		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

