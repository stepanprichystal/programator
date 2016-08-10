
#-------------------------------------------------------------------------------------------#
# Description: Inteface, which  define  operation for feature parser
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Polygon::Features::IFeatures;

#3th party library
use strict;
use warnings;

#local library


#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

use Class::Interface;
&interface;     

sub GetFeatures;     
sub Parse;   

1;
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

