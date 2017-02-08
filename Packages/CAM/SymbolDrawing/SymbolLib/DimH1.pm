
#-------------------------------------------------------------------------------------------#
# Description: 'Code' type of (but rotated 90 degree ccw):
#
#  \|/   - length 1
#   |	 - length 2
#   |
#  /|\   - length 3
#   |
#   |

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::SymbolLib::DimH1;
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

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $type    = shift;    # if dimension is on right/left side
	my $length1 = shift;    # see description
	my $length2 = shift;
	my $length3 = shift;
	my $symbol  = shift;    # symbol of dim lines

	my $textValue     = shift;    # text of dimension
	my $textHeight    = shift;    # font size in mm
	my $textLineWidth = shift;    # font size in mm
	my $textMirror    = shift;
	my $textAngle     = shift;
	my $textPosition     = shift; #top/bot

	my $polarity = shift;
	
	$textPosition = defined $textPosition? $textPosition : "top";

	my $self = {};
	$self = $class->SUPER::new($polarity);
	bless $self;

	$self->{"y"} = 0;

	my $sign = 1;
	if ( $type eq "left" ) {
		$sign *= -1;
	}

	$self->{"x1"} = $sign * ( -$length1 );
	$self->{"x2"} = $sign * (0);
	$self->{"x3"} = $sign * ($length2);
	$self->{"x4"} = $sign * ( $length2 + $length3 );

	$self->{"textValue"}     = $textValue;
	$self->{"textHeight"}    = $textHeight;
	$self->{"textLineWidth"} = $textLineWidth;
	$self->{"textMirror"}    = $textMirror;
	$self->{"textAngle"}     = $textAngle;
	$self->{"textPosition"}     = $textPosition;

	$self->{"symbol"} = $symbol;

	$self->__DefineSymbol();

	return $self;
}

sub __DefineSymbol {
	my $self = shift;

	# get size of arrw in x,y
	my $arrwSize = $self->{"x2"} - $self->{"x1"};

	# 1. arrow
	my $arrw1BotLine = PrimitiveLine->new( Point->new( $self->{"x2"}, $self->{"y"} ),
										   Point->new( $self->{"x2"} - $arrwSize, $self->{"y"} - $arrwSize ),
										   $self->{"symbol"} );
	my $arrw1TopLine = $arrw1BotLine->Copy();
	$arrw1TopLine->MirrorX();

	$self->AddPrimitive($arrw1BotLine);
	$self->AddPrimitive($arrw1TopLine);

	# 2. arrow

	my $arrw2BotLine = PrimitiveLine->new( Point->new( $self->{"x3"}, $self->{"y"} ),
										   Point->new( $self->{"x3"} + $arrwSize, $self->{"y"} - $arrwSize ),
										   $self->{"symbol"} );
	my $arrw2TopLine = $arrw2BotLine->Copy();
	$arrw2TopLine->MirrorX();

	$self->AddPrimitive($arrw2BotLine);
	$self->AddPrimitive($arrw2TopLine);

	# code line

	$self->AddPrimitive(
					  PrimitiveLine->new( Point->new( $self->{"x1"}, $self->{"y"} ), Point->new( $self->{"x4"}, $self->{"y"} ), $self->{"symbol"} ) );

	# add text value

	my $textPos = Point->new( $self->{"x4"}, $self->{"y"} + 5 );

	$self->AddPrimitive(
						 PrimitiveText->new(
											 $self->{"textValue"},  $textPos,             $self->{"textHeight"}, $self->{"textLineWidth"},
											 $self->{"textMirror"}, $self->{"textAngle"}, $self->GetPolarity()
						 )
	);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

