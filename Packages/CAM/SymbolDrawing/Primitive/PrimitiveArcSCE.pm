
#-------------------------------------------------------------------------------------------#
# Description: Class which represent primitive geometric - arc defined by start-center-end point
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::PrimitiveArcSCE;
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
	my $class    = shift;
	my $startP   = shift;
	my $centerP  = shift;
	my $endP     = shift;
	my $direction = shift; # cw/ccw, default is cw
	my $symbol   = shift;
	my $polarity = shift;    #
	

	my $self = {};
	$self = $class->SUPER::new( Enums->Primitive_ARCSCE, $polarity );
	bless $self;

	$self->{"startP"}  = $startP;
	$self->{"centerP"} = $centerP;
	$self->{"endP"}    = $endP;
	
	
	$self->{"direction"}  = $direction;
	unless($self->{"direction"})
	{
		$self->{"direction"} = "cw";
	}
	
	
	
	$self->{"symbol"}  = $symbol;

	return $self;
}

sub MirrorY {
	my $self = shift;
	$self->{"startP"}->{"x"} *= -1;
	$self->{"endP"}->{"x"}   *= -1;
}

sub MirrorX {
	my $self = shift;
	$self->{"startP"}->{"y"} *= -1;
	$self->{"endP"}->{"y"}   *= -1;
}

sub GetStartP {
	my $self = shift;

	return $self->{"startP"};
}

sub GetCenterP {
	my $self = shift;

	return $self->{"centerP"};
}

sub GetEndP {
	my $self = shift;

	return $self->{"endP"};
}

sub GetDirection {
	my $self = shift;

	return $self->{"direction"};
}

sub GetSymbol {
	my $self = shift;

	return $self->{"symbol"};
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

