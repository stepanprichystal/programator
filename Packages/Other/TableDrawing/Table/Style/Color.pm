
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

	$self->{"R"} = shift // 255;
	$self->{"G"} = shift // 255;
	$self->{"B"} = shift // 255;

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

