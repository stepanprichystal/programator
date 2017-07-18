
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::StencilCreator;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::StencilCreator::Forms::StencilFrm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	# Main application form
	$self->{"form"} = StencilFrm->new( -1, $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# paste layer
	my @pasteL = grep { $_->{"gROWname"} =~ /^s[ab][-]((ori)|(made))+$/ } CamJob->GetAllLayers( $inCAM, $jobId );

	my $topLayer = ( grep { $_->{"gROWname"} =~ /^sa-ori/ } @pasteL )[0];
	unless ($topLayer) {
		$topLayer = ( grep { $_->{"gROWname"} =~ /^sa-made/ } @pasteL )[0];
	}

	my $botLayer = ( grep { $_->{"gROWname"} =~ /^sb-ori/ } @pasteL )[0];
	unless ($botLayer) {
		$botLayer = ( grep { $_->{"gROWname"} =~ /^sb-made/ } @pasteL )[0];
	}

	# steps
	my @steps =  map {$_->{"stepName"} } grep { $_->{"stepName"} } CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "panel" );
	 
	# limits
	my %stepsSize = ();

	foreach my $stepName (@steps) {

		my %size = ();

		# 1) store step profile size
		my %profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, $stepName );

		$size{"width"}  = abs( $profLim{"xMax"} - $profLim{"xMin"} );
		$size{"height"} = abs( $profLim{"yMax"} - $profLim{"yMin"} );

		# store layer data size for sa..., sb... layers
		if ($topLayer) {

			my %layerLim = CamJob->GetLayerLimits2( $inCAM, $jobId, $stepName, $topLayer->{"gROWname"} );
			my %layerSize = ();
			$layerSize{"width"}  = abs( $layerLim{"xMax"} - $layerLim{"xMin"} );
			$layerSize{"height"} = abs( $layerLim{"yMax"} - $layerLim{"yMin"} );
			$size{"top"}         = \%layerSize;
		}
		if ($botLayer) {

			my %layerLim = CamJob->GetLayerLimits2( $inCAM, $jobId, $stepName, $botLayer->{"gROWname"} );
			my %layerSize = ();
			$layerSize{"width"}  = abs( $layerLim{"xMax"} - $layerLim{"xMin"} );
			$layerSize{"height"} = abs( $layerLim{"yMax"} - $layerLim{"yMin"} );
			$size{"bot"}         = \%layerSize;
		}

		$stepsSize{$stepName} = \%size;
	}

	$self->{"form"}->Init( \%stepsSize, \@steps, defined $topLayer ? 1 : 0, defined $botLayer  ? 1 : 0 );

	$self->{"form"}->{"mainFrm"}->Show();

	$self->{"form"}->MainLoop();
}

# ================================================================================
# FORM HANDLERS
# ================================================================================

# ================================================================================
# PRIVATE METHODS
# ================================================================================

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::StencilCreator::StencilCreator';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

	my $creator = StencilCreator->new( $inCAM, $jobId );
	$creator->Run();

}

1;

