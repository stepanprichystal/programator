#-------------------------------------------------------------------------------------------#
# Description:  Class fotr testing application

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::TpvService::ReOrder::Checks::Check_DATACODE_IS;
use base('Programs::TpvService::ReOrder::Checks::CheckBase');

use Class::Interface;
&implements('Programs::TpvService::ReOrder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new("DATACODE_IS");
	bless($self);
	
	
	return $self;
}

sub NeedChange {
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

