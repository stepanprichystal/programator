#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with drilling
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Drilling::DrillingOperation;

#3th party library

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::FileHelper';
#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

 




#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = StackupLayerHelper->GetStackupPress("F14742");

 
	print $test;

}

1;
