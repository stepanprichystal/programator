
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTravelerTmpl::TravelerDataBuilder::ITravelerBuilder;

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

sub BuildTraveler;

sub BuildOperations;

sub BuildInfoBoxes;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

