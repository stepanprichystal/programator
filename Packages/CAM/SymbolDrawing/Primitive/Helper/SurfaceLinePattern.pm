
#-------------------------------------------------------------------------------------------#
# Description: Class which represent line surface pattern
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceLinePattern;

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

	$self->{"outline_draw"}  = shift;
	$self->{"outline_width"} = shift;
	$self->{"lines_angle"}   = shift;
	$self->{"outline_invert"}   = shift;
	$self->{"lines_width"}   = shift;
	$self->{"lines_dist"}    = shift;
	
	$self->{"predefined_pattern_type"}    = "lines";

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

sub GetLines_angle {
	my $self = shift;

	return $self->{"lines_angle"};
}

sub GetOutline_invert {
	my $self = shift;

	return $self->{"outline_invert"};
}


sub GetLines_width {
	my $self = shift;

	return $self->{"lines_width"};
}

sub GetLines_dist {
	my $self = shift;

	return $self->{"lines_dist"};
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

