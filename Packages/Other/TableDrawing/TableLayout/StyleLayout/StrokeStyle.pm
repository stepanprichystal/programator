
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::TableLayout::StyleLayout::StrokeStyle;
use base qw(Packages::Other::TableDrawing::TableLayout::TableLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');


#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
use aliased 'Packages::Other::TableDrawing::Enums';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	
	my $strokeStyle = shift // Enums->StrokeStyle_NONE;
	my $strokeWidth = shift // 0;
	my $strokeColor = shift // Color->new();
	my $dashLen   = shift // 0;
	my $gapLen    = shift // 0;
	
	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"strokeStyle"} = $strokeStyle;
	$self->{"strokeWidth"} = $strokeWidth;
	$self->{"strokeColor"} = $strokeColor;
	$self->{"dashLen"}   = $dashLen;
	$self->{"gapLen"}    = $gapLen;
 
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

