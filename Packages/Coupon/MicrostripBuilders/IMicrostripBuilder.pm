
#-------------------------------------------------------------------------------------------#
# Description: Interface, contain operation for creating nif file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::MicrostripBuilders::IMicrostripBuilder;

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

sub Build;     

sub SetModel;
 


 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

