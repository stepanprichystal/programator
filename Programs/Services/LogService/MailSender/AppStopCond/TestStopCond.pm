#-------------------------------------------------------------------------------------------#
# Description:  Class fotr testing application

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::LogService::MailSender::AppStopCond::TestStopCond;


use Class::Interface;
&implements('Programs::Services::LogService::MailSender::AppStopCond::IStopCond');

#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
 
	return $self;
}

sub ProcessLog {
	my $self = shift;
	my $pcbId = shift;
	
	return 1;
 
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
	print "ee";
}

1;

