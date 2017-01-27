#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with tooling
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Tooling::ToolOperation;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return if exist pressfit in job in layer m,f
sub ExistPressfitJob {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;    # step which is breaked and controlled
	my $breakSR = shift;

	my $exist = 0;

	if ( CamHelper->LayerExists( $inCAM, $jobId, "m" ) ) {

		my @result = CamDTM->GetDTMColumnsByType( $inCAM, $jobId, $step, "m", "press_fit", $breakSR );

		if ( scalar(@result) ) {
			$exist = 1;
		}
	}

	unless ($exist) {
		if ( CamHelper->LayerExists( $inCAM, $jobId, "f" ) ) {

			my @result = CamDTM->GetDTMColumnsByType( $inCAM, $jobId, $step, "f", "press_fit", $breakSR );

			if ( scalar(@result) ) {
				$exist = 1;
			}
		}
	}

	return $exist;
}

#
#sub ExistPressfitLayer {
#	my $self  = shift;
#	my $inCAM = shift;
#	my $jobId = shift;
#	my $step  = shift;
#	my $layer  = shift;
#
#	my @steps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $step );
#
#	my $exist = 0;
#
#		foreach my $step (@steps) {
#
#			my @result = CamDTM->GetDTMColumnsByType( $inCAM, $jobId, $step->{"stepName"}, $layer, "press_fit" );
#
#
#		}
#	}
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
