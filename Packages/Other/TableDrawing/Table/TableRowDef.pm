
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::Table::TableRowDef;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Packages::Other::TableDrawing::Table::Style::BorderStyle';
use aliased 'Packages::Other::TableDrawing::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"idx"}         = shift;
	$self->{"key"}         = shift;
	$self->{"height"}      = shift;
	$self->{"borderStyle"} = shift // BorderStyle->new();

	return $self;
}

sub GetIndex {
	my $self = shift;

	return $self->{"idx"};

}

sub GetKey {
	my $self = shift;

	return $self->{"key"};

}

sub GetHeight {
	my $self = shift;

	return $self->{"height"};

}

sub GetBorderStyle {
	my $self = shift;

	return $self->{"borderStyle"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

