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
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsGeneral';

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

	my @lPressfit = ();

	my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_plt_nDrill ] );

	if (@layers) {

		foreach my $l (@layers) {
			my @result = CamDTM->GetDTMToolsByType( $inCAM, $jobId, $step, $l->{"gROWname"}, "press_fit", $breakSR );

			if ( scalar(@result) ) {
				push( @lPressfit, $l->{"gROWname"} );
			}
		}
	}
 
	return @lPressfit;
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



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

		use aliased 'Packages::Tooling::PressfitOperation';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d152457";
	my $stepName = "panel";
	my $res  = PressfitOperation->ExistPressfitJob( $inCAM, $jobId, $stepName, 1);
	
	 
	
	die;

}

1;
