
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
sub CheckBeforeExport;

# When group form is buiild, refresh controls based on default/group data
sub RefreshGUI;

# When group form is buiild, refresh group wrapper
sub RefreshWrapper;

# Get vale, if group is disable, active and on, active and off
sub GetGroupState;

# Set programatically ifgroup is disable, active and on, active and off
sub SetGroupState;


# Update group data by values from GUI
sub UpdateGroupData;

# Return current group data
sub GetGroupData;

# Return data intended for final export
sub GetExportData;





#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

