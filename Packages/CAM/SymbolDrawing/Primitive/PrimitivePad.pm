#-------------------------------------------------------------------------------------------#
# Description: Class which represent primitive geometric - pad
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::PrimitivePad;
use base ("Packages::CAM::SymbolDrawing::Primitive::PrimitiveBase");

use Class::Interface;

&implements('Packages::CAM::SymbolDrawing::Primitive::IPrimitive');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::Enums';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $symbol     = shift; # r2000, s400, ..
	my $position  = shift;    # font size in mm
	my $mirror    = shift;
	my $polarity  = shift;    #

	my $self = {};
	$self = $class->SUPER::new( Enums->Primitive_PAD, $polarity );
	bless $self;

	$self->{"symbol"}     = $symbol;
	$self->{"position"}  = $position;
	$self->{"mirror"}    = $mirror;


	return $self;
}

sub MirrorY {
	my $self = shift;
	$self->{"position"}->{"x"} *= -1;

}

sub MirrorX {
	my $self = shift;
	$self->{"position"}->{"y"} *= -1;

}

sub GetSymbol {
	my $self = shift;

	return $self->{"symbol"};
}

sub GetPosition {
	my $self = shift;

	return $self->{"position"};
}

 
 

sub GetMirror {
	my $self = shift;

	return $self->{"mirror"};
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

