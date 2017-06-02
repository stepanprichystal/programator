
#-------------------------------------------------------------------------------------------#
# Description: Custom appender, which insert log directly to TPV db log table
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::LogService::LogAppenders::TPVLogDB;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Connectors::TpvConnector::TpvMethods';
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;    # Create an anonymous hash, and #self points to it.
	
	my %params = @_;
	$self = {};
	bless $self;         # Connect the hash to the package Cocoa.


	$self->{"appName"} = $params{"appname"};
 
	return $self;
}


sub log {
	my($self, %params) = @_;
       
       my $mess = $params{"message"};
       my $level = $params{"level"}; # 2 #warn, #3 error
       
       my $tpvLogType = "Warning"; 
       
       # if level is error, send to db log type error, else warning
       if($level == 3){
       	
       		$tpvLogType = "Error";
       } 
       
        my ($package, $filename, $line) = caller;
       
       print $mess;
       
          
       
       #TpvMethods->InsertAppLog($self->{"appName"}, $tpvLogType, $mess)
       
      
      
    }


sub Warning {
	my $self = shift; 
	
	return scalar(@{$self->{"subs"}});
}

  

1;
	
	
 
