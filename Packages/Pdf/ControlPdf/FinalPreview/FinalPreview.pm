
#-------------------------------------------------------------------------------------------#
# Description: Module create image preview of pcb based on physical layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::FinalPreview::FinalPreview;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::LayerData::LayerDataList';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::LayerData::LayerColor';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::OutputPdf';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::OutputPrepare';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Pdf::ControlPdf::Helper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';

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
	$self->{"outputPdf"}     = OutputPdf->new( $self->{"viewType"}, $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"} );
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
	$self->__SetGoldPlating(\@layers );

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
# this method is responsible for choose this color/texture
sub __PrepareColors {
	my $self = shift;
	my %clrs = ();

	# final surface of pcb
	my $surface = HegMethods->GetPcbSurface( $self->{"jobId"} );

	# Pcb material

	my $pcbMatClr = LayerColor->new( Enums->Surface_COLOR, "226,235,150" );
	$clrs{ Enums->Type_PCBMAT } = $pcbMatClr;

	my $mat = HegMethods->GetMaterialKind( $self->{"jobId"} );
	if ( $mat =~ /al/i ) {

		$pcbMatClr->SetType( Enums->Surface_TEXTURE );

		if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

			$pcbMatClr->SetTexture( Enums->Texture_CU );
		}
		elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

			$pcbMatClr->SetTexture( Enums->Texture_CHEMTINALU );
		}
	}
	elsif ( $mat =~ /cu/i ) {

		$pcbMatClr->SetType( Enums->Surface_TEXTURE );
		$pcbMatClr->SetTexture( Enums->Texture_CU );

	}

	# Outer cu
	my $outerCuClr = undef;

	if ( $surface eq "" || $surface =~ /^n$/i ) {

		$outerCuClr = LayerColor->new( Enums->Surface_TEXTURE, Enums->Texture_CU );
	}
	else {

		$outerCuClr = LayerColor->new( Enums->Surface_COLOR, "232,141,77" );
	}

	$clrs{ Enums->Type_OUTERCU } = $outerCuClr;

	# Outer surface

	my $outerSurfaceClr = LayerColor->new( Enums->Surface_TEXTURE, Enums->Texture_CU );
	$clrs{ Enums->Type_OUTERSURFACE } = $outerSurfaceClr;

	if ( $surface =~ /^a$/i || $surface =~ /^b$/i ) {
		$outerSurfaceClr->SetTexture( Enums->Texture_HAL );
	}
	elsif ( $surface =~ /^c$/i ) {
		$outerSurfaceClr->SetTexture( Enums->Texture_CHEMTINALU );
	}
	elsif ( $surface =~ /^i$/i || $surface =~ /^g$/i ) {
		$outerSurfaceClr->SetTexture( Enums->Texture_GOLD );
	}
	
	# Gold fingers

	my $goldFingerClr = LayerColor->new( Enums->Surface_TEXTURE, Enums->Texture_GOLD );
	$clrs{ Enums->Type_GOLDFINGER } = $goldFingerClr;
	

	# Mask color

	my $maskClr = LayerColor->new( Enums->Surface_COLOR, $self->__GetMaskColor() );
	$maskClr->SetOpaque(80);
	$clrs{ Enums->Type_MASK } = $maskClr;

	# Silk color

	my $silkClr = LayerColor->new( Enums->Surface_COLOR, $self->__GetSilkColor() );
	$clrs{ Enums->Type_SILK } = $silkClr;

	# Depth NC plated - same as surface but dareker

	my $pltDepthClr = LayerColor->new();
	$clrs{ Enums->Type_PLTDEPTHNC } = $pltDepthClr;

	$pltDepthClr->SetType( $outerSurfaceClr->GetType() );
	$pltDepthClr->SetBrightness( $outerSurfaceClr->GetBrightness() - 15 );

	if ( $outerSurfaceClr->GetType() eq Enums->Surface_COLOR ) {
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

	if ( $pcbMatClr->GetType() eq Enums->Surface_COLOR ) {
		$npltDepthClr->SetColor( $pcbMatClr->GetColor() );
	}
	else {
		$npltDepthClr->SetTexture( $pcbMatClr->GetTexture() );
	}

	# PLT Through NC

	my $pltThroughNcClr = LayerColor->new( Enums->Surface_COLOR );
	$clrs{ Enums->Type_PLTTHROUGHNC } = $pltThroughNcClr;

	# NPLT Through NC

	my $npltThroughNcClr = LayerColor->new( Enums->Surface_COLOR );
	$clrs{ Enums->Type_NPLTTHROUGHNC } = $npltThroughNcClr;

	return \%clrs;

}

sub __GetMaskColor {
	my $self = shift;

	my %pcbMask = Helper->GetMaskColor( $self->{"inCAM"}, $self->{"jobId"} );
	my $pcbMaskVal = $self->{"viewType"} eq Enums->View_FROMTOP ? $pcbMask{"top"} : $pcbMask{"bot"};

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

	my %pcbSilk = Helper->GetSilkColor( $self->{"inCAM"}, $self->{"jobId"} );
	my $pcbSilkVal = $self->{"viewType"} eq Enums->View_FROMTOP ? $pcbSilk{"top"} : $pcbSilk{"bot"};

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

