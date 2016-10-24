#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with InCAM layer
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamStep;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return name of all steps
 sub GetAllStepNames {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
 
 
	$inCAM->INFO(units => 'mm', angle_direction => 'ccw', entity_type => 'job', entity_path => $jobId,data_type => 'STEPS_LIST');
	
	return @{$inCAM->{doinfo}{gSTEPS_LIST}};
}
 

1;
