
#-------------------------------------------------------------------------------------------#
# Description: Special layer - Copper, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::LayerData::SingleLayerData;


#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self  = {};
	bless $self;

	$self->{"layer"} = shift;
	$self->{"title"} = shift;
	$self->{"info"} = shift;
 
	return $self;  
}


# return name of copper. Name can be
# c, v2, v3, v4,......, s
sub AddSigleLayer{
	my $self = shift;
	my $l = shift;
	my $lTitle = shift;
	my $lInfo = shift;
	
	return $self->{"copperName"};
}

# Return number from 1 to infinity, according count of cu layers
# c = 1, v2 = 2, v3 = 3, v4 = 4,......, s = order of last layer
sub GetCopperNumber{
	my $self = shift;
	return $self->{"copperNumber"};
}

sub GetUssage{
	my $self = shift;
	return $self->{"usage"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

