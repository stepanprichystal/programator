
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::TableLayout::StyleLayout::BackgStyle;
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
	my $backgStyle = shift // Enums->BackgStyle_NONE;
	my $backgColor  = shift // Color->new();
	
	my $self       = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"backgStyle"} = $backgStyle;
	$self->{"backgColor"} = $backgColor;

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

