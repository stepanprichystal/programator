
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::Table::TableCell;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Packages::Other::TableDrawing::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"id"}          = shift;
	$self->{"text"}        = shift;
	$self->{"textStyle"}   = shift;
	$self->{"backgStyle"}  = shift;
	$self->{"borderStyle"} = shift;
	$self->{"xPosCnt"}     = shift;    # number of merged cells
	$self->{"yPosCnt"}     = shift;    # number of merged cells

	return $self;
}

sub GetId {
	my $self = shift;
	return $self->{"id"};
}

sub GetText {
	my $self = shift;

	return $self->{"text"};

}

sub GetTextStyle {
	my $self = shift;

	return $self->{"textStyle"};

}

sub GetBackgStyle {
	my $self = shift;

	return $self->{"backgStyle"};

}

sub GetBorderStyle {
	my $self = shift;

	return $self->{"borderStyle"};
}

sub GetIsMerged {
	my $self = shift;

	return ( $self->{"xPosCnt"} > 1 || $self->{"yPosCnt"} > 1 ) ? 1 : 0;
}

sub GetXPosCnt {
	my $self = shift;

	return $self->{"xPosCnt"};
}

sub GetYPosCnt {
	my $self = shift;

	return $self->{"yPosCnt"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

