
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build "operations" for technical procedure
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::IGroup;

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

sub SetData;
sub Run;     
sub GetItemsCount; 
#sub GetResultBuilder;
# Events

# onItemResult;
 

1;
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

