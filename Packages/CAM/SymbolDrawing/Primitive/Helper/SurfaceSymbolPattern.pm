
#-------------------------------------------------------------------------------------------#
# Description: Class which represent line surface pattern
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSymbolPattern;

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
	
	$self->{"symbol"} = shift;
	$self->{"symbolDX"} = shift;
	$self->{"symbolDY"} = shift;
	
	$self->{"predefined_pattern_type"}    = "symbol";

	return $self;
}
 
sub GetPredefined_pattern_type {
	my $self = shift;

	return $self->{"predefined_pattern_type"};
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

sub GetSymbol {
	my $self = shift;

	return $self->{"symbol"};
}

sub GetSymbolDX {
	my $self = shift;

	return $self->{"symbolDX"};
}

sub GetSymbolDY {
	my $self = shift;

	return $self->{"symbolDY"};
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

