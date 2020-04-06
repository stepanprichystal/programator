
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

	$self->{"id"}         = shift;
	$self->{"key"}         = shift;
	$self->{"height"}      = shift;
	$self->{"backgStyle"}  = shift;
	$self->{"borderStyle"} = shift ;

	return $self;
}

sub GetId {
	my $self = shift;

	return $self->{"id"};

}

sub GetKey {
	my $self = shift;

	return $self->{"key"};

}

sub GetHeight {
	my $self = shift;

	return $self->{"height"};

}

sub GetBackgStyle {
	my $self = shift;

	return $self->{"backgStyle"};

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

