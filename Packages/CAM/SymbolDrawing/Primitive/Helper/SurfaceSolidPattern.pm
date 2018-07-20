
#-------------------------------------------------------------------------------------------#
# Description: Class which represent line surface pattern
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSolidPattern;

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
	$self->{"outline_invert"} = shift;
	
	$self->{"predefined_pattern_type"}    = "solid";

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

 
sub GetPredefined_pattern_type {
	my $self = shift;

	return $self->{"predefined_pattern_type"};
}


sub GetOutline_invert {
	my $self = shift;

	return $self->{"outline_invert"};
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

