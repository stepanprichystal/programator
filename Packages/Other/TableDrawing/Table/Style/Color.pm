
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::Table::Style::Color;

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
	my $class = shift;
	my $self  = {};
	bless $self;

	if ( @_ == 1 ) {

		# overload - color defined as string (3 numbers separated by coma)
		my $str = shift;
		$str =~ s/\s//g;
		my @rgb = split( ",", $str );

		$self->{"R"} = $rgb[0] // 255;
		$self->{"G"} = $rgb[1] // 255;
		$self->{"B"} = $rgb[2] // 255;

	}
	elsif ( @_ == 3 ) {

		# overload - color defined three separated values

		$self->{"R"} = shift // 255;
		$self->{"G"} = shift // 255;
		$self->{"B"} = shift // 255;
	}

	return $self;
}

sub GetHexCode {
	my $self = shift;

	my $hex = sprintf( "%.2x%.2x%.2x", $self->{"R"}, $self->{"G"}, $self->{"B"} );

	return "#" . $hex;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

