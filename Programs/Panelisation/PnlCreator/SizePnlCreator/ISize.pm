
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

# Return unique Id for creator
sub GetCreatorKey;

# Init creator class in order process panelisation
# (instead of Init method is possible init by import JSON settings)
# Return 1 if succes 0 if fail
sub Init;

# Do necessary check before processing panelisation
# This method is called always before Process method
# Return 1 if succes 0 if fail
sub Check;

# Return 1 if succes 0 if fail
sub Process;

# Method is alternative to Init method
# Allow set creator setting by JSON string
# mainly in order to use class in background workers
sub ExportSettings;

# Allow set creator export setting as JSON string
# mainly in order to use class in background workers with together with ImportSettings method
sub ImportSettings;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

