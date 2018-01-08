
#-------------------------------------------------------------------------------------------#
# Description: Interface, which each template class must implement
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::HtmlTemplate::ITemplateKey;

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

sub GetKeyData;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

