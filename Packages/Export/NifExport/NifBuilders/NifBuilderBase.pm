
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::NifBuilders::NifBuilderBase;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;
	
	#require rows in nif section
	$self->{"require"} = shift;
	
	return $self;
}

sub Init{
	my $self = shift;
	
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift; 
	$self->{"nifData"} = shift; 
	$self->{"layerCnt"} = shift;
	
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

