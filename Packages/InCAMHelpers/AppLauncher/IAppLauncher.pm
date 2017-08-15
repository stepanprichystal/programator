
#-------------------------------------------------------------------------------------------#
# Description: Interface, for application launched by AppLauncher
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::IAppLauncher;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

use Class::Interface;
&interface;

sub Run;    # After calling Run, app should be inited and showed and called MainLoop

sub Init;   # first archument is LauncherClient object, which contain InCamlibrary etc,

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

