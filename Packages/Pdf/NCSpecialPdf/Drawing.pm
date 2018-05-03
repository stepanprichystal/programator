
#-------------------------------------------------------------------------------------------#
# Description: Drawing special NC operation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::NCSpecialPDF::Drawing;
use base('Packages::CAMJob::OutputData::Drawing::Drawing');

#3th party libraryPackages::Pdf::
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

	my $self = $class->SUPER::new(@_);
	bless $self;
	return $self;
 

	return $self;
}

# Cuntersink with drilled hole
sub CreateDetailCountersinkDrilled {
	my $self       = shift;
	my $radius     = shift;    # in mm
	my $radiusHole = shift;    # in mm
	my $csDepth     = shift;   # depth of countersink in mm
	my $csHeadDepth = shift;   # depth of countersink head if exists in mm
	my $angle      = shift;    #
	my $type       = shift;    # slot/hole

 
	$self->_CreateDetailCountersinkDrilled($radius, $radiusHole, $csDepth,$csHeadDepth, $angle, $type);

	 

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

