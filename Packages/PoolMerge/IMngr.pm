
#-------------------------------------------------------------------------------------------#
# Description: Interface, which must implement each export manager
# Rules for creating export scripts.
# Because each export scripts are launched in "Export utility" in perl ithreads
# is necessary acomplish this.
# - code hasn't contain another child thread. Use library Packages::SystemCall for using threads
# - code hasn't use library Connectors::HeliosConnector::HelperWriter, because free wrong pool errors
# for this use this library but launeched by Packages::SystemCall again
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::IMngr;

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

sub TaskItemsCount;


 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

