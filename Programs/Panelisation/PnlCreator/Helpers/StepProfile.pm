
#-------------------------------------------------------------------------------------------#
# Description: Special helper dedicated for working with profile steps at RigidFlex pcb
# which contain layer cvrlpins
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::Helpers::StepProfile;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Helpers::GeneralHelper';
use aliased 'Programs::Panelisation::PnlCreator::Helpers::Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

use constant STEPSUFFIX => "_cvrlpins";

# Duplicate all potential steps and include cvrlpis to step profile
sub PrepareCvrlPinSteps {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @cvrlpinSteps = ();

	if ( CamHelper->LayerExists( $inCAM, $jobId, "cvrlpins" ) ) {

		$inCAM->SetDisplay(0);

		my @editSteps = Helper->GetEditSteps( $inCAM, $jobId );

		my $profL = GeneralHelper->GetGUID();
		CamMatrix->DeleteLayer( $inCAM, $jobId, $profL );
		CamMatrix->CreateLayer( $inCAM, $jobId, $profL, "document", "positive", 0 );

		foreach my $oriStep (@editSteps) {

			my $cvrlPinStep = $oriStep . STEPSUFFIX;
			push( @cvrlpinSteps, $cvrlPinStep );

			CamStep->DeleteStep( $inCAM, $jobId, $cvrlPinStep );

			CamStep->CopyStep( $inCAM, $jobId, $oriStep, $jobId, $cvrlPinStep );

			CamStep->ProfileToLayer( $inCAM, $cvrlPinStep, $profL, 10 );
			$inCAM->COM( "merge_layers", "source_layer" => "cvrlpins", "dest_layer" => $profL );

			# Fill gaps
			CamLayer->Contourize( $inCAM, $profL, "x_or_y", "203200" );    # 203200 = max size of emptz space in InCAM which can be filled by surface
			                                                               # Create one surface
			CamLayer->Contourize( $inCAM, $profL, "x_or_y", "203200" );

			# Create conour
			CamLayer->WorkLayer( $inCAM, $profL );
			$inCAM->COM( "sel_feat2outline", "width" => 10, "location" => "on_edge" );
			CamStep->CreateProfileByLayer( $inCAM, $cvrlPinStep, $profL );

		}

		CamMatrix->DeleteLayer( $inCAM, $jobId, $profL );

		$inCAM->SetDisplay(1);

	}

	return @cvrlpinSteps;

}

# Remove existing cvrlpins steps
sub RemoveCvrlPinSteps {
	my $self = shift;

	my $inCAM        = shift;
	my $jobId        = shift;
	my @cvrlpinSteps = @{ shift(@_) };

	return 0 if ( scalar(@cvrlpinSteps) == 0 );

	# 2) Remove cvrlpisn step
	foreach my $step (@cvrlpinSteps) {
		CamStep->DeleteStep( $inCAM, $jobId, $step );
	}

}

# After using svrlpins steps, replace them in created panel
# by original steps
sub ReplaceCvrlpinSteps {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my @sr = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $step );

	my $suff = STEPSUFFIX;
	if ( scalar( grep { $_->{"stepName"} =~ /$suff/ } @sr ) ) {

		for ( my $i = 0 ; $i < scalar(@sr) ; $i++ ) {

			my $srRow = $sr[$i];

			my $cvrlpinsStep = $srRow->{"gSRstep"};

			if ( $cvrlpinsStep =~ /$suff/ ) {

				$cvrlpinsStep =~ s/$suff//;

				CamStepRepeat->ChangeStepAndRepeat(
													$inCAM,            $jobId,                $step,             $i + 1,
													$cvrlpinsStep,     $srRow->{"gSRxa"},     $srRow->{"gSRya"}, $srRow->{"gSRdx"},
													$srRow->{"gSRdy"}, $srRow->{"gSRnx"},     $srRow->{"gSRny"}, $srRow->{"gSRangle"},
													"ccw",             $srRow->{"gSRmirror"}, $srRow->{"gSRflip"}
				);

			}
		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

