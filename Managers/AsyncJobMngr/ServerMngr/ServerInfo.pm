
#-------------------------------------------------------------------------------------------#
# Description: Data structure for information about server
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AsyncJobMngr::ServerMngr::ServerInfo;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Managers::AsyncJobMngr::Enums';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"state"} = Enums->State_FREE_SERVER;
	
	$self->{"port"} = -1;    #working server port. Is port value, which we working with...
	
	$self->{"portDefault"} = -1; # default server port. Is port, which is defaultly set (1001, 1002,...)    
	
	$self->{"pidInCAM"}  = -1;
	
	$self->{"pidServer"} = -1; # PID of server script, running in InCAM

	# External means, server was prepared and launched "outside"
	# NOT by ServerMngr class
	$self->{"external"} = 0; 

	return $self;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

