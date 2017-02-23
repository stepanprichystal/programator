
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
use aliased 'Packages::CAMJob::OutputData::OutputData';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"step"} = shift;
	$self->{"lang"}    = shift;

	$self->{"outputData"} = OutputData->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

	$self->{"layerList"} = LayerDataList->new( $self->{"lang"} );
	$self->{"outputPdf"} = OutputPdf->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"outputData"}->GetStepName(), $self->{"lang"} );

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

sub Create {
	my $self = shift;
	#my $lRef = shift;
	my $message = shift;

	# prepare layers for export
 
	my $mess   = "";
	my $result = $self->{"outputData"}->Create( \$mess );

	unless ($result) {
		die "Error when preparing layers for output.". $mess."\n";
	}

	my @dataLayers = $self->{"outputData"}->GetLayers();
	my $stepName   = $self->{"outputData"}->GetStepName();

 	$self->{"layerList"}->SetStepName( $stepName);
	$self->{"layerList"}->SetLayers( \@dataLayers);
 
	$self->{"outputPdf"}->Output( $self->{"layerList"} );


	# clear job
	$self->{"outputData"}->Clear();

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

