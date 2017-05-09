#-------------------------------------------------------------------------------------------#
# Description: Helper 
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AsyncJobMngr::Helper;

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

	print STDERR '====== E X P O R T ======= '.$mess;
}


#Return file name from full path
sub PrintServer{

	my $self = shift;
	my $mess = shift;

	print STDERR '====== E X P O R T ======= '.$mess;
}

1;
