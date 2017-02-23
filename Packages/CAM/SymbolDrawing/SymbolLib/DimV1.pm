
#-------------------------------------------------------------------------------------------#
# Description: 'Dimension' type of:
#
#  \|/   - length 1
#   |	 - length 2
#   |
#  /|\   - length 3
#   |
#   |

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::SymbolLib::DimV1;
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
	my $type    = shift;    # if dimension is on top/bot side
	my $length1 = shift;    # see description
	my $length2 = shift;
	my $length3 = shift;
	my $symbol  = shift;    # symbol of dim lines

	my $textValue     = shift;    # text of dimension
	my $textHeight    = shift;    # font size in mm
	my $textLineWidth = shift;    # font size in mm
	my $textMirror    = shift;
	my $textAngle     = shift;

	my $polarity = shift;

	my $self = {};
	$self = $class->SUPER::new($polarity);
	bless $self;

	$self->{"x"} = 0;

	my $sign = 1;
	if ( $type eq "bot" ) {
		$sign *= -1;
	}

	$self->{"y1"} = $sign * ( -$length1 );
	$self->{"y2"} = $sign * (0);
	$self->{"y3"} = $sign * ($length2);
	$self->{"y4"} = $sign * ( $length2 + $length3 );

	$self->{"textValue"}     = $textValue;
	$self->{"textHeight"}    = $textHeight;
	$self->{"textLineWidth"} = $textLineWidth;
	$self->{"textMirror"}    = $textMirror;
	$self->{"textAngle"}     = $textAngle;

	$self->{"symbol"} = $symbol;

	$self->__DefineSymbol();

	return $self;
}

sub __DefineSymbol {
	my $self = shift;

	# get size of arrw in x,y
	my $arrwSize = $self->{"y1"} - $self->{"y2"};

	# 1. arrow
	my $arrw1LeftLine = PrimitiveLine->new( Point->new( $self->{"x"}, $self->{"y2"} ),
										   Point->new( $self->{"x"} - $arrwSize, $self->{"y2"} + $arrwSize ),
										   $self->{"symbol"} );
	my $arrw1RightLine = $arrw1LeftLine->Copy();
	$arrw1RightLine->MirrorY();

	$self->AddPrimitive($arrw1LeftLine);
	$self->AddPrimitive($arrw1RightLine);

	# 2. arrow

	my $arrw2LeftLine = PrimitiveLine->new( Point->new( $self->{"x"}, $self->{"y3"} ),
										   Point->new( $self->{"x"} - $arrwSize, $self->{"y3"} - $arrwSize ),
										   $self->{"symbol"} );
	my $arrw2RightLine = $arrw2LeftLine->Copy();
	$arrw2RightLine->MirrorY();

	$self->AddPrimitive($arrw2LeftLine);
	$self->AddPrimitive($arrw2RightLine);

	# code line

	$self->AddPrimitive(
					  PrimitiveLine->new( Point->new( $self->{"x"}, $self->{"y1"} ), Point->new( $self->{"x"}, $self->{"y4"} ), $self->{"symbol"} ) );

	# add text value

	my $textPos = Point->new( $self->{"x"} + 2 , $self->{"y4"});

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

