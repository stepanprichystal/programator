#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with InCAM layer
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamStep;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return name of all steps
sub GetAllStepNames {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	$inCAM->INFO( units => 'mm', angle_direction => 'ccw', entity_type => 'job', entity_path => $jobId, data_type => 'STEPS_LIST' );

	return @{ $inCAM->{doinfo}{gSTEPS_LIST} };
}

# Flatten step, to new step
sub CreateFlattenStep {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $sourceStep  = shift;
	my $targetStep  = shift;
	my $treatDTM    = shift;    # when 1, dtm user columns will be flattened too
	my $layerFilter = shift;    # array of requested layer names. If SR flaten only requested layer for quick result

	#delete if step already exist
	if ( CamHelper->StepExists( $inCAM, $jobId, $targetStep ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $targetStep, "type" => "step" );
	}

	# simple copy whole step (copz step wtih all no SR features)
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

	#check if SR exists in etStep, if so, flattern layer by layer
	my $srExist = CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $targetStep );

	if ($srExist) {

		# 1) filter only requested layers
		my @allLayers = CamJob->GetBoardLayers( $inCAM, $jobId );
		my @layers = @allLayers;

		if ($layerFilter) {
			my %tmp;
			@tmp{ @{$layerFilter} } = ();
			@layers = grep { exists $tmp{ $_->{"gROWname"} } } @layers;
		}

		# 2) flatten
		$self->FlattenStep( $inCAM, $jobId, \@layers, $targetStep, $treatDTM );

		# 3) delete layers which are not requested to be flatenned

		my %tmp2;
		@tmp2{ map { $_->{"gROWname"} } @layers } = ();
		my @layersDel = map { $_->{"gROWname"} } grep { !exists $tmp2{ $_->{"gROWname"} } } @allLayers;

		if (@layersDel) {
			CamLayer->ClearLayers($inCAM);
			CamLayer->AffectLayers( $inCAM, \@layersDel );
			$inCAM->COM('sel_delete');
			CamLayer->ClearLayers($inCAM);
		}
	}

}

sub FlattenStep {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my @layers   = @{ shift(@_) };
	my $stepPdf  = shift;
	my $treatDTM = shift;

	CamHelper->SetStep( $inCAM, $stepPdf );

	foreach my $l (@layers) {

		if ( $treatDTM && ( $l->{"gROWlayer_type"} eq "drill" || $l->{"gROWlayer_type"} eq "rout" ) ) {

			CamLayer->FlatternNCLayer( $inCAM, $jobId, $stepPdf, $l->{"gROWname"} );
		}
		else {
			CamLayer->FlatternLayer( $inCAM, $jobId, $stepPdf, $l->{"gROWname"} );
		}
	}

	$inCAM->COM('sredit_sel_all');
	$inCAM->COM('sredit_del_steps');
}

# Return name of all steps
sub GetDatumPoint {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $stepName       = shift;
	my $considerOrigin = shift;

	if ($considerOrigin) {
		$inCAM->INFO(
					  "units"           => 'mm',
					  "angle_direction" => 'ccw',
					  "entity_type"     => 'step',
					  "entity_path"     => "$jobId/$stepName",
					  "data_type"       => 'DATUM',
					  "options"         => "consider_origin"
		);

	}
	else {
		$inCAM->INFO(
					  "units"           => 'mm',
					  "angle_direction" => 'ccw',
					  "entity_type"     => 'step',
					  "entity_path"     => "$jobId/$stepName",
					  "data_type"       => 'DATUM'
		);

	}

	my %inf = ( "x" => $inCAM->{doinfo}{gDATUMx}, "y" => $inCAM->{doinfo}{gDATUMy} );

	return %inf;
}

# Set new datum point of step
sub SetDatumPoint {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;
	my $x        = shift;
	my $y        = shift;

	CamHelper->SetStep( $inCAM, $stepName );

	$inCAM->COM( "datum", "x" => $x, "y" => $y );

}

# Get limits of active area
sub GetActiveAreaLim {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $stepName       = shift;
	my $considerOrigin = shift;
	my %limits;

	unless ($considerOrigin) {

		$inCAM->INFO(
			units       => 'mm',
			entity_type => 'step',
			entity_path => "$jobId/$stepName",
			data_type   => 'ACTIVE_AREA'

		);
	}
	else {

		$inCAM->INFO(
					  units       => 'mm',
					  entity_type => 'step',
					  entity_path => "$jobId/$stepName",
					  data_type   => 'ACTIVE_AREA',
					  "options"   => "consider_origin"
		);
	}

	$limits{"xMin"} = ( $inCAM->{doinfo}{gACTIVE_AREAxmin} );
	$limits{"xMax"} = ( $inCAM->{doinfo}{gACTIVE_AREAxmax} );
	$limits{"yMin"} = ( $inCAM->{doinfo}{gACTIVE_AREAymin} );
	$limits{"yMax"} = ( $inCAM->{doinfo}{gACTIVE_AREAymax} );

	return %limits;
}

# Set new active area border
sub SetActiveAreaBorder {
	my $self  = shift;
	my $inCAM = shift;
	my $step  = shift;
	my $lb    = shift;
	my $rb    = shift;
	my $tb    = shift;
	my $bb    = shift;

	CamHelper->SetStep( $inCAM, $step );

	$inCAM->COM( "sr_active", "top" => $tb, "bottom" => $bb, "left" => $lb, "right" => $rb );

}

# Create profile by rectangle
sub CreateProfileRect {
	my $self  = shift;
	my $inCAM = shift;
	my $step  = shift;
	my $p1    = shift;
	my $p2    = shift;

	CamHelper->SetStep( $inCAM, $step );

	$inCAM->COM( "profile_rect", "x1" => $p1->{"x"}, "y1" => $p1->{"y"}, "x2" => $p2->{"x"}, "y2" => $p2->{"y"} );

}

# If layer contain countour data, profile is created from them
sub CreateProfileByLayer {
	my $self  = shift;
	my $inCAM = shift;
	my $step  = shift;
	my $layer = shift;

	CamHelper->SetStep( $inCAM, $step );
	CamLayer->WorkLayer( $inCAM, $layer );

	$inCAM->COM("sel_all_feat");
	$inCAM->COM( "sel_create_profile", "create_profile_with_holes" => "yes" );
}

# Create countur from profile in specific layer
# Note: if lazer doesn't exist, layer type will be rout
sub ProfileToLayer {
	my $self      = shift;
	my $inCAM     = shift;
	my $step      = shift;
	my $layer     = shift;    # layer where profile will be copied
	my $lineWidth = shift;    # line width of profile countour

	CamHelper->SetStep( $inCAM, $step );

	$inCAM->COM( "profile_to_rout", "layer" => $layer, "width" => $lineWidth );
}

# Return "reference" step for given step
# Reference means original step of step edited by tpv
# Eg.: input, o, pcb (reference) => o+1 (edited)
sub GetReferenceStep {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $editStep = shift;

	my $refStep = undef;

	if ( $editStep eq "o+1" || $editStep eq "o+1_single" ) {

		foreach my $input ( "o", "input", "pcb" ) {
			if ( CamHelper->StepExists( $inCAM, $jobId, $input ) ) {
				$refStep = $input;
				last;
			}
		}
	}
	else {

		my $refTest = $editStep;
		$refTest =~ s/\+1//;

		if ( CamHelper->StepExists( $inCAM, $jobId, $refTest ) ) {

			$refStep = $refTest;
		}
	}

	return $refStep;
}

# Get all edit steps in DPS
# Edit steps means all leaf child steps in final production panel
# If exist Panel steps, get deepsest step in panel
# If panel step doesnt exist, return all step with name in format: \w+\+1
sub GetJobEditSteps {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @steps = ();

	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {
		@steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );
	}
	else {
		@steps = grep { $_ =~ /^\w+\+1$/ } $self->GetAllStepNames( $inCAM, $jobId );
	}
	return @steps;
}

# If step exist, delete it and return 1
sub DeleteStep {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	if ( CamHelper->StepExists( $inCAM, $jobId, $step ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $step, "type" => "step" );

		return 1;
	}
	else {
		return 0;
	}

}

# Move step data including profile
# All data layers are moved from source point to target point
sub MoveStepData {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $sourcePoint = shift;
	my $targetPoint = shift;

	my $x = -1 * $sourcePoint->{"x"} + $targetPoint->{"x"};
	my $y = -1 * $sourcePoint->{"y"} + $targetPoint->{"y"};

	CamHelper->SetStep( $inCAM, $step );

	my $lName = GeneralHelper->GetGUID();
	$self->ProfileToLayer( $inCAM, $step, $lName, 200 );

	# 1) move all layers data
	my @layers = map { $_->{"gROWname"} } CamJob->GetAllLayers( $inCAM, $jobId );

	CamLayer->ClearLayers($inCAM);
	CamLayer->AffectLayers( $inCAM, \@layers );

	$inCAM->COM( "sel_move", "dx" => $x, "dy" => $y );

	CamLayer->ClearLayers($inCAM);

	# 2) create new profile

	$self->CreateProfileByLayer( $inCAM, $step, $lName );
	$inCAM->COM( 'delete_layer', layer => $lName );
}

# Copy step
sub CopyStep {
	my $self        = shift;
	my $inCAM       = shift;
	my $sourcejobId = shift;
	my $sourceStep  = shift;
	my $targetJob   = shift;
	my $targetStep  = shift;

	$inCAM->COM(
				 "copy_entity",
				 "type"           => "step",
				 "source_job"     => $sourcejobId,
				 "source_name"    => $sourceStep,
				 "dest_job"       => $targetJob,
				 "dest_name"      => $targetStep,
				 "dest_database"  => "",
				 "remove_from_sr" => "yes"
	);
}

# Rename step
sub RenameStep {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $oldName = shift;
	my $newName = shift;

	$inCAM->COM(
				 "rename_entity",
				 "job"      => $jobId,
				 "name"     => $oldName,
				 "new_name" => $newName,
				 "is_fw"    => "no",
				 "type"     => "step",
				 "fw_type"  => "form"
	);
}

# Create new step
sub CreateStep {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	if ( !CamHelper->StepExists( $inCAM, $jobId, $stepName ) ) {
		$inCAM->COM(
					 'create_entity',
					 "job"   => $jobId,
					 "name"  => $stepName,
					 "is_fw" => 'no',
					 "type"  => 'step'
		);

		return 1;
	}
	else {
		return 0;
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamStep';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d78045";
	my $step  = "panel";

	CamStep->CreateFlattenStep( $inCAM, $jobId, $step, "test", 0, [ "c", "m", "v1" ] );

	print "ddd";

}

1;
