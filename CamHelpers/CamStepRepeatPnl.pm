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
use List::Util qw[max min];

#loading of locale modules
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';

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

	CamStepRepeat->RemoveCouponSteps( \@steps,  $includeCpns, $includeSteps );

	return @steps;
}

#Return information about steps in panel step
sub GetUniqueStepAndRepeat {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId        = shift;
	my $includeCpns  = shift // 0;    # include coupons steps, default: no
	my $includeSteps = shift;         # definition of included coupon steps, if undef = all coupon steps

	my $stepName = "panel";

	my @steps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $stepName );

	CamStepRepeat->RemoveCouponSteps( \@steps,   $includeCpns, $includeSteps );

	return @steps;
}

# Return limits of all step and repeat
sub GetStepAndRepeatLim {
	my $self           = shift;
	my $inCAM          = shift;
	my $jobId          = shift;
	my $considerOrigin = shift;
	my $includeCpns  = shift // 0;    # include coupons steps, default: no
	my $includeSteps = shift;         # definition of included coupon steps, if undef = all coupon steps
	
	my $stepName = "panel";
	
	my @SR = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $stepName, $considerOrigin );
	
	CamStepRepeat->RemoveCouponSteps( \@SR,  $includeCpns, $includeSteps );
	
	
	my %limits;
 
	$limits{"xMin"} =  min( map { $_->{"gSRxmin"} } @SR);
	$limits{"xMax"} =  max( map { $_->{"gSRxmax"} } @SR);
	$limits{"yMin"} =  min( map { $_->{"gSRymin"} } @SR);
	$limits{"yMax"} =  max( map { $_->{"gSRymax"} } @SR);

	return %limits;
}

 



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamStepRepeat';
	use aliased 'CamHelpers::CamStepRepeatPnl';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d044218";
	my $step  = "panel";

	my %lim = CamStepRepeat->GetStepAndRepeatLim( $inCAM, $jobId, $step );

	my @s = CamStepRepeatPnl->GetRepeatStep( $inCAM, $jobId);
	
	die;

}

1;
