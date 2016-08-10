#-------------------------------------------------------------------------------------------#
# Description: Helper module for InCAM Drill tool manager
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::ProductionPanel::Helper;

#3th party library
use strict;
use warnings;

#loading of locale modules


#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#


# Return cu-mark for drilled cu thickness number
sub __GetCuThickPanelMark {
	my $self    = shift;
	my $cuThick = shift;

	my $mark = "";

	if ($cuThick) {

		if ( $cuThick <= 17 ) {
			$mark = "/";
		}
		elsif ( $cuThick <= 34 ) {
			$mark = "-";
		}
		elsif ( $cuThick <= 69 ) {
			$mark = ":";
		}
		elsif ( $cuThick <= 104 ) {
			$mark = "+";
		}
		else {
			$mark = "++";
		}
	}

	return $mark;

}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


	 
print "\n1";
}

1;