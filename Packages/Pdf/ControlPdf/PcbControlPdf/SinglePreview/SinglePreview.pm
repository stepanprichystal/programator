
#-------------------------------------------------------------------------------------------#
# Description: Create pdf of single layer previef + drill maps with titles and description
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::SinglePreview::SinglePreview;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';
use aliased "Helpers::JobHelper";
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::SinglePreview::LayerData::LayerDataList';
use aliased 'Packages::Pdf::ControlPdf::Helpers::SinglePreview::OutputPdfBase';
use aliased 'Packages::CAMJob::OutputData::OutputData';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;
	$self->{"SR"}    = shift;
	$self->{"lang"}  = shift;

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	$self->{"outputData"} = OutputData->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"SR"} );

	$self->{"layerList"} = LayerDataList->new( $self->{"lang"} );
	$self->{"outputPdf"} =
	  OutputPdfBase->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"outputData"}->GetStepName(),
						  $self->{"lang"}, $self->{"outputPath"} );

	return $self;
}

sub Create {
	my $self           = shift;
	my $drawProfile    = shift;
	my $drawProfile1Up = shift;
	my $message        = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# prepare layers for export

	CamHelper->SetStep( $inCAM, $self->{"step"} );

	my $mess   = "";
	my $result = $self->{"outputData"}->Create( \$mess );

	unless ($result) {
		die "Error when preparing layers for output." . $mess . "\n";
	}

	my @dataLayers = $self->{"outputData"}->GetLayers();
	my $stepName   = $self->{"outputData"}->GetStepName();

	$self->{"layerList"}->SetStepName($stepName);
	$self->{"layerList"}->SetLayers( \@dataLayers );

	# output single in 2x2 images per page
	# define multiplicity per page by step size
	#	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $self->{"step"} );
	#
	#	my $w = abs( $lim{"xMax"} - $lim{"xMin"} );
	#	my $h = abs( $lim{"yMax"} - $lim{"yMin"} );

	my $featsCnt = 0;
	my @layers   = $self->{"layerList"}->GetLayers();
	foreach my $l ( map { $_->GetOutput() } @layers ) {
		my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $self->{"outputData"}->GetStepName(), $l );
		$featsCnt += $hist{"total"};
	}

	my $featPerL = $featsCnt / scalar(@layers);

	# Decide if 9 or 4 layers per page
	my $multiplX = 3;
	my $multiplY = 3;
	if ( $featPerL > 4000 ) {
		$multiplX = 3;
		$multiplY = 2;
	}
	$self->{"outputPdf"}->Output( $self->{"layerList"}, $multiplX, $multiplY, $drawProfile, $drawProfile1Up, [ 255, 0, 0 ], [ 100, 100, 100 ] );

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

