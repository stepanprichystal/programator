#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with routing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::CheckSingleStep;

#3th party library
use strict;
use warnings;
use Math::Polygon;
use List::Util qw[max];

#local library

use aliased 'CamHelpers::CamHelper';

use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStep';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# 1) Add attribute plated rout area to step o,o+1 to all plated rout layers
# 2) Delete smd attributes from pads, where is plated rout
sub SetRoutPlated {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;

	my @steps = CamStep->GetAllStepNames( $inCAM, $jobId );

	my $o1Exist = scalar( grep { $_ =~ /o+1/ } @steps );

	unless ( !( scalar(@steps) > 1 && $o1Exist ) ) {

		return 0;
	}

	my @res = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill );


	foreach my $layer (@res) {

		#CamHelper->SetStep( $inCAM, $jobId, $steps[0] );
		$self->SetRoutPlatedByStep( $inCAM, $jobId, $steps[0], $layer->{"gROWname"} );

		#CamHelper->SetStep( $inCAM, $jobId, "o+1" );
		$self->SetRoutPlatedByStep( $inCAM, $jobId, "o+1", $layer->{"gROWname"} );

		$self->DeleteSmdWhereRoutPlated( $inCAM, $jobId, $layer->{"gROWname"} )

	}

}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


	


}

1;
