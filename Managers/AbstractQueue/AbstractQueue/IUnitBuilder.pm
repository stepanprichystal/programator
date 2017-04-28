
#-------------------------------------------------------------------------------------------#
# Description: Interface define for UnitBuilders
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::AbstractQueue::IUnitBuilder;

#3th party library
use strict;
use warnings;
#use File::Copy;

#local library


#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

use Class::Interface;
&interface;   

# Methods

sub GetUnits;

sub GetTaskData;


 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

