
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::Table::Style::StrokeStyle;

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

	$self->{"strokeStyle"} = shift // Enums->StrokeStyle_NONE;
	$self->{"strokeWidth"} = shift // 0;
	$self->{"strokeColor"} = shift // Color->new();
	$self->{"dashLen"}   = shift // 0;
	$self->{"gapLen"}    = shift // 0;

	return $self;
}

sub GetStyle {
	my $self = shift;

	return $self->{"strokeStyle"};

}

sub GetWidth {
	my $self = shift;

	return $self->{"strokeWidth"};

}

sub GetColor {
	my $self = shift;

	return $self->{"strokeColor"};
}

sub GetDashLen {
	my $self = shift;

	return $self->{"dashLen"};
}

sub GetGapLen {
	my $self = shift;

	return $self->{"gapLen"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

