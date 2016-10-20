
#-------------------------------------------------------------------------------------------#
# Description: Interface, which must implement each UnitForm
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Exceptions::IException;

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

# Return error message in string

sub Error;

sub GetExceptionId;


 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

