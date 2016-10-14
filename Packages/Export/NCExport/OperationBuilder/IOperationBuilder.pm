
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build "operations" for technical procedure
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::OperationBuilder::IOperationBuilder;

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

sub DefineOperations;     
 


 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

