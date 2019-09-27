
#-------------------------------------------------------------------------------------------#
# Description: Module create image preview of pcb based on physical layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::FinalPreview;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::LayerData::LayerDataList';
use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerColor';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::OutputPdf';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::OutputPrepare';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::Helper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::FinalPreview::Enums';
use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::Enums' => 'PrevEnums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelpers';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"pdfStep"} = shift;

	$self->{"viewType"} = shift;    # TOP/BOT

	$self->{"layerList"}     = LayerDataList->new( $self->{"viewType"} );
	$self->{"outputPrepare"} = OutputPrepare->new( $self->{"viewType"}, $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"} );
	$self->{"outputPdf"}     = OutputPdf->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"} );
	$self->{"outputPath"}    = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".png";


	return $self;
}

# Create image preview
sub Create {
	my $self    = shift;
	my $message = shift;

	# get all board layers
	my @layers = CamJob->GetBoardLayers( $self->{"inCAM"}, $self->{"jobId"} );

	# check if gold plating exist - layer c, s and set indicator gold_plating => 1 to layer
	$self->__SetGoldPlating( \@layers );

	# add nc info to nc layers
	my @nclayers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;
	CamDrilling->AddNCLayerType( \@nclayers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@nclayers );

	# set layer list
	$self->{"layerList"}->SetLayers( \@layers );
	$self->{"layerList"}->SetColors( $self->__PrepareColors() );

	$self->{"outputPrepare"}->PrepareLayers( $self->{"layerList"} );
	$self->{"outputPdf"}->Output( $self->{"layerList"} );

	return 1;
}

# Return path of image
sub GetOutput {
	my $self = shift;

	return $self->{"outputPdf"}->GetOutput();
}

sub __ConvertPdfToPng {
	my $self       = shift;
	my $outputPath = shift;

	my $result = 1;

	my @cmd = ( EnumsPaths->InCAM_3rdScripts . "im\\convert.exe" );
	push( @cmd, "-density 200" );
	push( @cmd, $outputPath );
	push( @cmd, "-shave 20x20 -trim -shave 2x2" );
	push( @cmd, "--alpha off" );

	push( @cmd, $self->{"outputPath"} );

	my $cmdStr = join( " ", @cmd );

	my $systeMres = system($cmdStr);

	unlink($outputPath);

	if ( $systeMres > 0 ) {
		$result = 0;
	}

	return;
}

# Each pcb layer is represent bz color/texture
# this method is responsible for choose this color/texture, transparency, 3d effects, etc..
sub __PrepareColors {
	my $self = shift;
	my %clrs = ();

	# final surface of pcb
	my $surface = HegMethods->GetPcbSurface( $self->{"jobId"} );
	my $flex = JobHelper->GetIsFlex($self->{"jobId"});
	my $flexType = JobHelper->GetPcbType($self->{"jobId"});

	# Pcb material

	my $pcbMatClr = LayerColor->new(PrevEnums->Surface_COLOR, "226,235,150" );
	$clrs{ Enums->Type_PCBMAT } = $pcbMatClr;

	my $mat = HegMethods->GetMaterialKind( $self->{"jobId"} );
	if ( $mat =~ /al/i ) {

		$pcbMatClr->SetType(PrevEnums->Surface_TEXTURE );

		if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

			$pcbMatClr->SetTexture( Enums->Texture_CU );
		}
		elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

			$pcbMatClr->SetTexture( Enums->Texture_CHEMTINALU );
		}
	}
	elsif ( $mat =~ /cu/i ) {

		$pcbMatClr->SetType(PrevEnums->Surface_TEXTURE );
		$pcbMatClr->SetTexture( Enums->Texture_CU );

	}elsif($flex && $flexType eq EnumsGeneral-> )
	
	# Via fill
	my $viaFillClr = LayerColor->new(PrevEnums->Surface_COLOR, "97,47,4" );
	$clrs{ Enums->Type_VIAFILL } = $viaFillClr;

	# Outer cu
	my $outerCuClr = undef;

	if ( $surface eq "" || $surface =~ /^n$/i ) {

		$outerCuClr = LayerColor->new(PrevEnums->Surface_TEXTURE, Enums->Texture_CU );
	}
	else {

		$outerCuClr = LayerColor->new(PrevEnums->Surface_COLOR, "232,141,77" );
	}
	

	$clrs{ Enums->Type_OUTERCU } = $outerCuClr;
	$outerCuClr->Set3DEdges(1);

	# Outer surface

	my $outerSurfaceClr = LayerColor->new(PrevEnums->Surface_TEXTURE, Enums->Texture_CU );
	$clrs{ Enums->Type_OUTERSURFACE } = $outerSurfaceClr;

	if ( $surface =~ /^[ab]$/i   ) {
		# HAL + HAL Pbfree
		$outerSurfaceClr->SetTexture( Enums->Texture_HAL );
	}
	elsif ( $surface =~ /^[cj]$/i  ) {
		# Chemical tin + chemical silver
		$outerSurfaceClr->SetTexture( Enums->Texture_CHEMTINALU );
	}
	elsif ( $surface =~ /^[ig]$/i ) {
		# Chemical gold + hard gold
		$outerSurfaceClr->SetTexture( Enums->Texture_GOLD );
	}
 

	# Gold fingers

	my $goldFingerClr = LayerColor->new(PrevEnums->Surface_TEXTURE, Enums->Texture_GOLD );
	$clrs{ Enums->Type_GOLDFINGER } = $goldFingerClr;
	 
	
	# Peelable mask
	
	my $peelableClr = LayerColor->new(PrevEnums->Surface_TEXTURE, Enums->Texture_PEELABLE );
	$clrs{ Enums->Type_PEELABLE } = $peelableClr; 
	$peelableClr->Set3DEdges(5);
	
	# Grafit paste
	
	my $grafitClr = LayerColor->new(PrevEnums->Surface_TEXTURE, Enums->Texture_GRAFIT );
	$clrs{ Enums->Type_GRAFIT } = $grafitClr; 
	 
	

	# Mask color
	my $clrRGB = $self->__GetMaskColor();
	my $maskClr = LayerColor->new(PrevEnums->Surface_COLOR, $clrRGB );

	# if white mask, do smaller opaque
	if ( $clrRGB eq "250,250,250" ) {

		$maskClr->SetOpaque(90);
	}
	else {
		$maskClr->SetOpaque(80);
	}
	
		
	$clrs{ Enums->Type_MASK } = $maskClr;
	

	# Silk color

	my $silkClr = LayerColor->new(PrevEnums->Surface_COLOR, $self->__GetSilkColor() );
	$clrs{ Enums->Type_SILK } = $silkClr;
	
	# Silk color 2 (second selkscreen)

	my $silkClr2 = LayerColor->new(PrevEnums->Surface_COLOR, $self->__GetSilkColor(1) );
	$clrs{ Enums->Type_SILK2 } = $silkClr2;

	# Depth NC plated - same as surface but dareker

	my $pltDepthClr = LayerColor->new();
	$clrs{ Enums->Type_PLTDEPTHNC } = $pltDepthClr;

	$pltDepthClr->SetType( $outerSurfaceClr->GetType() );
	$pltDepthClr->SetBrightness( $outerSurfaceClr->GetBrightness() - 15 );

	if ( $outerSurfaceClr->GetType() eq PrevEnums->Surface_COLOR ) {
		$pltDepthClr->SetColor( $outerSurfaceClr->GetColor() );
	}
	else {
		$pltDepthClr->SetTexture( $outerSurfaceClr->GetTexture() );
	}

	# Depth NC nonplated - same as material pcb but darker

	my $npltDepthClr = LayerColor->new();
	$clrs{ Enums->Type_NPLTDEPTHNC } = $npltDepthClr;

	$npltDepthClr->SetType( $pcbMatClr->GetType() );
	$npltDepthClr->SetBrightness( $pcbMatClr->GetBrightness() - 15 );

	if ( $pcbMatClr->GetType() eq PrevEnums->Surface_COLOR ) {
		$npltDepthClr->SetColor( $pcbMatClr->GetColor() );
	}
	else {
		$npltDepthClr->SetTexture( $pcbMatClr->GetTexture() );
	}

	# PLT Through NC

	my $pltThroughNcClr = LayerColor->new(PrevEnums->Surface_COLOR );
	$clrs{ Enums->Type_PLTTHROUGHNC } = $pltThroughNcClr;

	# NPLT Through NC

	my $npltThroughNcClr = LayerColor->new(PrevEnums->Surface_COLOR );
	$clrs{ Enums->Type_NPLTTHROUGHNC } = $npltThroughNcClr;

	return \%clrs;

}

sub __GetMaskColor {
	my $self = shift;

	my %pcbMask = Helper->GetMaskColor( $self->{"inCAM"}, $self->{"jobId"} );
	my %pcbMask2 = Helper->GetMaskColor( $self->{"inCAM"}, $self->{"jobId"}, 1 ); # return second color mask
	
	# Decide which mask color is on top	
	my $pcbMaskVal;
	if($self->{"viewType"} eq Enums->View_FROMTOP){
		
		$pcbMaskVal = defined $pcbMask2{"top"} && $pcbMask2{"top"} ne "" ? $pcbMask2{"top"} : $pcbMask{"top"};
	
	}elsif($self->{"viewType"} eq Enums->View_FROMBOT){
		
		$pcbMaskVal = defined $pcbMask2{"bot"} && $pcbMask2{"bot"} ne "" ? $pcbMask2{"bot"} : $pcbMask{"bot"};
	}
 
	unless ($pcbMaskVal) {
		return "";
	}

	my %colorMap = ();
	$colorMap{"Z"} = "0,115,42";       # green
	$colorMap{"B"} = "59,59,59";       # black
	$colorMap{"W"} = "250,250,250";    #white
	$colorMap{"M"} = "0,48,153";       #blue
	$colorMap{"T"} = "255,255,255";    # ??
	$colorMap{"R"} = "196,0,0";        # red

	return $colorMap{$pcbMaskVal};
}

sub __GetSilkColor {
	my $self = shift;
	my $secondSilk = shift; # return color for scend silkscreen

	my %pcbSilk = Helper->GetSilkColor( $self->{"inCAM"}, $self->{"jobId"}, $secondSilk );
	my $pcbSilkVal;
	
	if($self->{"viewType"} eq Enums->View_FROMTOP){
		
		$pcbSilkVal = $pcbSilk{"top"} ;
	
	}elsif($self->{"viewType"} eq Enums->View_FROMBOT){
		
		$pcbSilkVal = $pcbSilk{"bot"};
	}
 
	unless ($pcbSilkVal) {
		return "";
	}

	my %colorMap = ();
	$colorMap{"B"} = "250,250,250";    #white
	$colorMap{"Z"} = "255,247,0";      #yellow
	$colorMap{"C"} = "74,74,74";       # black

	return $colorMap{$pcbSilkVal};
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

