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

	$self->__RemoveCouponSteps( \@steps, $includeCpns, $includeSteps );

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

	$self->__RemoveCouponSteps( \@steps, $includeCpns, $includeSteps );

	return @steps;
}

 

sub __RemoveCouponSteps {
	my $self         = shift;
	my $steps        = shift;
	my $includeCpns  = shift;
	my $includeSteps = shift;

	for ( my $i = scalar( @{$steps} ) - 1 ; $i >= 0 ; $i-- ) {

		if ( !$includeCpns ) {

			if ( $steps->[$i]->{"stepName"} =~ /^coupon_?/ ) {

				splice @{$steps}, $i, 1;

			}
		}
		else {
			if ( $steps->[$i]->{"stepName"} =~ /^coupon_?/ && defined $includeSteps ) {

				if ( !scalar( grep { $_ eq $steps->[$i]->{"stepName"} } @{$includeSteps} ) ) {
					splice @{$steps}, $i, 1;
				}

			}
		}

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamStepRepeat';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";
	my $step  = "panel";

	my @sr = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $step );

	#	my $l = undef;
	#
	#	for(my $i= 0;  $i < scalar(@sr); $i++){
	#
	#		if(  $srg[$i]->{"SRstep"} eq "mpanel"){
	#			$l = $i+1;
	#			last;
	#		}
	#	}
	#
	#
	#
	#

}

1;
