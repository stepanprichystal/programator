
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::Table::Style::BackgStyle;

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
use aliased 'Packages::Other::TableDrawing::Enums';
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"backgStyle"} = shift // Enums->BackgStyle_NONE;
	$self->{"backgColor"} = shift // Color->new();

	return $self;
}

sub GetBackgStyle {
	my $self = shift;

	return $self->{"backgStyle"};

}

sub GetBackgColor {
	my $self = shift;

	return $self->{"backgColor"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

