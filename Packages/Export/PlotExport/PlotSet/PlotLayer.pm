#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::PlotSet::PlotLayer;

#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

 
 sub new {
	my $class     = shift;
	my $self ={};
	 
	bless $self;
	
 	$self->{"name"} = shift;
 	$self->{"polarity"} = shift;
  	$self->{"mirror"} = shift;
 	$self->{"compensation"} = shift;
 
	return $self;
}

 
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
