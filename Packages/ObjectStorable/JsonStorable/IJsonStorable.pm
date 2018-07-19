
#-------------------------------------------------------------------------------------------#
# Description: Interface, for all object which has to be decoded back to object
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ObjectStorable::JsonStorable::IJsonStorable;

#3th party library
use strict;
use warnings;
#use File::Copy;

#local library


#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

use Class::Interface;
&interface;   

# Methods

# TO_JSON allow serialze blessed object
sub TO_JSON;

# Property


# __CLASS__ contains eturn name of class which deserialized data will be blessed into
# $self->{"__CLASS__"} 
 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

