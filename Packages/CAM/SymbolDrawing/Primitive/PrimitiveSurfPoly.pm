
#-------------------------------------------------------------------------------------------#
# Description: Class which represent primitive geometric - surface created by polygon
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly;
use base ("Packages::CAM::SymbolDrawing::Primitive::PrimitiveBase");

use Class::Interface;

&implements('Packages::CAM::SymbolDrawing::Primitive::IPrimitive');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSolidPattern';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class    = shift;
	my $points   = shift;    #
	my $pattern  = shift;
	my $polarity = shift;    #

	my $self = {};
	$self = $class->SUPER::new( Enums->Primitive_SURFACEPOLY, $polarity );
	bless $self;

	$self->{"points"} = $points;
	$self->{"pattern"} = $pattern;
	
	# Set default pattern solid
	unless ( defined $self->{"pattern"} ) {
		$self->{"pattern"} = SurfaceSolidPattern->new( 0, 0 );
	}

	return $self;
}

sub MirrorY {
	my $self = shift;
	
	foreach my $p (@{$self->{"points"}}){
		
		$p->{"x"} *= -1;
		$p->{"x"}   *= -1;
	}	
}

sub MirrorX {
	my $self = shift;
	
	foreach my $p (@{$self->{"points"}}){
		
		$p->{"y"} *= -1;
		$p->{"y"}   *= -1;
	}	
}

sub GetPoints {
	my $self = shift;

	return @{$self->{"points"}};
}

sub GetPattern {
	my $self = shift;

	return $self->{"pattern"};
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

