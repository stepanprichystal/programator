#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with tolerance hole operation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Tooling::TolHoleOperation;

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

# Return layer name where is tolerance holes
sub GetTolHoleLayers {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;    # step which is breaked and controlled
	my $breakSR = shift;

	my @lTol = ();

	my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nDrill, EnumsGeneral->LAYERTYPE_nplt_nMill ] );

	if (@layers) {

		foreach my $l (@layers) {
			my @result = grep { $_->{"gTOOLmin_tol"} > 0 || $_->{"gTOOLmax_tol"} }
			  CamDTM->GetDTMTools( $inCAM, $jobId, $step, $l->{"gROWname"}, 1 );

			if ( scalar(@result) ) {
				push( @lTol, $l->{"gROWname"} );
			}
		}
	}

	return @lTol;
}

# Return if exist tolerance holes in job in layer m,f
sub ExistTolHoleJob {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;    # step which is breaked and controlled
	my $breakSR = shift;

	my $exist = 0;

	my @l = $self->GetTolHoleLayers( $inCAM, $jobId, $step, $breakSR );

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

	use aliased 'Packages::Tooling::TolHoleOperation';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d152457";
	my $stepName = "panel";
	my $res  = TolHoleOperation->ExistTolHoleJob( $inCAM, $jobId, $stepName);
	
	 
	
	die;
	

}

1;
