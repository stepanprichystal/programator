
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
use aliased 'Packages::Pdf::ControlPdf::Helper';
use aliased 'Enums::EnumsPaths';

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
	$self->{"outputPdf"} = OutputPdf->new( $self->{"pdfStep"} );

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".png";

	return $self;
}

sub Create {
	my $self = shift;
	my $view = shift;

	# get all base layers
	my @layers = CamJob->GetBoardLayers( $self->{"inCAM"}, $self->{"jobId"} );

	# add nc info to nc layers
	my @nclayers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;
	CamDrilling->AddNCLayerType( \@nclayers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@nclayers );

	# set layer list
	$self->{"layerList"}->SetLayers( \@layers );
	$self->{"layerList"}->SetColors( $self->__PrepareColors() );

	$self->{"outputPdf"}->Output( $self->{"layerList"} );

	my $outPdf = $self->{"outputPdf"}->GetOutput();

	$self->__ConvertPdfToPng($outPdf);

	return 1;
}

sub __ConvertPdfToPng {
	my $self       = shift;
	my $outputPath = shift;

	my $result = 1;

	my @cmd = ( EnumsPaths->InCAM_3rdScripts . "im\\convert.exe" );
	push( @cmd, "-density 200" );
	push( @cmd, $outputPath );
	push( @cmd, "-shave 20x20 -trim -shave 5x5" );
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
	$clrs{ Enums->Type_PCBMAT } = "233,252,199";

	# surface or cu
	my $surface = HegMethods->GetPcbSurface($jobId);

	my $surfClr = "";

	if ( $surface =~ /^n$/i ) {
		$surfClr = "227,186,120";
	}
	elsif ( $surface =~ /^a$/i || $surface =~ /^b$/i ) {
		$surfClr = "222,222,222";
	}
	elsif ( $surface =~ /^c$/i ) {
		$surfClr = "196,196,196";
	}
	elsif ( $surface =~ /^i$/i || $surface =~ /^g$/i ) {
		$surfClr = "255,217,0";
	}

	$clrs{ Enums->Type_OUTERCU } = $surfClr;

	# Mask color
	my $maskClr = $self->__GetMaskColor();

	$clrs{ Enums->Type_MASK } = $maskClr;

	# Silk color
	my $silkClr = $self->__GetSilkColor();
	$clrs{ Enums->Type_SILK } = $silkClr;

	# Depth NC plated
	#multiply surface color
	my @surfArr = $split ( "," $surfClr );
	@surfArr = map( $_ * 1 / 4 );

	$clrs{ Enums->Type_PLTDEPTHNC } = join( ",", @surfArr );

	# Depth NC non plated
	$clrs{ Enums->Type_NPLTDEPTHNC } = "233,252,199";

	# Through NC
	$clrs{ Enums->Type_THROUGHNC } = "255,255,255";

	return \%clrs;

}

sub __GetMaskColor {
	my $self = shift;

	my $pcbMask = Helper->GetSolderMaskColor( $self->{"inCAM"}, $self->{"jobId"} );
	$pcbMask = $self->{"viewType"} eq Enums->View_FROMTOP ? $pcbMask->{"top"} : $pcbMask->{"bot"};

	my %colorMap = ();
	$colorMap{"Z"} = "0,163,11";       # green
	$colorMap{"V"} = "74,74,74";       # black
	$colorMap{"W"} = "255,255,255";    #white
	$colorMap{"M"} = "0,20,235";       #blue
	$colorMap{"T"} = "255,255,255";    # ??
	$colorMap{"R"} = "242,0,0";        # red

	return $colorMap{$pcbMask};
}

sub __GetSilkColor {
	my $self = shift;

	my $pcbSilk = Helper->GetSilkScreenColor( $self->{"inCAM"}, $self->{"jobId"} );
	$pcbSilk = $self->{"viewType"} eq Enums->View_FROMTOP ? $pcbSilk->{"top"} : $pcbSilk->{"bot"};

	my %colorMap = ();
	$colorMap{"B"} = "255,255,255";    #white
	$colorMap{"Z"} = "255,247,0";      #yellow
	$colorMap{"C"} = "74,74,74";       # black

	return $colorMap{$pcbSilk};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

