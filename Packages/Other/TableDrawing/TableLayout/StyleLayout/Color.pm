
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::TableLayout::StyleLayout::Color;
use base qw(Packages::Other::TableDrawing::TableLayout::TableLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
use aliased 'Packages::Other::TableDrawing::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my @rgbARG = @_;

		my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	if ( scalar(@rgbARG) == 1 ) {

		# overload - color defined as string (3 numbers separated by coma)
		my $str = $rgbARG[0];
		$str =~ s/\s//g;
		my @rgb = split( ",", $str );

		$self->{"R"} = $rgb[0] // 255;
		$self->{"G"} = $rgb[1] // 255;
		$self->{"B"} = $rgb[2] // 255;

	}
	elsif ( scalar(@rgbARG) == 3 ) {

		# overload - color defined three separated values

		$self->{"R"} = $rgbARG[0] // 255;
		$self->{"G"} = $rgbARG[1] // 255;
		$self->{"B"} = $rgbARG[2] // 255;
	}

	return $self;
}

sub GetHexCode {
	my $self = shift;

	my $hex = sprintf( "%.2x%.2x%.2x", $self->{"R"}, $self->{"G"}, $self->{"B"} );

	return "#" . $hex;

}

# Coonver color to gray scale
# Return value 0-255
# 0 - black
# 255 - white
sub GetGrayScale {
	my $self = shift;
 
	my $val =   0.30 * $self->{"R"} + 0.59 * $self->{"G"} + 0.11 * $self->{"B"};

	return $val;
}




#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

