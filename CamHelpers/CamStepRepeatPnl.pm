#-------------------------------------------------------------------------------------------#
# Description: Helper class, operation which are working with S&R of panel step
# Bz defualt all special (coupon) steps are ignored
# Special steps start with "coupon_<text>"
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamStepRepeatPnl;

#3th party library
use strict;
use warnings;
use List::Util qw[max min first];

#loading of locale modules
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return information about each steps in panel step
sub GetRepeatStep {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $includeCpns  = shift // 0;    # include coupons steps, default: no
	my $includeSteps = shift;         # definition of included coupon steps, if undef = all coupon steps

	my $stepName = "panel";

	my @steps = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $stepName );

	CamStepRepeat->RemoveCouponSteps( \@steps, $includeCpns, $includeSteps );

	return @steps;
}

# Return information about deepest nested steps in panel step, which doesn't contain another SR
# Return array of hashes. Hash contains keys:
# - stepName
# - totalCnt: Total count of steps in specified step
sub GetUniqueDeepestSR {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $includeCpns  = shift // 0;    # include coupons steps, default: no
	my $includeSteps = shift;         # definition of included coupon steps, if undef = all coupon steps

	my $stepName = "panel";

	my @steps = CamStepRepeat->GetUniqueDeepestSR( $inCAM, $jobId, $stepName );

	CamStepRepeat->RemoveCouponSteps( \@steps, $includeCpns, $includeSteps );

	return @steps;

}

# Return information about all nested steps in panel step
# Return array of hashes. Hash contains keys:
# - stepName
# - totalCnt: Total count of steps in specified step
sub GetUniqueStepAndRepeat {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $includeCpns  = shift // 0;    # include coupons steps, default: no
	my $includeSteps = shift;         # definition of included coupon steps, if undef = all coupon steps

	my $stepName = "panel";

	my @steps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $stepName );

	CamStepRepeat->RemoveCouponSteps( \@steps, $includeCpns, $includeSteps );

	return @steps;
}

# Return information about all nested steps (through all deepness level) steps in panel step
# Return array of hashes. Hash contains keys:
# - stepName
# - totalCnt: Total count of steps in specified step
sub GetUniqueNestedStepAndRepeat {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $includeCpns  = shift // 0;    # include coupons steps, default: no
	my $includeSteps = shift;         # definition of included coupon steps, if undef = all coupon steps

	my $stepName = "panel";

	my @steps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $stepName );

	CamStepRepeat->RemoveCouponSteps( \@steps, $includeCpns, $includeSteps );

	return @steps;
}

# Return limits of all step and repeat
sub GetStepAndRepeatLim {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $considerOrigin = shift;
	my $includeCpns    = shift // 0;    # include coupons steps, default: no
	my $includeSteps   = shift;         # definition of included coupon steps, if undef = all coupon steps

	my $stepName = "panel";

	my @SR = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $stepName, $considerOrigin );

	CamStepRepeat->RemoveCouponSteps( \@SR, $includeCpns, $includeSteps );

	my %limits;

	$limits{"xMin"} = min( map { $_->{"gSRxmin"} } @SR );
	$limits{"xMax"} = max( map { $_->{"gSRxmax"} } @SR );
	$limits{"yMin"} = min( map { $_->{"gSRymin"} } @SR );
	$limits{"yMax"} = max( map { $_->{"gSRymax"} } @SR );

	return %limits;
}

# Return information about nested deepest steps in panel step
# Returned values match absolute position and rotation of nested steps in panel step
# Each item contains
# - x: final x position
# - y: final y position
# - angle: final angle
# Function consider origin ( position of steps is relate to zero of step in parameter)
sub GetTransformRepeatStep {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $includeCpns  = shift // 0;    # include coupons steps, default: no
	my $includeSteps = shift;         # definition of included coupon steps, if undef = all coupon steps

	my $stepName = "panel";

	my @steps = CamStepRepeat->GetTransformRepeatStep( $inCAM, $jobId, $stepName );

	CamStepRepeat->RemoveCouponSteps( \@steps, $includeCpns, $includeSteps );

	return @steps;
}

# Return all coupon step names in panel step
sub GetAllCouponSteps {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $stepName = "panel";

	my @defCpnNames = JobHelper->GetCouponStepNames();

	my @pnlStep = map { $_->{"stepName"} } CamStepRepeat->GetUniqueStepAndRepeat($inCAM,$jobId, $stepName);

	for ( my $i = scalar(@pnlStep) - 1 ; $i >= 0 ; $i-- ) {

		my $exist = first { $pnlStep[$i] =~ /$_/i } @defCpnNames;

		if ( !$exist ) {

			splice @pnlStep, $i, 1;

		}
	}

	return @pnlStep;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamStepRepeatPnl';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d322953";
	my $step  = "panel";

	#my %lim = CamStepRepeat->GetStepAndRepeatLim( $inCAM, $jobId, $step );

	my @s = CamStepRepeatPnl->GetAllCouponSteps( $inCAM, $jobId );

	die;

}

1;
