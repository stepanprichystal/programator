#-------------------------------------------------------------------------------------------#
# Description: Class which represent primitive geometric - polyline
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::PrimitivePolyline;
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
	my $points   = shift;    #
	my $symbol   = shift;
	my $polarity = shift;    #

	my $self = {};
	$self = $class->SUPER::new( Enums->Primitive_POLYLINE, $polarity );
	bless $self;

	$self->{"points"}  = $points;
	$self->{"symbol"} = $symbol;

	return $self;
}

sub MirrorY {
	my $self = shift;

	foreach my $p ( @{ $self->{"points"} } ) {

		$p->{"x"} *= -1;
		$p->{"x"} *= -1;
	}
}

sub MirrorX {
	my $self = shift;

	foreach my $p ( @{ $self->{"points"} } ) {

		$p->{"y"} *= -1;
		$p->{"y"} *= -1;
	}
}
 
sub GetSymbol {
	my $self = shift;

	return $self->{"symbol"};
}

sub GetPoints {
	my $self = shift;

	return @{ $self->{"points"} };
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

