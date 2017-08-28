#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::AppLauncher::Server::Helper;

#3th party library
use strict;
use warnings;

#local library
 


#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Return file name from full path
sub Print{

	my $self = shift;
	my $mess = shift;

	print '====== E X P O R T CHECKER ======= '.$mess;
}


#Return file name from full path
sub PrintServer{

	my $self = shift;
	my $mess = shift;

	print STDERR '====== E X P O R T CHECKER ======= '.$mess;
}

1;
