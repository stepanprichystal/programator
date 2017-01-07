
#-------------------------------------------------------------------------------------------#
# Description: Create pdf of single layer previef + drill maps with titles and description
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::SinglePreview::SinglePreview;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';

use aliased "Helpers::JobHelper";
use aliased 'Enums::EnumsPaths';

use aliased 'Packages::Pdf::ControlPdf::SinglePreview::LayerData::LayerDataList';

use aliased 'Packages::Pdf::ControlPdf::SinglePreview::OutputPdf';

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
	$self->{"lang"}    = shift;

	$self->{"layerList"} = LayerDataList->new( $self->{"lang"} );
	$self->{"outputPdf"} = OutputPdf->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"}, $self->{"lang"} );

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

sub Create {
	my $self = shift;

	#my $lRef = shift;
	my $message = shift;

	# get all base layers
	my @layers = CamJob->GetBoardLayers( $self->{"inCAM"}, $self->{"jobId"} );

	 
	# 2) Filter ou helper layers fr, v1, etc..
	@layers = grep { $_->{"gROWname"} ne "v1" && $_->{"gROWname"} ne "fr" && $_->{"gROWname"} ne "fsch" && $_->{"gROWname"} !~ /^gold[cs]$/ } @layers;

	# 3) Prepare non  NC layers
	my @NCLayers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;

	CamDrilling->AddNCLayerType( \@NCLayers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@NCLayers );

	foreach my $l (@NCLayers) {
		my %fHist = CamHistogram->GetFeatuesHistogram( $self->{"inCAM"}, $self->{"jobId"}, $self->{"pdfStep"}, $l->{"gROWname"} );
		$l->{"fHist"} = \%fHist;
	}

	$self->{"layerList"}->SetLayers( \@layers );

	$self->{"outputPdf"}->Output( $self->{"layerList"} );

	return 1;

}

sub GetOutput {
	my $self = shift;

	return $self->{"outputPdf"}->GetOutput();
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

