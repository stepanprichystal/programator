
#-------------------------------------------------------------------------------------------#
# Description: Inteface, which  define  operation for feature parser
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::IPrimitive;

#3th party library
use strict;
use warnings;

#local library


#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

use Class::Interface;
&interface;     

sub GetPolarity;     
sub GetType;  
sub MirrorY;
sub MirrorX;
 
1;
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

