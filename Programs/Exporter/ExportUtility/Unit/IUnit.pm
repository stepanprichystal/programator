
#-------------------------------------------------------------------------------------------#
# Description: Interface defines method, which each Unit has to implement
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Unit::IUnit;

use Class::Interface;
&interface;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Process data, emmited, when item export finis
sub ProcessItemResult;

# Process data, emmited, when group export finis
sub ProcessGroupResult;

# Get actual total resul od export group
sub Result;

sub GetErrorsCnt;

sub GetWarningsCnt;

# Get total progress
sub GetProgress;

# Get manager, which keep information about item export errors
sub GetGroupItemResultMngr;

# Get manager, which keep information about group export errors
sub GetGroupResultMngr;

# Return class, which contain code responsible for export 
sub GetExportClass;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

