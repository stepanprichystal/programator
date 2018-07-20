
#-------------------------------------------------------------------------------------------#
# Description: 'Dimension' type of:
#		
#  /|\   - length 1
#   |	 
#   |	 - length 2
#   |
#  \|/   - zero is here


# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::SymbolLib::DimV1In;
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
	#my $type    = shift;    # if dimension is on top/bot side
	my $length1 = shift;    # see description. In mm
	my $length2 = shift;	# see description. In mm
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
 

	$self->{"y1"} = 0;
	$self->{"y2"} = $length1;
	$self->{"y3"} = $length2 - $length1;
	$self->{"y4"} = $length2;

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
	my $arrwSize = $self->{"y2"} - $self->{"y1"};

	# 1. arrow bot
	my $arrw1LeftLine = PrimitiveLine->new( Point->new( $self->{"x"}, $self->{"y1"} ),
										   Point->new( $self->{"x"} - $arrwSize/2,   $arrwSize ),
										   $self->{"symbol"} );
	my $arrw1RightLine = $arrw1LeftLine->Copy();
	$arrw1RightLine->MirrorY();

	$self->AddPrimitive($arrw1LeftLine);
	$self->AddPrimitive($arrw1RightLine);

	# 2. arrow top

	my $arrw2LeftLine = PrimitiveLine->new( Point->new( $self->{"x"}, $self->{"y4"} ),
										   Point->new( $self->{"x"} - $arrwSize/2, $self->{"y3"} ),
										   $self->{"symbol"} );
	my $arrw2RightLine = $arrw2LeftLine->Copy();
	$arrw2RightLine->MirrorY();

	$self->AddPrimitive($arrw2LeftLine);
	$self->AddPrimitive($arrw2RightLine);

	# code line

	$self->AddPrimitive(
					  PrimitiveLine->new( Point->new( $self->{"x"}, $self->{"y1"} ), Point->new( $self->{"x"}, $self->{"y4"} ), $self->{"symbol"} ) );

	# add text value
	my $posx = 2;
	if($self->{"textMirror"}){
		$posx *=-1;
	}
	my $textPos = Point->new( $self->{"x"} + $posx , $self->{"y4"} /2);

	$self->AddPrimitive(
						 PrimitiveText->new(
											 $self->{"textValue"},  $textPos,             $self->{"textHeight"}, undef, $self->{"textLineWidth"},
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

