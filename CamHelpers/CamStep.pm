#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with InCAM layer
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamStep;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return name of all steps
 sub GetAllStepNames {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
 
 
	$inCAM->INFO(units => 'mm', angle_direction => 'ccw', entity_type => 'job', entity_path => $jobId,data_type => 'STEPS_LIST');
	
	return @{$inCAM->{doinfo}{gSTEPS_LIST}};
}


# create special step, which IPC will be exported from
sub CreateFlattenStep {
	my $self = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $sourceStep = shift;
	my $targetStep = shift;
	 

	#delete if step already exist
	if ( CamHelper->StepExists( $inCAM, $jobId, $targetStep ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $targetStep, "type" => "step" );
	}

	$inCAM->COM(
				 'copy_entity',
				 type             => 'step',
				 source_job       => $jobId,
				 source_name      => $sourceStep,
				 dest_job         => $jobId,
				 dest_name        => $targetStep,
				 dest_database    => "",
				 "remove_from_sr" => "yes"
	);

	#check if SR exists in etStep, if so, flattern whole step
	my $srExist = CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $targetStep );

	if ($srExist) {
		$self->__FlatternPdfStep($inCAM, $jobId,$targetStep);
	}

}


sub __FlatternPdfStep {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $stepPdf = shift;

	CamHelper->SetStep( $inCAM, $stepPdf );

	my @allLayers = CamJob->GetBoardLayers( $inCAM, $jobId );

	foreach my $l (@allLayers) {

		CamLayer->FlatternLayer( $inCAM, $jobId, $stepPdf, $l->{"gROWname"} );
	}

	$inCAM->COM('sredit_sel_all');
	$inCAM->COM('sredit_del_steps');

}
 

1;
