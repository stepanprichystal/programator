
#-------------------------------------------------------------------------------------------#
# Description: Interface, class must implement methoc ProcessLog
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::ICheck;

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

# return 0, if log should not be processed anymore by Log service
sub NeedChange;     
 


 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

