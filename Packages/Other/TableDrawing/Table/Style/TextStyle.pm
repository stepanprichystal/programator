
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::Table::Style::TextStyle;

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

	$self->{"textType"}   = shift;
	$self->{"size"}       = shift;
	$self->{"color"}      = shift // Color->new( 0, 0, 0 );
	$self->{"font"}       = shift // Enums->Font_NORMAL;
	$self->{"fontFamily"} = shift // Enums->FontFamily_ARIAL;
	$self->{"HAlign"}     = shift // Enums->TextHAlign_LEFT;
	$self->{"VAlign"}     = shift // Enums->TextVAlign_TOP;
	$self->{"margin"}     = shift // 0;

	return $self;
}

sub GetTextType {
	my $self = shift;

	return $self->{"textType"};

}

sub GetSize {
	my $self = shift;

	return $self->{"size"};

}

sub GetColor {
	my $self = shift;

	return $self->{"color"};

}

sub GetFont {
	my $self = shift;

	return $self->{"font"};

}

sub GetFontFamily {
	my $self = shift;

	return $self->{"fontFamily"};
}

sub GetHAlign {
	my $self = shift;

	return $self->{"HAlign"};

}

sub GetVAlign {
	my $self = shift;

	return $self->{"VAlign"};

}

sub GetMargin {
	my $self = shift;

	return $self->{"margin"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

