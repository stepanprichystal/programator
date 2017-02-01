
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::ProduceData::LayerData::LayerData;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"type"}   = shift;
	$self->{"name"}   = shift;    # physic name of file
	$self->{"title"}  = shift;    # description of layer
	$self->{"info"}   = shift;    # extra info of layer
	$self->{"output"} = undef;    # name of prepared layer in matrix

	return $self;
}

sub SetOutput {
	my $self = shift;

	$self->{"output"} = shift;
}

sub GetOutput {
	my $self = shift;

	return $self->{"output"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

