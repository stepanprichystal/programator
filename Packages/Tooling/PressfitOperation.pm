#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with tooling
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Tooling::PressfitOperation;

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

# Return layer name where is pressfit
sub GetPressfitLayers {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;    # step which is breaked and controlled
	my $breakSR = shift;

	my @layers = ();

	if ( CamHelper->LayerExists( $inCAM, $jobId, "m" ) ) {

		my @result = CamDTM->GetDTMColumnsByType( $inCAM, $jobId, $step, "m", "press_fit", $breakSR );

		if ( scalar(@result) ) {
			push( @layers, "m" );
		}
	}

	if ( CamHelper->LayerExists( $inCAM, $jobId, "f" ) ) {

		my @result = CamDTM->GetDTMColumnsByType( $inCAM, $jobId, $step, "f", "press_fit", $breakSR );

		if ( scalar(@result) ) {
			push( @layers, "f" );
		}
	}

	return @layers;
}

# Return if exist pressfit in job in layer m,f
sub ExistPressfitJob {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;    # step which is breaked and controlled
	my $breakSR = shift;

	my $exist = 0;

	my @l = $self->GetPressfitLayers( $inCAM, $jobId, $step, $breakSR );

	if ( scalar(@l) ) {
		return 1;
	}
	else {
		return 0;
	}

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
