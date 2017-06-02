
#-------------------------------------------------------------------------------------------#
# Description: Inteface, which  define  operation for feature parser
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::IServiceApp;

#3th party library
use strict;
use warnings;

#local library


#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

use Class::Interface;
&interface;     

# this method is called bt service, one parameter InCAM
sub Run;     

# this is called manualy, outside of services, for testing, params, jobId, inCAM
#sub RunJob;   

# return App name
sub GetAppName;

1;
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

