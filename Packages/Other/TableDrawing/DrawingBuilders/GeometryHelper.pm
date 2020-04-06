#-------------------------------------------------------------------------------------------#
# Description: Helper module for InCAM Drill tool manager
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Other::TableDrawing::DrawingBuilders::GeometryHelper;

#3th party library
use strict;
use warnings;

#loading of locale modules
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums';
use aliased 'Packages::Other::TableDrawing::Enums' => 'EnumsDraw';
#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub ScaleDrawingInCanvasSize {
	my $self        = shift;
	my $tblDrawing  = shift;
	my $drawBuilder = shift;
	my $keepRatio = shift // 1;

	my ( $canvasW, $canvasH ) = $drawBuilder->GetCanvasSize(1);

	my %lim = $tblDrawing->GetOriLimits();

	my $scaleX = 1;
	my $scaleY = 1;

	if ( $canvasW < ( $lim{"xMax"} - $lim{"xMin"} ) ) {
		$scaleX = $canvasW / ( $lim{"xMax"} - $lim{"xMin"} );
		$scaleY = $scaleX if($keepRatio);    # keep original ratio
	}

	if ( $canvasH < ( $lim{"yMax"} - $lim{"yMin"} ) * $scaleY ) {

		$scaleY = $canvasH / ( $lim{"yMax"} - $lim{"yMin"} * $scaleY );
		$scaleX = $scaleY if($keepRatio);;
	}

	return ( $scaleX, $scaleY );
}

sub HAlignDrawingInCanvasSize {
	my $self        = shift;
	my $tblDrawing  = shift;
	my $drawBuilder = shift;
	my $align       = shift;    #HAlign_TOP/HAlign_MIDDLE/HVAlign_BOT
	my $scaleX      = shift;
	my $scaleY      = shift;


	my ( $canvasW, $canvasH ) = $drawBuilder->GetCanvasSize();
	my %lim = $tblDrawing->GetScaleLimits( $scaleX, $scaleY );

	my $offsetX = 0;            # left align

	if ( $align eq Enums->HAlign_MIDDLE ) {

		$offsetX = ( $canvasW - ( $lim{"xMax"} - $lim{"xMin"} ) ) / 2;

	}
	elsif ( $align eq Enums->HAlign_RIGHT ) {

		$offsetX = ( $canvasW - ( $lim{"xMax"} - $lim{"xMin"} ) );
	}

	return $offsetX;
}

sub VAlignDrawingInCanvasSize {
	my $self        = shift;
	my $tblDrawing  = shift;
	my $drawBuilder = shift;
	my $align       = shift;    #VAlign_TOP/VAlign_MIDDLE/VAlign_BOT
	my $scaleX      = shift;
	my $scaleY      = shift;


	my ( $canvasW, $canvasH ) = $drawBuilder->GetCanvasSize();
	my %lim = $tblDrawing->GetScaleLimits( $scaleX, $scaleY );

	my $offsetY = 0;

	if ( $drawBuilder->GetCoordSystem() eq EnumsDraw->CoordSystem_LEFTTOP ) {

		# if TOP align, offsetY = 0, because tblDrawing has coodrdinate system Enums->CoordSystem_LEFTTOP and starts in zero

		if ( $align eq Enums->VAlign_MIDDLE ) {
			$offsetY = ( $canvasH - ( $lim{"yMax"} - $lim{"yMin"} ) ) / 2;

		}
		elsif ( $align eq Enums->VAlign_BOT ) {
			$offsetY = ( $canvasH - ( $lim{"yMax"} - $lim{"yMin"} ) );
		}

	}
	elsif ( $drawBuilder->GetCoordSystem() eq EnumsDraw->CoordSystem_LEFTBOT ) {

		# if BOT align, offsetY = 0, because tblDrawing has coodrdinate system Enums->CoordSystem_LEFTTOP and starts in zero

		if ( $align eq Enums->VAlign_TOP ) {
			$offsetY = ( $canvasH - ( $lim{"yMax"} - $lim{"yMin"} ) );
		}
		elsif ( $align eq Enums->VAlign_MIDDLE ) {
			$offsetY = ( $canvasH - ( $lim{"yMax"} - $lim{"yMin"} ) ) / 2;

		}
	}

	return $offsetY;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
