
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
use aliased 'Packages::Pdf::ControlPdf::Outputdf';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"viewType"} = shift;

	$self->{"outputPdf"} = LayerDataList->new( $self->{"viewType"} ) $self->{"outputPdf"} = OutputPdf->new();

	return $self;
}

sub Create {
	my $self = shift;
	my $view = shift;

	my $outFile = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".png";

	# get all base layers
	my @layers = CamJob->GetBoardLayers( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"outputPdf"}->SetLayers( \@layers );

	$self->{"outputPdf"}->SetColors( $self->__PrepareColors() );

	# Filter only requested layers
	if ($lRef) {

		for ( my $i = scalar(@layers) ; $i >= 0 ; $i-- ) {

			my $l = $layers[$i];
			my $exist = scalar( grep { $_ eq $l->{"gROWname"} } @{$lRef} );

			unless ($exist) {
				splice @layers, $i, 1;    #remove
			}
		}
	}

	# Filter ou helper layers fr, v1, etc..

	CamHelper->SetStep( $self->{"inCAM"}, $self->{"step"} );

	my $pdfStep = $self->__CreatePdfStep();

	CamHelper->SetStep( $self->{"inCAM"}, $pdfStep );

	my @layerData = $self->__PrepareLayerData( \@layers );

	$self->{"outputPdf"}->OutputData( \@layerData );

	$self->__DeletePdfStep($pdfStep);

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
	my $silkClr = $self->__GetMaskColor();
	$clrs{ Enums->Type_SILK } = $silkClr;

	# Depth NC plated
	$clrs{ Enums->Type_PLTDEPTHNC } = $surfClr;

	# Depth NC non plated
	$clrs{ Enums->Type_NPLTDEPTHNC } = $surfClr;

	# Through NC
	$clrs{ Enums->Type_THROUGHNC } = $surfClr;

}

sub __GetMaskColor {
	my $self = shift;

	my $pcbMask = HegMethods->GetSolderMaskColor( $self->{"jobId"} );
	$pcbMask = $self->{"viewType"} eq Enums->View_FROMTOP ? $pcbMask->{"top"} : $pcbMask->{"bot"};

	my %colorMap = ();
	$colorMap{"Z"} = "Green";
	$colorMap{"V"} = "Black";
	$colorMap{"W"} = "White";
	$colorMap{"M"} = "Blue";
	$colorMap{"T"} = "Transparent";
	$colorMap{"R"} = "Red";

	return $colorMap{$pcbMask};
}

sub __GetSilkColor {
	my $self = shift;

	my $pcbSilk = HegMethods->GetSilkScreenColor( $self->{"jobId"} );
	$pcbSilk = $self->{"viewType"} eq Enums->View_FROMTOP ? $pcbSilk->{"top"} : $pcbSilk->{"bot"};

	my %colorMap = ();
	$colorMap{"B"} = "White";
	$colorMap{"Z"} = "Yellow";
	$colorMap{"C"} = "Black";

	return $colorMap{$pcbSilk};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

