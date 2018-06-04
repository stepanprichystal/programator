
#-------------------------------------------------------------------------------------------#
# Description: Interface, contain operation for creating nif file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::ICpnBuilder;

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

# Build layout, return 1 if succes, 0 if fail
sub Build;     
 
# If builded, return layout 
sub GetLayout;     


 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

