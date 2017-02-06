
#-------------------------------------------------------------------------------------------#
# Description: 'Code' type of:
#        - $lineStart
#  \|/   - $frstArrowPoint   - zero point of this symbol
#   |
#   |
#  /|\   - $secArrowPoint
#   |
#   |    - $lineEnd

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::SymbolLib::DimVertical1;
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
	my $class = shift;

	my $frstArrowPoint = shift;
	my $secArrowPoint  = shift;
	my $lineStart      = shift;
	my $lineEnd        = shift;
	my $symbol         = shift;    # symbol of dim lines

	my $textValue     = shift;
	my $textHeight    = shift;     # font size in mm
	my $textLineWidth = shift;     # font size in mm
	my $textMirror    = shift;
	my $textAngle     = shift;

	my $polarity = shift;

	my $self = {};
	$self = $class->SUPER::new( Point->new(), $polarity );
	bless $self;

	$self->{"frstArrowPoint"} = $frstArrowPoint;
	$self->{"secArrowPoint"}  = $secArrowPoint;
	$self->{"lineStart"}      = $lineStart;
	$self->{"lineEnd"}        = $lineEnd;

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
	my $arrwSize = abs( $self->{"frstArrowPoint"}->Y() - $self->{"lineStart"}->Y() );

	# 1. arrow
	my $arrw1LeftLine = PrimitiveLine->new( $self->{"frstArrowPoint"},
											Point->new( $self->{"frstArrowPoint"}->X() - $arrwSize, $self->{"frstArrowPoint"}->Y() + $arrwSize ),
											$self->{"symbol"} );
	my $arrw1RightLine = $arrw1LeftLine->Copy();
	$arrw1RightLine->MirrorY();

	$self->AddPrimitive($arrw1LeftLine);
	$self->AddPrimitive($arrw1RightLine);

	# 2. arrow

	my $arrw2LeftLine = PrimitiveLine->new( $self->{"secArrowPoint"},
											Point->new( $self->{"secArrowPoint"}->X() - $arrwSize, $self->{"secArrowPoint"}->Y() - $arrwSize ),
											$self->{"symbol"} );
	my $arrw2RightLine = $arrw2LeftLine->Copy();
	$arrw2RightLine->MirrorY();

	$self->AddPrimitive($arrw2LeftLine);
	$self->AddPrimitive($arrw2RightLine);

	# code line

	$self->AddPrimitive( PrimitiveLine->new( $self->{"lineStart"}, $self->{"lineEnd"}, $self->{"symbol"} ) );

	# add text value

	my $textPos = $self->{"lineEnd"}->Copy();
	$textPos->Move( 5, 0 );
	
	$self->AddPrimitive(
						 PrimitiveText->new(  $self->{"textValue"},  $textPos,             $self->{"textHeight"},
											 $self->{"textLineWidth"}, $self->{"textMirror"},  $self->{"textAngle"}, $self->GetPolarity()
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

