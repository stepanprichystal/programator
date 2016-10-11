#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::PlotSet::PlotSet;

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
	
 	$self->{"orientation"} = shift;
 	$self->{"filmSize"} = shift;
 	$self->{"layers"} = shift;
 
	return $self;
}

sub GetLayers{
	my $self = shift;
	
	return @{$self->{"layers"}};
	
}

sub GetOrientation{
	my $self = shift;
	
	return $self->{"orientation"};
	
}

sub GetFilmSize{
	my $self = shift;
	
	return $self->{"filmSize"};
	
}

  
1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 

}

1;
