#-------------------------------------------------------------------------------------------#
# Description: Class which represent primitive geometric - text
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::PrimitiveText;
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
	my $value     = shift;
	my $position  = shift;               # text position in mm
	my $height    = shift;               # char height  in mm
	my $width     = shift // $height;    # char width  in mm (default same as height)
	my $lineWidth = shift;               # char lines width in mm
	my $mirror    = shift;
	my $angle     = shift;
	my $polarity  = shift;               #

	my $self = {};
	$self = $class->SUPER::new( Enums->Primitive_TEXT, $polarity );
	bless $self;

	$self->{"value"}     = $value;
	$self->{"position"}  = $position;
	$self->{"height"}    = $height;
	$self->{"width"}     = $width;
	$self->{"lineWidth"} = $lineWidth;
	$self->{"mirror"}    = $mirror;
	$self->{"angle"}     = $angle;

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

sub GetValue {
	my $self = shift;

	return $self->{"value"};
}

sub GetPosition {
	my $self = shift;

	return $self->{"position"};
}

sub GetHeight {
	my $self = shift;

	return $self->{"height"};
}

sub GetWidth {
	my $self = shift;

	return $self->{"width"};
}

sub GetLineWidth {
	my $self = shift;

	return $self->{"lineWidth"};
}

sub GetMirror {
	my $self = shift;

	return $self->{"mirror"};
}

sub GetAngle {
	my $self = shift;

	return $self->{"angle"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

