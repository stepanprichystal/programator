#-------------------------------------------------------------------------------------------#
# Description:  Class fotr testing application

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::CheckReorderApp::Reorder::Checks::CheckBase;

 
#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	my $checkKey = shift;
	
	$self = {};
	bless $self;
 
	$self->{"key"} = $checkKey;
 
	return $self;
}

sub GetCheckKey {
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

