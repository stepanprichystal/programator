
#-------------------------------------------------------------------------------------------#
# Description: Interface, which must implement each PartForm
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::IPartForm;

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

 
# Return proper creator view form
sub OnGetCreatorLayout;
 
# override base class method
sub SetCreators;
 
# override base class method
sub GetCreators;

sub SetSelectedCreator;
 
sub GetSelectedCreator;
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

