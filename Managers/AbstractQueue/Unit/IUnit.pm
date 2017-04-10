
#-------------------------------------------------------------------------------------------#
# Description: Interface defines method, which each Unit has to implement
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::Unit::IUnit;

use Class::Interface;
&interface;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Process data, emmited, when item task finis
sub ProcessItemResult;

# Process data, emmited, when group task finis
sub ProcessGroupResult;

# Get actual total resul od task group
sub Result;

sub GetErrorsCnt;

sub GetWarningsCnt;

# Get total progress
sub GetProgress;

# Get manager, which keep information about item task errors
sub GetGroupItemResultMngr;

# Get manager, which keep information about group task errors
sub GetGroupResultMngr;

# Return class, which contain code responsible for task 
sub GetExportClass;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

