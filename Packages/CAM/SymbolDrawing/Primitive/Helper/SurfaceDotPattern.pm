
#-------------------------------------------------------------------------------------------#
# Description: Class which represent dots surface pattern
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceDotPattern;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"outline_draw"}   = shift;
	$self->{"outline_width"}  = shift;
	$self->{"outline_invert"} = shift;
	$self->{"dots_shape"}     = shift;    # square/circle
	$self->{"dots_diameter"}  = shift;
	$self->{"dots_grid"}      = shift;
	$self->{"indentation"}    = shift;    # odd/even

	$self->{"predefined_pattern_type"} = "dots";

	return $self;
}

sub GetOutline_draw {
	my $self = shift;

	return $self->{"outline_draw"};
}

sub GetOutline_width {
	my $self = shift;

	return $self->{"outline_width"};
}

sub GetOutline_invert {
	my $self = shift;

	return $self->{"outline_invert"};
}

sub GetDots_shape {
	my $self = shift;

	return $self->{"dots_shape"};
}

sub GetDots_diameter {
	my $self = shift;

	return $self->{"dots_diameter"};
}

sub GetDots_grid {
	my $self = shift;

	return $self->{"dots_grid"};
}

sub GetIndentation {
	my $self = shift;

	return $self->{"indentation"};
}

sub GetPredefined_pattern_type {
	my $self = shift;

	return $self->{"predefined_pattern_type"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

