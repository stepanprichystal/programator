
#-------------------------------------------------------------------------------------------#
# Description: Base section builder. Section builder are responsible for content of section
# Allow add new rows to section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ServiceAppBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';

use aliased 'Programs::Services::LogService::Logger::DBLogger';
use aliased 'Packages::InCAMServer::Client::InCAMServer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $appName = shift;
	my $self  = {};
	bless $self;
 
	$self->{"appName"} = $appName;
#	
#	print STDERR $appName;
#  
	$self->{"loggerDB"} = DBLogger->new($appName); # logger which send log to tpv db

	
	$self->{"inCAMServer"} = InCAMServer->new();


	return $self;
}
 
sub DESTROY {
	my $self = shift;
	
	$self->{"inCAMServer"}->JobDone();
	
	
	$self->{"logger"}->debug("Callin job done");
}
  
 
 
sub GetAppName{
	my $self = shift;
	
	return $self->{"appName"};
} 


# return prepared InCAM library 
sub _GetInCAM{
	my $self = shift;
	
	return $self->{"inCAMServer"}->GetInCAM();
	
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

