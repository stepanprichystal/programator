#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::FilmCreator::FilmCreator;

#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

 
sub Get;
 

 


 
1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;

	use aliased 'HelperScripts::DirStructure';

	DirStructure->Create();

}

1;
