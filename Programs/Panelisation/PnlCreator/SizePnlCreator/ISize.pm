
#-------------------------------------------------------------------------------------------#
# Description: Interface for all coupon builders
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::SizePnlCreator::ISize;

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
sub Init;     
 
## If builded, return layout 
#sub Check;     
#
#
#sub ExportSett;
#
#sub ImportSett;
#
#sub CreatePanel;


 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

