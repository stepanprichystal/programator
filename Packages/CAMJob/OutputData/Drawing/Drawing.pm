
#-------------------------------------------------------------------------------------------#
# Description: Special structure responsible for draw
# technical image about depth drilling/routing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::Drawing::Drawing;

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
	my $self = shift;
	$self = {};
	bless $self;
	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"layer"}    = shift;    # layer where drawing is placed
	$self->{"position"} = shift;    # top/bot
	$self->{"pcbThick"} = shift;    # pcbthick in mm
	$self->{"side"}     = shift;    # top/bot
	$self->{"plated"}   = shift;    # 1/0

	$self->{"scale"}            = 5;
	$self->{"drawWidth"}        = 120;
	$self->{"drawOutlineWidth"} = "400";
	$self->{"dimLineWidth"}     = "r150";
	$self->{"dimTextWidth"}     = "0.8";
	$self->{"dimTextHeight"}    = 2.8;
	$self->{"dimTextMirror"}    = 0;
	$self->{"dimTextAngle"}     = 0;

	# title settings
	$self->{"titleTextHeight"}    = 3;
	$self->{"titleTextLineWidth"} = 1.5;
	$self->{"titlePosition"}      = $self->{"position"}->Copy();
	$self->{"titlePosition"}->Move( 0, 45 );

	# mirror all texts in drawing,
	if ( $self->{"side"} eq "bot" ) {

		$self->{"dimTextMirror"} = 1;
		$self->{"position"}->Move( 0, -$self->{"pcbThick"} * $self->{"scale"} );
	}

	$self->{"drawing"}      = SymbolDrawing->new( $self->{"inCAM"}, $self->{"jobId"},  $self->{"position"} );
	$self->{"drawingTitle"} = SymbolDrawing->new( $self->{"inCAM"},$self->{"jobId"},  $self->{"titlePosition"} );

	# mirror drawing
	if ( $self->{"side"} eq "bot" ) {

		$self->{"drawing"}->SetMirrorX();

	}

	return $self;
}

sub Create {
	my $self = shift;

	my $type       = shift;    # countersink z-axis
	my $symbolType = shift;    # slot/hole/surface
	my $diameter   = shift;
	my $depth      = shift;
	my $angle      = shift;

	$self->__CreateDraw( $type, $symbolType, $diameter, $depth, $angle );
	$self->__CreateTexts( $type, $symbolType );
}

sub __CreateDraw {
	my $self = shift;

	my $type       = shift;    # countersink z-axis
	my $symbolType = shift;    # slot/hole/surface
	my $diameter   = shift;
	my $depth      = shift;
	my $angle      = shift;

	# 1) Add pcb surface primitive
	$self->__CreateDetailDraw( $type, $symbolType, $diameter, $depth, $angle );

	# 2) Add pcb thick dimension

	my $w     = $self->{"drawWidth"};
	my $drawH = $self->{"pcbThick"} * $self->{"scale"};    # mm

	my $dimThick = DimV1->new( "bot", ( $w * 0.01 ),
							   $drawH,
							   ( $w * 0.2 ),
							   $self->{"dimLineWidth"},
							   sprintf( "%.2f", $self->{"pcbThick"} ) . "mm (pcb thick)",
							   $self->{"dimTextHeight"},
							   $self->{"dimTextWidth"},
							   $self->{"dimTextMirror"},
							   $self->{"dimTextAngle"} );
	$self->{"drawing"}->AddSymbol( $dimThick, Point->new( ( $w * 0.9 ), 0 ) );

	# 3) draw picture to layer
	CamLayer->WorkLayer( $self->{"inCAM"}, $self->{"layer"} );
	$self->{"drawing"}->Draw();

}

sub __CreateTexts {
	my $self       = shift;
	my $type       = shift;    # countersink z-axis
	my $symbolType = shift;    # slot/hole/surface

	my $title = "";

	if ( $self->{"plated"} ) {
		$title .= "Plated ";
	}
	else {
		$title .= "Non plated ";
	}

	if ( $type eq Enums->Depth_ZAXIS ) {

		$title .= "Z-axis milling from " . uc( $self->{"side"} ) . ". Type - ";
	}
	elsif ( $type eq Enums->Depth_COUNTERSINK ) {

		$title .= "Countersink from " . uc( $self->{"side"} ) . ". Type - ";
	}

	if ( $symbolType eq Enums->Symbol_SLOT ) {
		$title .= "slot";
	}
	elsif ( $symbolType eq Enums->Symbol_HOLE ) {
		$title .= "hole";
	}
	elsif ( $symbolType eq Enums->Symbol_SURFACE ) {
		$title .= "surface";
	}

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

# Measure is 1: 10, thus pcb thisk 1.5 mm will be draw as thicj 15mm
sub __GetPcbDrawSide {
	my $self       = shift;
	my $surfPoints = shift;
	my $side       = shift;

	my $drawW = $self->{"drawWidth"};                      # mm
	my $drawH = $self->{"pcbThick"} * $self->{"scale"};    # mm

	my $flashLen = $drawH / 3;
	my $flashP1  = -$flashLen;
	my $flashP2  = -( $flashLen + 1 * ( $flashLen / 3 ) );
	my $flashP3  = -( $flashLen + 2 * ( $flashLen / 3 ) );
	my $flashP4  = -( $flashLen + 3 * ( $flashLen / 3 ) );

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
	my $type       = shift;
	my $symbolType = shift;                            # slot/hole/surface                             # countersink z-axis
	my $diameter   = shift;
	my $depth      = shift;
	my $angle      = shift;

	if ( $type eq Enums->Depth_ZAXIS ) {

		if ( $symbolType eq Enums->Symbol_SURFACE ) {

			$self->__CreateDetailZaxisSurf($depth);
		}
		else {

			$self->__CreateDetailZaxis( $symbolType, $diameter, $depth );
		}

	}
	elsif ( $type eq Enums->Depth_COUNTERSINK ) {

		$self->__CreateDetailCountersink( $symbolType, $depth, $angle );
	}

}

sub __AddDetailDraw {
	my $self       = shift;
	my $surfPoints = shift;

	my $pcbSurf = PrimitiveSurfPoly->new( $surfPoints, SurfaceLinePattern->new( 1, $self->{"drawOutlineWidth"}, 45, 0, 20, 1500 ) );
	$self->{"drawing"}->AddPrimitive($pcbSurf);

}

sub __CreateDetailZaxis {
	my $self       = shift;
	my $symbolType = shift;    # slot/hole/surface
	my $diameter   = shift;
	my $depth      = shift;

	if ( $depth >= $self->{"pcbThick"} ) {
		die "Tool depth $depth is bigger than pcb thick " . $self->{"pcbThick"} . ".\n"; 
		#return 0;
	}

	my @surfPoints = ();

	# 1) Add right side of draw
	$self->__GetPcbDrawSide( \@surfPoints, "right" );

	# 2) Add left side of draw
	$self->__GetPcbDrawSide( \@surfPoints, "left" );

	# 3) create detail part of surface
	my $drawW        = $self->{"drawWidth"};
	my $diameterReal = $diameter * $self->{"scale"};
	my $depthReal    = $depth * $self->{"scale"};

	my $x1 = ( ( $drawW - $diameterReal ) / 2 );
	my $x2 = ( ( $drawW - $diameterReal ) / 2 + $diameterReal );

	push( @surfPoints, Point->new( $x1, 0 ) );
	push( @surfPoints, Point->new( $x1, -$depthReal ) );
	push( @surfPoints, Point->new( $x2, -$depthReal ) );
	push( @surfPoints, Point->new( $x2, 0 ) );

	$self->__AddDetailDraw( \@surfPoints );

	# 4) create dimension draw for tool

	my $w = $self->{"drawWidth"};

	my $dimTool = DimH1Lines->new(
								   "top", "right",
								   ( $w * 0.1 ), ( $w * 0.01 ),
								   $diameterReal, ( $w * 0.2 ),
								   "both",                         $self->{"dimLineWidth"},
								   "D " . $diameter . "mm (tool)", $self->{"dimTextHeight"},
								   $self->{"dimTextWidth"},        $self->{"dimTextMirror"},
								   $self->{"dimTextAngle"}
	);
	$self->{"drawing"}->AddSymbol( $dimTool, Point->new( $x1, 0 ) );

	# 5) create dimension draw for depth
	my $dimDepth = DimV1Lines->new(
									"left", "bot",
									( $w * 0.05 ), ( $w * 0.01 ),
									$depthReal, ( $w * 0.2 ),
									"both", $self->{"dimLineWidth"},
									sprintf( "%.2f", $depth ) . "mm (depth)", $self->{"dimTextHeight"},
									$self->{"dimTextWidth"}, $self->{"dimTextMirror"},
									$self->{"dimTextAngle"}
	);
	$self->{"drawing"}->AddSymbol( $dimDepth, Point->new( $x1, 0 ) );

}

sub __CreateDetailZaxisSurf {
	my $self  = shift;
	my $depth = shift;

	if ( $depth >= $self->{"pcbThick"} ) {
		die "Tool depth $depth is bigger than pcb thick " . $self->{"pcbThick"} . ".\n";
		#return 0;
	}

	my @surfPoints = ();

	# 1) Add right side of draw
	$self->__GetPcbDrawSide( \@surfPoints, "right" );

	# 2) Add left side of draw
	$self->__GetPcbDrawSide( \@surfPoints, "left" );

	# 3) create detail part of surface
	my $drawW     = $self->{"drawWidth"};
	my $depthReal = $depth * $self->{"scale"};

	my @points = ();

	my $percent30 = int( $drawW / 3 );

	push( @surfPoints, Point->new( $percent30,     0 ) );
	push( @surfPoints, Point->new( $percent30,     -$depthReal ) );
	push( @surfPoints, Point->new( 2 * $percent30, -$depthReal ) );
	push( @surfPoints, Point->new( 2 * $percent30, 0 ) );

	$self->__AddDetailDraw( \@surfPoints );

	# 4) create dimension draw for depth

	my $w = $self->{"drawWidth"};

	my $dimDepth = DimV1Lines->new(
									"left", "bot",
									( $w * 0.05 ), ( $w * 0.01 ),
									$depthReal, ( $w * 0.2 ),
									"both", $self->{"dimLineWidth"},
									sprintf( "%.2f", $depth ) . "mm (depth)", $self->{"dimTextHeight"},
									$self->{"dimTextWidth"}, $self->{"dimTextMirror"},
									$self->{"dimTextAngle"}
	);
	$self->{"drawing"}->AddSymbol( $dimDepth, Point->new( $percent30, 0 ) );

}

sub __CreateDetailCountersink {
	my $self       = shift;
	my $symbolType = shift;    # slot/hole/surface

	my $depth = shift;
	my $angle = shift;

	# compute diameter of tool by angle and depth
	my $diameter = tan( deg2rad( $angle / 2 ) ) * $depth * 2;

	# 1) create detail part of surface

	my $drawW        = $self->{"drawWidth"};
	my $drawH        = $self->{"pcbThick"} * $self->{"scale"};    # mm
	my $diameterReal = $diameter * $self->{"scale"};
	my $depthReal    = $depth * $self->{"scale"};

	my @points = ();

	my $x1 = ( $drawW - $diameterReal ) / 2;
	my $x2 = $drawW / 2;
	my $x3 = ( $drawW - $diameterReal ) / 2 + $diameterReal;

	# if depth of tool is smaller than pcb thick, do drawing from one surface
	if ( $depth < $self->{"pcbThick"} ) {

		my @surfPoints = ();

		# 1) Add right side of draw
		$self->__GetPcbDrawSide( \@surfPoints, "right" );

		# 2) Add left side of draw
		$self->__GetPcbDrawSide( \@surfPoints, "left" );

		push( @surfPoints, Point->new( $x1, 0 ) );
		push( @surfPoints, Point->new( $x2, -$depthReal ) );
		push( @surfPoints, Point->new( $x3, 0 ) );

		$self->__AddDetailDraw( \@surfPoints );
	}

	# do drawing rfom two separate surfaces
	else {

		my $xTmp = $drawH / tan( deg2rad( 90 - ( $angle / 2 ) ) );

		# left survace
		my @surfPoints1 = ();

		push( @surfPoints1, Point->new( $x1, 0 ) );

		push( @surfPoints1, Point->new( $xTmp + $x1, -$drawH ) );

		$self->__GetPcbDrawSide( \@surfPoints1, "left" );
		$self->__AddDetailDraw( \@surfPoints1 );

		# right surface
		my @surfPoints2 = ();

		$self->__GetPcbDrawSide( \@surfPoints2, "right" );

		push( @surfPoints2, Point->new( $x3 - $xTmp, -$drawH ) );

		push( @surfPoints2, Point->new( $x3, 0 ) );
		$self->__AddDetailDraw( \@surfPoints2 );

	}

	# 2) create dimension draw for tool
	my $w = $self->{"drawWidth"};

	my $dimTool = DimH1Lines->new(
								   "bot", "left",
								   ( $w * 0.2 ), ( $w * 0.01 ),
								   $diameterReal, ( $w * 0.2 ),
								   "both", $self->{"dimLineWidth"},
								   "D " . sprintf( "%.2f", $diameter ) . "mm", $self->{"dimTextHeight"},
								   $self->{"dimTextWidth"}, $self->{"dimTextMirror"},
								   $self->{"dimTextAngle"}
	);
	$self->{"drawing"}->AddSymbol( $dimTool, Point->new( $x3, 0 ) );

	# 3) create dimension draw for depth
	my $dimDepth = DimV1Lines->new(
									"right", "bot",
									abs( $x3 - $x2 ), ( $w * 0.01 ),
									$depthReal, ( $w * 0.2 ),
									"second", $self->{"dimLineWidth"},
									sprintf( "%.2f", $depth ) . "mm (depth)", $self->{"dimTextHeight"},
									$self->{"dimTextWidth"}, $self->{"dimTextMirror"},
									$self->{"dimTextAngle"}
	);
	$self->{"drawing"}->AddSymbol( $dimDepth, Point->new( $x2, 0 ) );

	# 4) create dimension draw for angle
	my $dimAngle = DimAngle1->new( $angle,
								   int( $w * 0.20 ),
								   $self->{"dimLineWidth"},
								   $angle . " deg.",
								   $self->{"dimTextHeight"},
								   $self->{"dimTextWidth"},
								   $self->{"dimTextMirror"},
								   $self->{"dimTextAngle"} );
	$self->{"drawing"}->AddSymbol( $dimAngle, Point->new( $x2, -$depthReal ) );

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

