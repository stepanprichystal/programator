
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::OutputData::LayerData::LayerData;

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

	$self->{"type"}   = shift; # type of Packages::Gerbers::OutputData::Enums
	$self->{"oriLayer"}   = shift;    # ori matrix layer
	
	$self->{"enTit"} = shift; # titles
	$self->{"czTit"} = shift;
	$self->{"enInf"} = shift; # description
	$self->{"czInf"} = shift;
	
	$self->{"output"} = shift;    # name of prepared layer in matrix
	
	$self->{"number"} = undef;    # when more "layerData" has similar "oriLayer" type, this is unique number
	
	$self->{"parent"} = undef;    # soma layer can be connect with another layer (eg drill map parent layer, contan data which are use for creaet drill map)

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

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub GetOriLayer {
	my $self = shift;

	return $self->{"oriLayer"};
}

sub GetNumber {
	my $self = shift;
	
	return $self->{"number"}
	
}

sub GetTitle {
	my $self = shift;
	my $cz = shift;
	
	if($cz){
		return  $self->{"czTit"};
	}else{
		
		return  $self->{"enTit"};
	}
}

sub GetInfo {
	my $self = shift;
	my $cz = shift;
	
	if($cz){
		return  $self->{"czInf"};
	}else{
		
		return  $self->{"enInf"};
	}
}


sub SetParent {
	my $self = shift;

	$self->{"parent"} = shift;
}


sub GetParent {
	my $self = shift;

	return $self->{"parent"};
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

