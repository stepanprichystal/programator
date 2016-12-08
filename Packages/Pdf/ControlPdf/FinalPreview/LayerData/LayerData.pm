
#-------------------------------------------------------------------------------------------#
# Description: Special layer - Copper, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::FinalPreview::LayerData::LayerData;


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

	$self->{"type"} = shift;
	$self->{"order"} = undef;
	$self->{"color"} = undef;
	$self->{"output"} = undef;
	
	my @l = ();
	$self->{"singleLayers"}    = \@l; 
 
	return $self;  
}
 
 
sub GetColor{
	my $self = shift;
	return $self->{"color"};
}

sub SetColor{
	my $self = shift;
	my $color = shift;
	
	
	$self->{"color"} = $color;
}

sub GetType{
	my $self = shift;
	 
	return $self->{"type"};
}

 
sub GetSingleLayers{
	my $self = shift;
	return @{$self->{"singleLayers"}};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

