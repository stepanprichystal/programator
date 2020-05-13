
#-------------------------------------------------------------------------------------------#
# Description: Class which implement this interface, 
# can prepare table drawings for travelers. Each table drawing represent traveler page
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::ITravelerBuilder;

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

# Method is responsible for preparation of array of TableDrawing instances
# Each table drawing instance, represent one traveler page
sub Build;

# Return array of TableDrawing instances
sub GetTblDrawings;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

