
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
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
	
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"pdfStep"}  = shift;
	$self->{"lang"}        = shift;
	
	$self->{"layerList"} = LayerDataList->new( $self->{"lang"} );
	$self->{"outputPdf"} = OutputPdf->new( $self->{"inCAM"},$self->{"jobId"}, $self->{"pdfStep"}, $self->{"lang"}  );

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

sub Create {
	my $self = shift;
	my $lRef = shift;

	# get all base layers
	my @layers = CamJob->GetBoardLayers( $self->{"inCAM"}, $self->{"jobId"} );

	# 1) Filter only requested layers
	if ($lRef) {

		for ( my $i = scalar(@layers) ; $i >= 0 ; $i-- ) {

			my $l = $layers[$i];
			my $exist = scalar( grep { $_ eq $l->{"gROWname"} } @{$lRef} );

			unless ($exist) {
				splice @layers, $i, 1;    #remove
			}
		}
	}
	
	# 2) Filter ou helper layers fr, v1, etc..
	@layers = grep { $_->{"gROWname"} ne "v1" && $_->{"gROWname"} ne "fr"  && $_->{"gROWname"} ne "fsch"  && $_->{"gROWname"} !~ /^gold[cs]$/} @layers;
	
 
	# 3) Prepare non  NC layers
	my @NCLayers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;

	CamDrilling->AddNCLayerType( \@NCLayers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@NCLayers );
	
	foreach my $l (@NCLayers){
		my %fHist = CamHistogram->GetFeatuesHistogram( $self->{"inCAM"}, $self->{"jobId"},  $self->{"pdfStep"}, $l->{"gROWname"} );
		$l->{"fHist"} = \%fHist;
	}

	
	
	$self->{"layerList"}->SetLayers(\@layers);
	
	$self->{"outputPdf"}->Output( $self->{"layerList"} );

}

sub GetOutput {
	my $self = shift;

	return  $self->{"outputPdf"}->GetOutput();
}


#sub __PrepareLayerData {
#	my $self   = shift;
#	my @layers = @{ shift(@_) };
#
#	my @layerData = ();
#
#	push(@layerData, $self->__PrepareBaseLayerData(\@layers));
#	push(@layerData, $self->__PrepareNCLayerData(\@layers));
#
#}
 

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

