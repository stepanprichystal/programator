
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::TableLayout::StyleLayout::TextStyle;
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

	my $textType   = shift;
	my $size       = shift;
	my $color      = shift // Color->new( 0, 0, 0 );
	my $font       = shift // Enums->Font_NORMAL;
	my $fontFamily = shift // Enums->FontFamily_ARIAL;
	my $HAlign     = shift // Enums->TextHAlign_LEFT;
	my $VAlign     = shift // Enums->TextVAlign_TOP;
	my $margin     = shift // 0;

	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"textType"}   = $textType;
	$self->{"size"}       = $size;
	$self->{"color"}      = $color;
	$self->{"font"}       = $font;
	$self->{"fontFamily"} = $fontFamily;
	$self->{"HAlign"}     = $HAlign;
	$self->{"VAlign"}     = $VAlign;
	$self->{"margin"}     = $margin;

	return $self;
}

sub SetColor {
	my $self = shift;

	$self->{"color"} = shift;
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

