
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <LayerData> and operations with this items
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::OutputData::Drawing::Drawing;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceLinePattern';
use aliased 'Packages::Gerbers::OutputData::Enums';
use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimV1Lines';

use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimH1Lines';
use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimH1';
use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimV1';
use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimAngle1';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	$self->{"inCAM"}    = shift;
	$self->{"layer"}    = shift;
	$self->{"pcbThick"} = shift;    # pcbthick in mm
	$self->{"side"}     = shift;    # top/bot

	$self->{"scale"}            = 10;
	$self->{"drawWidth"}        = 200;
	$self->{"drawOutlineWidth"} = "500";
	$self->{"dimLineWidth"}     = "r200";
	$self->{"dimTextWidth"}     = "1";
	$self->{"dimTextHeight"}    = 4;

	$self->{"drawing"} = SymbolDrawing->new( $self->{"inCAM"} );

	return $self;
}

sub CreateDraw {
	my $self     = shift;
	my $pcbThick = shift;    # pcbthick in mm

	my $side       = shift;  # top/bot
	my $type       = shift;  # countersink z-axis
	my $symbolType = shift;  # slot/hole/surface
	my $diameter   = shift;
	my $depth      = shift;
	my $angle      = shift;

	my @surfPoints = ();

	$self->__CreatePcbDraw( \@surfPoints, $pcbThick );
	$self->__CreateDetailDraw( \@surfPoints, $type, $symbolType, $diameter, $depth, $angle );

	# 1) Add pcb surface primitive

	my $pcbSurf = PrimitiveSurfPoly->new( \@surfPoints, SurfaceLinePattern->new( 1, $self->{"drawOutlineWidth"}, 45, 0, 20, 2000 ) );
	$self->{"drawing"}->AddPrimitive($pcbSurf);

	# 2) Add pcb thick dimension

	my $w     = $self->{"drawWidth"};
	my $drawH = $pcbThick * $self->{"scale"};    # mm

	my $dimThick = DimV1->new( "bot", int( $w * 0.01 ),
							   $drawH,
							   int( $w * 0.2 ),
							   $self->{"dimLineWidth"},
							   $pcbThick . "mm (pcb thick)",
							   $self->{"dimTextHeight"},
							   $self->{"dimTextWidth"} );
	$self->{"drawing"}->AddSymbol( $dimThick, Point->new( int( $w * 0.9 ), 0 ) );

	# 4) draw picture to layer
	CamLayer->WorkLayer( $self->{"inCAM"}, $self->{"layer"} );
	$self->{"drawing"}->Draw();

}

# Measure is 1: 10, thus pcb thisk 1.5 mm will be draw as thicj 15mm
sub __GetPcbDrawSide {
	my $self       = shift;
	my $surfPoints = shift;
	my $side       = shift;

	my $drawW = $self->{"drawWidth"};                      # mm
	my $drawH = $self->{"pcbThick"} * $self->{"scale"};    # mm

	my $flashLen = int( $drawH / 3 );
	my $flashP1  = -$flashLen;
	my $flashP2  = -int( $flashLen + 1 * ( $flashLen / 3 ) );
	my $flashP3  = -int( $flashLen + 2 * ( $flashLen / 3 ) );
	my $flashP4  = -int( $flashLen + 3 * ( $flashLen / 3 ) );

	if ( $side eq "right" ) {
		push( @{$surfPoints}, Point->new( $drawW, 0 ) );    # top right corner

		# klikihak on the right side

		push(
			  @{$surfPoints},
			  (
				 Point->new( $drawW,     $flashP1 ),
				 Point->new( $drawW + 4, $flashP2 ),
				 Point->new( $drawW - 4, $flashP3 ),
				 Point->new( $drawW,     $flashP4 )
			  )
		);                                                  # right flash

		push( @{$surfPoints}, Point->new( $drawW, -$drawH ) );    # bot right corner

	}
	elsif ( $side eq "left" ) {

		push( @{$surfPoints}, Point->new( 0, -$drawH ) );         # bot left corner

		# klikihak on the left side

		push( @{$surfPoints},
			  ( Point->new( 0, $flashP4 ), Point->new( 0 + 4, $flashP3 ), Point->new( 0 - 4, $flashP2 ), Point->new( 0, $flashP1 ) ) );  # right flash

		push( @{$surfPoints}, Point->new( 0, 0 ) );    # top left corner
	}

}

sub __CreateDetailDraw {
	my $self       = shift;
	my $surfPoints = shift;
	my $type       = shift;
	my $symbolType = shift;                            # slot/hole/surface                             # countersink z-axis
	my $diameter   = shift;
	my $depth      = shift;
	my $angle      = shift;

	if ( $type eq Enums->Depth_ZAXIS ) {

		if ( $symbolType eq Enums->Symbol_SURFACE ) {

			$self->__CreateDetailZaxisSurf( $surfPoints, $depth );
		}
		else {

			$self->__CreateDetailZaxis( $surfPoints, $symbolType, $diameter, $depth );
		}

	}
	elsif ( $type eq Enums->Depth_COUNTERSINK ) {

		$self->__CreateDetailCountersink( $surfPoints, $symbolType, $diameter, $depth, $angle );
	}

}

sub __CreateDetailZaxis {
	my $self       = shift;
	my $surfPoints = shift;
	my $symbolType = shift;    # slot/hole/surface
	my $diameter   = shift;
	my $depth      = shift;

	# 1) Add right side of draw
	$self->__GetPcbDrawSide( $surfPoints, "right" );

	# 2) Add left side of draw
	$self->__GetPcbDrawSide( $surfPoints, "left" );

	# 3) create detail part of surface
	my $drawW        = $self->{"drawWidth"};
	my $diameterReal = $diameter * $self->{"scale"};
	my $depthReal    = $depth * $self->{"scale"};

	my $x1 = int( ( $drawW - $diameterReal ) / 2 );
	my $x2 = int( ( $drawW - $diameterReal ) / 2 + $diameterReal );

	push( @{$surfPoints}, Point->new( $x1, 0 ) );
	push( @{$surfPoints}, Point->new( $x1, -$depthReal ) );
	push( @{$surfPoints}, Point->new( $x2, -$depthReal ) );
	push( @{$surfPoints}, Point->new( $x2, 0 ) );

	# 4) create dimension draw for tool

	my $w = $self->{"drawWidth"};

	my $dimTool = DimH1Lines->new(
								   "top",                          "right",
								   int( $w * 0.1 ),                int( $w * 0.01 ),
								   $diameterReal,                  int( $w * 0.2 ),
								   "both",                         $self->{"dimLineWidth"},
								   "D " . $diameter . "mm (tool)", $self->{"dimTextHeight"},
								   $self->{"dimTextWidth"}
	);
	$self->{"drawing"}->AddSymbol( $dimTool, Point->new( $x1, 0 ) );

	# 5) create dimension draw for depth
	my $dimDepth = DimV1Lines->new(
									"left",                "bot",                    int( $w * 0.05 ), int( $w * 0.01 ),
									$depthReal,            int( $w * 0.2 ),          "both",           $self->{"dimLineWidth"},
									$depth . "mm (depth)", $self->{"dimTextHeight"}, $self->{"dimTextWidth"}
	);
	$self->{"drawing"}->AddSymbol( $dimDepth, Point->new( $x1, 0 ) );

}

sub __CreateDetailZaxisSurf {
	my $self       = shift;
	my $surfPoints = shift;
	my $depth      = shift;

	# 1) Add right side of draw
	$self->__GetPcbDrawSide( $surfPoints, "right" );

	# 2) Add left side of draw
	$self->__GetPcbDrawSide( $surfPoints, "left" );

	# 3) create detail part of surface
	my $drawW     = $self->{"drawWidth"};
	my $depthReal = $depth * $self->{"scale"};

	my @points = ();

	my $percent30 = int( $drawW / 3 );

	push( @{$surfPoints}, Point->new( $percent30,     0 ) );
	push( @{$surfPoints}, Point->new( $percent30,     -$depthReal ) );
	push( @{$surfPoints}, Point->new( 2 * $percent30, -$depthReal ) );
	push( @{$surfPoints}, Point->new( 2 * $percent30, 0 ) );

	# 4) create dimension draw for depth

	my $w = $self->{"drawWidth"};

	my $dimDepth = DimV1Lines->new(
									"left",                "bot",                    int( $w * 0.05 ), int( $w * 0.01 ),
									$depthReal,            int( $w * 0.2 ),          "both",           $self->{"dimLineWidth"},
									$depth . "mm (depth)", $self->{"dimTextHeight"}, $self->{"dimTextWidth"}
	);
	$self->{"drawing"}->AddSymbol( $dimDepth, Point->new( $percent30, 0 ) );

}

sub __CreateDetailCountersink {
	my $self       = shift;
	my $surfPoints = shift;
	my $symbolType = shift;    # slot/hole/surface
	my $diameter   = shift;
	my $depth      = shift;
	my $angle      = shift;

	# 1) create detail part of surface
	my @surfPointsDetail = ();

	my $drawW        = $self->{"drawWidth"};
	my $diameterReal = $diameter * $self->{"scale"};
	my $depthReal    = $depth * $self->{"scale"};

	my @points = ();

	my $x1 = int( ( $drawW - $diameterReal ) / 2 );
	my $x2 = int( $drawW / 2 );
	my $x3 = int( ( $drawW - $diameterReal ) / 2 + $diameterReal );

	push( @surfPointsDetail, Point->new( $x1, 0 ) );
	push( @surfPointsDetail, Point->new( $x2, -$depthReal ) );
	push( @surfPointsDetail, Point->new( $x3, 0 ) );

	# if depth of tool is smaller than pcb thick, do drawing from one surface
	if ( $depth < $self->{"pcbThick"} ) {

		# 1) Add right side of draw
		$self->__GetPcbDrawSide( $surfPoints, "right" );

		# 2) Add left side of draw
		$self->__GetPcbDrawSide( $surfPoints, "left" );

		push( @{$surfPoints}, @surfPointsDetail );
	}
	# do drawing rfom two separate surfaces
	else {
		
		# left survace		
		
		
	}

	# 2) create dimension draw for tool
	my $w = $self->{"drawWidth"};

	my $dimTool = DimH1Lines->new(
								   "bot",                   "left",                   int( $w * 0.15 ), int( $w * 0.01 ),
								   $diameterReal,           int( $w * 0.2 ),          "both",           $self->{"dimLineWidth"},
								   "D " . $diameter . "mm", $self->{"dimTextHeight"}, $self->{"dimTextWidth"}
	);
	$self->{"drawing"}->AddSymbol( $dimTool, Point->new( $x3, 0 ) );

	# 3) create dimension draw for depth
	my $dimDepth = DimV1Lines->new(
									"right",               "bot",                    abs( $x3 - $x2 ), int( $w * 0.01 ),
									$depthReal,            int( $w * 0.2 ),          "second",         $self->{"dimLineWidth"},
									$depth . "mm (depth)", $self->{"dimTextHeight"}, $self->{"dimTextWidth"}
	);
	$self->{"drawing"}->AddSymbol( $dimDepth, Point->new( $x2, 0 ) );

	# 4) create dimension draw for angle
	my $dimAngle =
	  DimAngle1->new( $angle, int( $w * 0.25 ), $self->{"dimLineWidth"}, $angle . " deg.", $self->{"dimTextHeight"}, $self->{"dimTextWidth"} );
	$self->{"drawing"}->AddSymbol( $dimAngle, Point->new( $x2, -$depthReal ) );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Gerbers::OutputData::Drawing::Drawing';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::Gerbers::OutputData::Enums';

	my $inCAM = InCAM->new();

	$inCAM->COM("sel_delete");

	my $draw = Drawing->new( $inCAM, "test" );

	#$draw->CreateDraw( 1.5, "top", Enums->Depth_ZAXIS, Enums->Symbol_SLOT, 2, 1 );
	#$draw->CreateDraw( 1.5, "top", Enums->Depth_ZAXIS, Enums->Symbol_SURFACE, 2, 1 );
	$draw->CreateDraw( 1.5, "top", Enums->Depth_COUNTERSINK, Enums->Symbol_SLOT, 2, 1, 90 );

}

1;

