
#-------------------------------------------------------------------------------------------#
# Description: Part interface
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::IPart;


use Class::Interface;
&interface;    


#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Initialize part model by:
# - Restored data from disc
# - Default depanding on panelisation type
sub InitPartModel;

# Set values from model to View
sub RefreshGUI;

# Return updated model by values from View
sub GetModel;

# Asynchronously process selected creator for this part
sub AsyncProcessSelCreatorModel;

# Asynchronously initialize selected creator for this part
sub AsyncInitSelCreatorModel;

# Set directly preview option
sub SetPreview;

# Get previre option
sub GetPreview;

# If all asynchronous init calling are done, return 1
sub IsPartFullyInited;


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

