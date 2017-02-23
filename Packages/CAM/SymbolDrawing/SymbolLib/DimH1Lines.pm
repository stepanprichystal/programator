
#-------------------------------------------------------------------------------------------#
# Description: 'Dimension' type of (but 90 degree ccw rotated):
# $x - position
#
#  ______\|/   - $length1
#         |    - $length2
#  ______ |
#        /|\   - $length3
#         |
#         |    -

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::SymbolLib::DimH1Lines;
use base ("Packages::CAM::SymbolDrawing::Symbol::SymbolBase");

use Class::Interface;

&implements('Packages::CAM::SymbolDrawing::Symbol::ISymbol');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::SymbolDrawing::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimH1';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $type1   = shift;    # if dimension si on top/bot
	my $type2   = shift;    # if dimension is on right/left
	my $height  = shift;    # height of helper lines
	my $length1 = shift;
	my $length2 = shift;
	my $length3 = shift;
	my $line    = shift;    # both/first/second first= only first line showed, second = only second line showed

	my $symbol        = shift;    # symbol of dim lines
	my $textValue     = shift;    # text value of dimension
	my $textHeight    = shift;    # font size in mm
	my $textLineWidth = shift;    # font size in mm
	my $textMirror    = shift;
	my $textAngle     = shift;

	my $polarity = shift;

	my $self = {};
	$self = $class->SUPER::new($polarity);
	bless $self;

	if ( $type1 eq "top" ) {
		$self->{"height"} = $height;
	}
	else {
		$self->{"height"} = -1 * $height;
	}

	$self->{"type1"}         = $type1;
	$self->{"type2"}         = $type2;
	$self->{"y"}             = 0;
	$self->{"length1"}       = $length1;
	$self->{"length2"}       = $length2;
	$self->{"length3"}       = $length3;
	$self->{"line"}          = $line;
	$self->{"symbol"}        = $symbol;
	$self->{"textValue"}     = $textValue;
	$self->{"textHeight"}    = $textHeight;
	$self->{"textLineWidth"} = $textLineWidth;
	$self->{"textMirror"}    = $textMirror;
	$self->{"textAngle"}     = $textAngle;

	$self->__DefineSymbol();

	return $self;
}

sub __DefineSymbol {
	my $self = shift;

	# define standard DimH dimension
	my $dimV1 = DimH1->new(
							$self->{"type2"},      $self->{"length1"},   $self->{"length2"},    $self->{"length3"},
							$self->{"symbol"},     $self->{"textValue"}, $self->{"textHeight"}, $self->{"textLineWidth"},
							$self->{"textMirror"}, $self->{"textAngle"}
	);

	$self->AddSymbol( $dimV1, Point->new( 0, $self->{"height"} ) );

	# add vertical helper lines

	if ( $self->{"line"} eq "both" || $self->{"line"} eq "first" ) {

		$self->AddPrimitive(
							 PrimitiveLine->new(
												 Point->new( $self->{"x2"}, $self->{"y"} ),
												 Point->new( $self->{"x2"}, $self->{"y"} + $self->{"height"} ),
												 $self->{"symbol"}
							 )
		);
	}
	if ( $self->{"line"} eq "both" || $self->{"line"} eq "second" ) {
		my $xPosLine2 = undef;

		if ( $self->{"type2"} eq "left" ) {
			$xPosLine2 = -1 * $self->{"length2"};
		}
		else {
			$xPosLine2 = $self->{"length2"};
		}

		$self->AddPrimitive(
							 PrimitiveLine->new(
												 Point->new( $xPosLine2, $self->{"y"} ),
												 Point->new( $xPosLine2, $self->{"y"} + $self->{"height"} ),
												 $self->{"symbol"}
							 )
		);

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

