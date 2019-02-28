#-------------------------------------------------------------------------------------------#
# Description: Helper module for creatin IPC files
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::ETesting::BasicHelper::Helper;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#loading of locale modules
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return if is possible export IPC file with Step and Repeats
# There are conditions:
# - step has to contain only one type of pcb
# - if pcb are rotated, all steps has to have same rotation
sub KeepProfilesAllowed {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $stepToTest = shift;
	my $mess       = shift;

	$$mess = "If keep profile step is required, ";

	my @couponSteps = ( EnumsGeneral->Coupon_IMPEDANCE );    # coupon steps which are consider during chcecks

	# 1. RULE
	my @repeats = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $stepToTest );
	CamStepRepeat->RemoveCouponSteps( \@repeats, 1, \@couponSteps );    # remove coupon steps

	unless ( scalar(@repeats) ) {
		$$mess .= "Et step: \"$stepToTest\" doesn't contain any steps" if ( defined $$mess );
		return 0;
	}

	# 2. RULE
	my @nested = CamStepRepeat->GetUniqueDeepestSR( $inCAM, $jobId, $stepToTest );
	CamStepRepeat->RemoveCouponSteps( \@nested, 1, \@couponSteps );     # remove coupon steps

	if ( scalar(@nested) > 1 ) {

		$$mess .= "ET step: \"$stepToTest\" has to contain only one type of \"end nested steps\""
		  if ( defined $$mess );
		return 0;
	}

	# 3. RULE
	my @endSteps = CamStepRepeat->GetTransformRepeatStep( $inCAM, $jobId, $stepToTest );
	CamStepRepeat->RemoveCouponSteps( \@endSteps, 1, \@couponSteps );    # remove coupon steps

	my @stdAngles  = uniq( grep { $_ % 90 == 0 } map { $_->{"angle"} } @endSteps );
	my @specAngles = uniq( grep { $_ % 90 > 0 } map  { $_->{"angle"} } @endSteps );

	if ( @stdAngles && @specAngles) {

		$$mess .=
		    "all end steps of ET step: \"$stepToTest\": "
		  . $endSteps[0]->{"stepName"}
		  . " has to have either standard rotation (0°;90°;270°) or special rotation (not standard)"
		  if ( defined $$mess );
		return 0;
	}
	
	# 4. RULE
		if (scalar(@specAngles) > 1) {

		$$mess .=
		    "all end steps (".$endSteps[0]->{"stepName"}.") of ET step: \"$stepToTest\": "
		  . " has to have same special rotation (current special step rotations: ".join("; ", @specAngles)." degree)"
		  if ( defined $$mess );
		return 0;
	}
	

	# 5.RULE 

	# Keep SR profile is not possible when "sub panel" steps contain data in at least one of these layers:
	# - route before etch
	# - rout before plate
	# - rout before ET

	if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $stepToTest ) ) {

		my $layerType = [
						  EnumsGeneral->LAYERTYPE_nplt_rsMill, EnumsGeneral->LAYERTYPE_nplt_kMill,
						  EnumsGeneral->LAYERTYPE_plt_nDrill,  EnumsGeneral->LAYERTYPE_plt_nMill
		];

		my @testLayers = map { $_->{"gROWname"} } CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, $layerType );

		if ( scalar(@testLayers) ) {

			my $endStep = $endSteps[0]->{"stepName"};

			# Search for subpanels (no end steps, no panel step)
			my @subPanels = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $stepToTest );
			CamStepRepeat->RemoveCouponSteps( \@subPanels, 1, \@couponSteps );    # remove coupon steps
			@subPanels = map { $_->{"stepName"} } @subPanels;
			push( @subPanels, $stepToTest );                                      # add test step
			@subPanels = grep { $_ ne $endStep && $_ ne "panel" } @subPanels;     # remove panel step

			foreach my $subPnl (@subPanels) {

				foreach my $l (@testLayers) {

					my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $subPnl, $l, 0 );
					if ( $hist{"total"} ) {

						$$mess .= "ET step: \"$stepToTest\", subpanel: $subPnl can't contain data in layer: $l"
						  if ( defined $$mess );
						return 0;
					}

				}

			}
		}

	}

	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
