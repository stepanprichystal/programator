
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::FinalPreview::FinalPreview;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::LayerData::LayerDataList';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::OutputPdf';
use aliased 'CamHelpers::CamDrilling';
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

	$self->{"viewType"} = shift;

	$self->{"layerList"} = LayerDataList->new( $self->{"viewType"} );
	$self->{"outputPdf"} = OutputPdf->new( $self->{"viewType"}, $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"} );

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".png";

	return $self;
}

sub Create {
	my $self    = shift;
	my $message = shift;

	# get all board layers
	my @layers = CamJob->GetBoardLayers( $self->{"inCAM"}, $self->{"jobId"} );

	# add nc info to nc layers
	my @nclayers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;
	CamDrilling->AddNCLayerType( \@nclayers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@nclayers );

	# set layer list
	$self->{"layerList"}->SetLayers( \@layers );
	$self->{"layerList"}->SetColors( $self->__PrepareColors() );

	$self->{"outputPdf"}->Output( $self->{"layerList"} );

	return 1;
}

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
	push( @cmd, "-shave 20x20 -trim -shave 5x5" );
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

sub __PrepareColors {
	my $self = shift;
	my %clrs = ();

	# base mat

	my %material = ( "Type" => Enums->Surface_COLOR, "Val" => "226,235,150" );

	my $mat = HegMethods->GetMaterialKind( $self->{"jobId"} );
	if ( $mat =~ /al/i ) {

		$material{"Type"} = Enums->Surface_TEXTURE;

		if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

			$material{"Val"} = Enums->Texture_CU;

		}
		elsif ( $self->{"viewType"} eq Enums->View_FROMBOT ) {

			$material{"Val"} = Enums->Texture_CHEMTINALU;
		}
	}
	elsif ( $mat =~ /cu/i ) {

		$material{"Type"} = Enums->Surface_TEXTURE;
		$material{"Val"}  = Enums->Texture_CU;

	}

	$clrs{ Enums->Type_PCBMAT } = \%material;

	# surface or cu
	my $surface = HegMethods->GetPcbSurface( $self->{"jobId"} );

	my %surf = ( "Type" => Enums->Surface_TEXTURE );

	if ( $surface =~ /^a$/i || $surface =~ /^b$/i ) {
		$surf{"Val"} = Enums->Texture_HAL;
	}
	elsif ( $surface =~ /^c$/i ) {
		$surf{"Val"} = Enums->Texture_CHEMTINALU;
	}
	elsif ( $surface =~ /^i$/i || $surface =~ /^g$/i ) {
		$surf{"Val"} = Enums->Texture_GOLD;
	
	}else {    # surface less

		$surf{"Val"} = Enums->Texture_CU;

	}
	 

	$clrs{ Enums->Type_OUTERCU } = \%surf;

	# Mask color
	my %mask = ( "Type" => Enums->Surface_COLOR, "Val" => $self->__GetMaskColor() );
 	$clrs{ Enums->Type_MASK } = \%mask;

	# Silk color
	my %silk = ( "Type" => Enums->Surface_COLOR, "Val" => $self->__GetSilkColor() );
	$clrs{ Enums->Type_SILK } = \%silk;

	# Depth NC plated
	#multiply surface color
	#my @surfArr = split( ",", $surfClr );
	#@surfArr = map { $_ * 1 / 4 } @surfArr;

	#$clrs{ Enums->Type_PLTDEPTHNC } = join( ",", @surfArr );
	my %pltDepthSurf = %surf;
	$pltDepthSurf{"Brightness"} = -15;
	$clrs{ Enums->Type_PLTDEPTHNC } = \%pltDepthSurf;

	# Depth NC non plated
	my %npltDepthSurf = %material;
	$npltDepthSurf{"Brightness"} = -20;
	$clrs{ Enums->Type_NPLTDEPTHNC } = \%npltDepthSurf;

	# PLT Through NC
	my %plt = ( "Type" => Enums->Surface_COLOR, "Val" => "250,250,250" );
	$clrs{ Enums->Type_PLTTHROUGHNC } = \%plt;

	# Through NC
	my %nplt = ( "Type" => Enums->Surface_COLOR, "Val" => "250,250,250" );
	$clrs{ Enums->Type_NPLTTHROUGHNC } = \%nplt;

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

