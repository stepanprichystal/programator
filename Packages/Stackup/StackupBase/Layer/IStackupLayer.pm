
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupBase::Layer::IStackupLayer;

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

sub GetType;

sub GetThick;
 
sub GetText;

sub GetTextType;

sub GetId;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

