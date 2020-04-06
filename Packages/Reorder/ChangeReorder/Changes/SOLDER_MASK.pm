#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::SOLDER_MASK;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Reorder::Enums';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::SolderMask::UnMaskNC';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if mask is not negative in matrix
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	my $result = 1;

	my @layers = CamJob->GetBoardLayers( $inCAM, $jobId );

	foreach my $l (@layers) {

		if ( $l->{"gROWname"} =~ /m[cs]/ && $l->{"gROWpolarity"} eq "negative" ) {

			CamLayer->SetLayerPolarityLayer( $inCAM, $jobId, $l->{"gROWname"}, "positive" );
		}
	}

	# 1) unmask selceted through holes near GBA pads

	my @NC = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );
	my @sm = map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "solder_mask" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	
	if ( scalar(@NC) && scalar(@sm) ) {

		my @bgaLayers = CamJob->GetSignalLayerNames( $inCAM, $jobId, 0, 1 );
		my @steps = ();
		if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {

			@steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );
		}
		else {

			@steps = ("o+1");
		}

		# BGA exist
		my $bgaExist = 0;
		foreach my $s (@steps) {
			foreach my $l (@bgaLayers) {

				my %att = CamHistogram->GetAttHistogram( $inCAM, $jobId, $s, $l );
				if ( $att{".bga"} ) {
					$bgaExist = 1;
					last;
				}
			}
			last if ($bgaExist);
		}

		if ($bgaExist) {
			foreach my $s (@steps) {

				my $unMaskedCntRef   = 0;
				my $unMaskAttrValRef = "";

				my $resize          = undef;    # default - copy drill smaller about 50µm to solder mask
				my $minDistHole2Pad = undef;    # default - 500µm minimal distance of through hole to pad

				unless ( UnMaskNC->UnMaskThroughHoleNearBGA( $inCAM, $jobId, $s, $resize, $minDistHole2Pad ) ) {
					$result = 0;
				}

			}
		}

		# SMD exist
		my $smdExist = 0;
		foreach my $s (@steps) {
			foreach my $l (@bgaLayers) {

				my %att = CamHistogram->GetAttHistogram( $inCAM, $jobId, $s, $l );
				if ( $att{".smd"} ) {
					$smdExist = 1;
					last;
				}
			}
			last if ($smdExist);
		}

		if ($smdExist) {
			foreach my $s (@steps) {

				my $unMaskedCntRef   = 0;
				my $unMaskAttrValRef = "";

				my $resize          = undef;    # default - copy drill smaller about 50µm to solder mask
				my $minDistHole2Pad = undef;    # default - 500µm minimal distance of through hole to pad

				unless ( UnMaskNC->UnMaskThroughHoleNearSMD( $inCAM, $jobId, $s, $resize, $minDistHole2Pad ) ) {
					$result = 0;
				}

			}
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ChangeReorder::Changes::MASK_POLAR' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d273354";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

