
#-------------------------------------------------------------------------------------------#
# Description: Interface, contain operation for stackup parser
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::StackupParsers::IStackupParser;

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

# Return array of parsed stackup items 
sub ParseStackup;     
 
# Get nominal thickness drequested bz customer 
sub GetNominalThick;

 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

