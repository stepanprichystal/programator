
#-------------------------------------------------------------------------------------------#
# Description: Prosuct press represent layers which are pressed together
# Layer can by material or nested Press product or nested Input product
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::StackupProduct::ProductPress;
use base('Packages::Stackup::Stackup::StackupProduct::ProductBase');

use Class::Interface;
&implements('Packages::Stackup::Stackup::StackupProduct::IProduct');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Stackup::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"productType"} = Enums->Product_PRESS;

	#Pressing order
	$self->{"order"} = shift;
	
	# Layers, which are pressed after this sequential press
	# List contains references to list of all layers
	# Typical layer types coverlay and No Flow prepregs
	$self->{"extraLayers"} = [];

	return $self;
}

sub GetPressOrder {
	my $self = shift;

	return $self->{"order"};
}

sub GetExistExtraPress{
	my $self = shift;
	
	return scalar(@{$self->{"extraLayers"} }) ? 1 : 0;
}

sub GetExtraPressLayers{
	my $self = shift;
	
	return @{$self->{"extraLayers"} };
}

sub AddExtraPressLayers{
	my $self = shift;
	my $layers = shift;
	
	push( @{$self->{"extraLayers"} }, @{$layers});
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

