
#-------------------------------------------------------------------------------------------#
# Description: General surface created by arary of points:
 
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::SymbolLib::Universal;
use base ("Packages::CAM::SymbolDrawing::Symbol::SymbolBase");

use Class::Interface;

&implements('Packages::CAM::SymbolDrawing::Symbol::ISymbol');

#3th party library
use strict;
use warnings;
use Math::Trig;
use Math::Geometry::Planar;
#local library
use aliased 'Packages::CAM::SymbolDrawing::Enums';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveArcSCE';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $angle    = shift;    # angle in degree
	my $length = shift;    # length of left+right line
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

	

	$self->{"angle"} = $angle;
	$self->{"length"} = $length;
	$self->{"symbol"} = $symbol;
	
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

	# compute end points of twho helper lines
	
	my $leftLineXPos = -1* sin( deg2rad($self->{"angle"}/2)) * $self->{"length"};
	my $leftLineYPos = cos( deg2rad($self->{"angle"}/2)) * $self->{"length"};
	
	# Add arc primitive
	
	my $startArcXPos = -1* sin( deg2rad($self->{"angle"}/2)) * $self->{"length"}*0.9;
	my $startArcYPos = cos( deg2rad($self->{"angle"}/2)) * $self->{"length"}*0.9;
	
	my $endArcXPos = -1*$startArcXPos;
	my $endArcYPos = $startArcYPos;
 	
	my $arc = PrimitiveArcSCE->new(Point->new( $startArcXPos, $startArcYPos), Point->new( 0, 0), Point->new( $endArcXPos, $endArcYPos), $self->{"symbol"});
	$self->AddPrimitive($arc);
	
	 # Add left helper line
 
 
	my $leftLine = PrimitiveLine->new( Point->new( 0, 0),
										   Point->new( $leftLineXPos,$ leftLineYPos ),
										   $self->{"symbol"} );
	my $rightLine = $leftLine->Copy();
	$rightLine->MirrorY();

	$self->AddPrimitive($leftLine);
	$self->AddPrimitive($rightLine);

	#  Add text

 
	# add text value

	my $textPos = Point->new(0, $self->{"length"});

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

