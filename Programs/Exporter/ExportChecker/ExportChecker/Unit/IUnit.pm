
#-------------------------------------------------------------------------------------------#
# Description: Prostrednik mezi formularem jednotky a buildere,
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit;


use Class::Interface;
&interface;    


#3th party library
use strict;
use warnings;

#local library


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# set default data fo controls, which are on exported forms
# default data means, settings, which are ussualy exported for given group
sub InitDataMngr;

# Do checking before export, based on group group data.
# Group data/ (= default data before user change them in GUI)
#sub CheckBeforeExport;

# When group form is buiild, refresh controls based on default/group data
#sub RefreshGUI;


#sub GetGroupDefaultState;
#sub GetGroupActualState;

# Return group data, either default data or changed by user
#sub GetGroupData;

# Return data intended for final export
#sub GetExportData;



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

