
#-------------------------------------------------------------------------------------------#
# Description: Drawing special NC operation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::Drawing::Drawing;
use base('Packages::CAMJob::OutputData::Drawing::DrawingBase');

#3th party library
use strict;
use warnings;
use Math::Trig;
use Math::Geometry::Planar;

#local library

use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';

use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceLinePattern';
use aliased 'Packages::CAMJob::OutputData::Enums';
use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimV1Lines';

use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimH1Lines';
use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimH1';
use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimV1';
use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimAngle1';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $scale = 5;
	my $self = $class->SUPER::new( @_, $scale );
	bless $self;
	return $self;

	return $self;
}

sub CreateDetailZaxis {
	my $self   = shift;
	my $radius = shift;    # in mm
	my $depth  = shift;    # in mm
	my $type   = shift;    # slot/hole

	$self->_CreateDetailZaxis( $radius, $depth, $type );

	# 3) Add drawing title
	# ----------------------------------

	my $txt = "";

	if ( $type eq "hole" ) {

		$txt = "z-axis from " . uc( $self->{"side"} ) . " (hole)";

	}
	elsif ( $type eq "slot" ) {

		$txt = "z-axis from " . uc( $self->{"side"} ) . " (slot)";
	}

	$self->__AddTitleTexts($txt);

}

sub CreateDetailZaxisSurf {
	my $self  = shift;
	my $depth = shift;

	$self->_CreateDetailZaxisSurf($depth);

	# 3) Add drawing title
	# ----------------------------------

	my $txt = "z-axis from " . uc( $self->{"side"} );

	$self->__AddTitleTexts($txt);

}

sub CreateDetailCountersink {
	my $self       = shift;
	my $radius     = shift;    # in mm
	my $csDepth     = shift;   # depth of countersink in mm
	my $csHeadDepth = shift;   # depth of countersink head if exists in mm
	my $angle      = shift;    #
	my $type       = shift;    # slot/hole
	my $toolRadius = shift;	 	

	$self->_CreateDetailCountersink( $radius, $csDepth, $csHeadDepth,  $angle, $type );

	my $txt = "";

	if ( $type eq "hole" ) {

		$txt = "countersink from " . uc( $self->{"side"} );

	}
	elsif ( $type eq "slot" ) {

		$txt = "chamfer from " . uc( $self->{"side"} );
	}

	$self->__AddTitleTexts($txt);

}

sub __AddTitleTexts {
	my $self = shift;
	my $text = shift;          # countersink z-axis

	my $title = "";

	if ( $self->{"plated"} ) {
		$title .= "Plated ";
	}
	else {
		$title .= "Non plated ";
	}

	$title .= $text;

	$self->{"drawingTitle"}->AddPrimitive( PrimitiveText->new( $title, Point->new(), $self->{"titleTextHeight"}, $self->{"titleTextLineWidth"} ) );

	$self->{"drawingTitle"}
	  ->AddPrimitive( PrimitiveLine->new( Point->new( 0, -2 ), Point->new( length($title) * $self->{"titleTextHeight"}, -2 ), "r300" ) );
	$self->{"drawingTitle"}
	  ->AddPrimitive( PrimitiveLine->new( Point->new( 0, -3 ), Point->new( length($title) * $self->{"titleTextHeight"}, -3 ), "r300" ) );

	$self->{"drawingTitle"}->AddPrimitive( PrimitiveText->new( "(1:" . $self->{"scale"} . ")", Point->new( 0, -10 ), 4, 1 ) );

	if ( $self->{"plated"} ) {
		$self->{"drawingTitle"}->AddPrimitive( PrimitiveText->new( "Note: All measures are after plating", Point->new( 25, -8 ), 2, 1 ) );
	}

	$self->{"drawingTitle"}->Draw();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Gerbers::OutputData::Drawing::Drawing';
	#	use aliased 'Packages::InCAM::InCAM';
	#	use aliased 'Packages::Gerbers::OutputData::Enums';
	#	use aliased 'Packages::CAM::SymbolDrawing::Point';
	#
	#	my $inCAM = InCAM->new();
	#
	#	$inCAM->COM("sel_delete");
	#
	#	my $draw = Drawing->new( $inCAM, "test", Point->new( 20, 40 ), 1.5, "bot" );
	#
	#	#$draw->Create( Enums->Depth_ZAXIS, Enums->Symbol_SLOT, 2, 1 );
	#	$draw->Create( Enums->Depth_ZAXIS, Enums->Symbol_SURFACE, 2, 1 );
	#
	#	#$draw->Create( Enums->Depth_COUNTERSINK, Enums->Symbol_SLOT, 4, 3, 60 );

}

1;

