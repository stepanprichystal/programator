
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow create drill maps from coupon objects
# Author:SPR
#-------------------------------------------------------------------------------------------#
package  Packages::CAMJob::Microsection::ICouponDrillMap;

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
 
# Return array of holes where each array item contains:
# - tools = array with tool in specific layer
#           - drillSize
#           - drillDepth
# - layer = hash sttructure with info about NC layer 
#           - "gROWname" 
#           - "NCSigStartOrder" 
#           - etc....
sub GetHoles;


# Return array of postions for specific, drillSize + layer name
sub GetHoleCouponPos;
 
# Return coupon step
sub GetStep;
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

