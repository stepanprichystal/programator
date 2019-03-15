
#-------------------------------------------------------------------------------------------#
# Description: Transition zone class represent border feat between flex and rigid part of pcb
# Feat has always CCW direction (within bend area), thus rigid part of pcb is always on the 
# right of border (in CWW direction)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::FlexiLayers::BendAreaParser::TransitionZone;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Enums::EnumsDrill';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"feature"} = shift;
 
 
	return $self;
}


sub GetFeature{
	my $self = shift;
	
	return $self->{"feature"};
}

sub GetStartPoint{
	my $self = shift;
	
	my %p = ();
	$p{"x"} = $self->{"feature"}->{"x1"};
	$p{"y"} = $self->{"feature"}->{"y1"};
	
	return %p;
}

sub GetEndPoint{
	my $self = shift;
	
	my %p = ();
	$p{"x"} = $self->{"feature"}->{"x2"};
	$p{"y"} = $self->{"feature"}->{"y2"};
	
	return %p;
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

