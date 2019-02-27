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

	if ( $stepToTest eq "panel" ) {

		my @repeats = CamStepRepeatPnl->GetRepeatStep( $inCAM, $jobId, 1, [ EnumsGeneral->Coupon_IMPEDANCE ] );

		unless ( scalar(@repeats) ) {
			$$mess = "Et step: $stepToTest doesn't contain any steps" if ( defined $$mess );
			return 0;
		}

		my @nested = CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId, 1, [ EnumsGeneral->Coupon_IMPEDANCE ] );

		if ( scalar(@nested) > 1 ) {

			$$mess = "If keep profile step is required for step: $stepToTest, has to contain only one type of \"end nested steps\""
			  if ( defined $$mess );
			return 0;
		}
		my @endSteps = CamStepRepeatPnl->GetTransformRepeatStep( $inCAM, $jobId, $stepToTest );

		if ( scalar( uniq( map { $_->{"angle"} } @endSteps ) ) > 1 ) {

			$$mess =
			  "If keep profile step is required for step: $stepToTest, all end steps " . $endSteps[0]->{"stepName"} . " has to have same rotation"
			  if ( defined $$mess );
			return 0;
		}
	}
	else {

		my @repeats = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $stepToTest );

		unless ( scalar(@repeats) ) {
			$$mess = "Et step: $stepToTest doesn't contain any steps" if ( defined $$mess );
			return 0;
		}

		my @nested = CamStepRepeat->GetUniqueDeepestSR( $inCAM, $jobId, $stepToTest );

		if ( scalar(@nested) > 1 ) {

			$$mess = "If keep profile step is required for step: $stepToTest, has to contain only one type of \"end nested steps\""
			  if ( defined $$mess );
			return 0;
		}

		my @endSteps = CamStepRepeat->GetTransformRepeatStep( $inCAM, $jobId, $stepToTest );

		if ( scalar( uniq( map { $_->{"angle"} } @endSteps ) ) > 1 ) {
			$$mess =
			  "If keep profile step is required for step: $stepToTest, all end steps " . $endSteps[0]->{"stepName"} . " has to have same rotation"
			  if ( defined $$mess );
			return 0;
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
