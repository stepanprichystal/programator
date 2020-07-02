
#-------------------------------------------------------------------------------------------#
# Description: Table drawer which generates prepared InCAM layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::DrawingBuilders::InCAMDrawing::InCAMDrawing;

use Class::Interface;
&implements('Packages::Other::TableDrawing::IDrawingBuilder');

#3th party library
use strict;
use warnings;
use PDF::API2;

#local library
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'Packages::CAM::SymbolDrawing::Enums' => "DrawingEnums";
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePad';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfFill';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveSurfPoly';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitivePolyline';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveLine';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::PrimitiveText';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSolidPattern';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceSymbolPattern';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceLinePattern';
use aliased 'Packages::CAM::SymbolDrawing::Primitive::Helper::SurfaceCrossHatchPattern';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

use constant mm => 1;
use constant in => 1 / 72;
use constant um => 1 / 1000;

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}       = shift;    # InCAM library
	$self->{"jobId"}       = shift;
	$self->{"step"}        = shift;
	$self->{"outputLayer"} = shift;    # Set layer name for generating table

	$self->{"units"}      = shift;
	$self->{"canvasSize"} = shift;        #
	$self->{"margin"}     = shift // 0;

	$self->{"coord"} = TblDrawEnums->CoordSystem_LEFTBOT;

	if ( $self->{"units"} eq TblDrawEnums->Units_MM ) {
		$self->{"unitConv"} = mm;

	}
	elsif ( $self->{"units"} eq TblDrawEnums->Units_UM ) {
		$self->{"unitConv"} = um;
	}
	else {

		die;
	}

	$self->{"drawing"} = SymbolDrawing->new( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub GetUnits {
	my $self = shift;

	return $self->{"units"};

}

sub GetCoordSystem {
	my $self = shift;

	return $self->{"coord"};

}

sub GetCanvasSize {
	my $self = shift;
	my $considerMargin = shift // 1;

	my $w = $self->{"canvasSize"}->[0];
	my $h = $self->{"canvasSize"}->[1];

	$w -= 2 * $self->{"margin"} if ($considerMargin);
	$h -= 2 * $self->{"margin"} if ($considerMargin);

	return ( $w, $h );
}

sub GetCanvasMargin {
	my $self = shift;

	return $self->{"margin"};
}

sub Init {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Set step
	CamHelper->SetStep( $inCAM, $self->{"step"} );

	# Init PDF page
	if ( !CamHelper->LayerExists( $inCAM, $jobId, $self->{"outputLayer"} ) ) {

		CamMatrix->CreateLayer( $inCAM, $jobId, $self->{"outputLayer"}, "document", "positive", 0 );
	}

	$self->{"fonts"} = {
						 TblDrawEnums->FontFamily_STANDARD => "standard",
						  TblDrawEnums->FontFamily_ARIAL => "standard",
						 TblDrawEnums->FontFamily_TIMES    => "romans.shx",
	};
}

sub DrawRectangle {
	my $self       = shift;
	my $sX         = shift;
	my $sY         = shift;
	my $width      = shift;
	my $height     = shift;
	my $backgStyle = shift;

	my $surfPattern = undef;

	if ( $backgStyle->GetBackgStyle() eq TblDrawEnums->BackgStyle_SOLIDCLR ) {
		my $val = $backgStyle->GetBackgColor()->GetGrayScale();

		if ( $val < 50 ) {

			$surfPattern = SurfaceCrossHatchPattern->new( 0, 0, 45, 0, 50, 700 );

		}
		elsif ( $val < 100 ) {
			$surfPattern = SurfaceLinePattern->new( 0, 0, 45, 0, 50, 700 );

		}
		elsif ( $val < 150 ) {

			$surfPattern = SurfaceCrossHatchPattern->new( 0, 0, 0, 0, 50, 700 );
		}
		elsif ( $val < 200 ) {

			$surfPattern = SurfaceLinePattern->new( 0, 0, 135, 0, 50, 700 );
		}
		elsif ( $val < 254 ) {

			$surfPattern = SurfaceSymbolPattern->new( 1, 100, 0, "r50", 0.7, 0.7 );
		}
		else {
			 
		}
	}

	my @rectLim = ();
	push( @rectLim, Point->new( $sX / $self->{"unitConv"}, $sY / $self->{"unitConv"} ) );
	push( @rectLim, Point->new( ( $sX + $width ) / $self->{"unitConv"}, $sY / $self->{"unitConv"} ) );
	push( @rectLim, Point->new( ( $sX + $width ) / $self->{"unitConv"}, ( $sY + $height ) / $self->{"unitConv"} ) );
	push( @rectLim, Point->new( $sX / $self->{"unitConv"}, ( $sY + $height ) / $self->{"unitConv"} ) );
	push( @rectLim, Point->new( $sX / $self->{"unitConv"}, $sY / $self->{"unitConv"} ) );

	my $areaP = PrimitiveSurfPoly->new( \@rectLim, $surfPattern, DrawingEnums->Polar_POSITIVE );

	$self->{"drawing"}->AddPrimitive($areaP);

}

sub DrawSolidStroke {
	my $self        = shift;
	my $sX          = shift;
	my $sY          = shift;
	my $eX          = shift;
	my $eY          = shift;
	my $strokeWidth = shift;
	my $strokeColor = shift;

	my $line = PrimitiveLine->new(
								   Point->new( $sX / $self->{"unitConv"}, $sY / $self->{"unitConv"} ),
								   Point->new( $eX / $self->{"unitConv"}, $eY / $self->{"unitConv"} ),
								   "r" . ( $strokeWidth * 1000 / $self->{"unitConv"} ),
								   DrawingEnums->Polar_POSITIVE
	);

	$self->{"drawing"}->AddPrimitive($line);

}

sub DrawDashedStroke {
	my $self        = shift;
	my $sX          = shift;
	my $sY          = shift;
	my $eX          = shift;
	my $eY          = shift;
	my $strokeWidth = shift;
	my $strokeColor = shift;
	my $dashLen     = shift;
	my $gapLen      = shift;

	my $orient = undef;

	if ( $sX == $eX ) {

		$orient = "v";
	}
	elsif ( $sY == $eY ) {

		$orient = "h";
	}
	else {

		die "Dashed line is not horizontal or vertical";
	}

	my $x1 = $sX;
	my $y1 = $sY;
	my $x2 = $sX + ($orient eq "h" ? $dashLen : 0);
	my $y2 = $sY + ($orient eq "v" ? $dashLen : 0);
	
	while (1) {

		$self->DrawSolidStroke( $x1, $y1, $x2, $y2, $strokeWidth, $strokeColor );

		# move by dash len
		$x1 += $gapLen + $dashLen if ( $orient eq "h" );
		$y1 += $gapLen + $dashLen if ( $orient eq "v" );
		$x2 += $gapLen + $dashLen if ( $orient eq "h" );
		$y2 += $gapLen + $dashLen if ( $orient eq "v" );

		last if ( $orient eq "h" && $x2 > $eX );
		last if ( $orient eq "v" && $y2 > $eY );
	}
}

sub DrawTextLine {
	my $self           = shift;
	my $boxStartX      = shift;
	my $boxStartY      = shift;
	my $boxW           = shift;
	my $boxH           = shift;
	my $text           = shift;
	my $size           = shift;    # not scaled
	my $scaleX         = shift;
	my $scaleY         = shift;
	my $textClr        = shift;
	my $textFont       = shift;
	my $textFontFamily = shift;
	my $textVAlign     = shift;
	my $textHAlign     = shift;

	my $font = $self->{"fonts"}->{$textFontFamily};

	die "Text font is not defined. Font Family: ; Font: " unless ( defined $font );

	$size *= $scaleX;

	#	$txt->fillcolor( $textClr->GetHexCode() );
	#
	my $x = undef;
	my $y = undef;

	# Compute horizontal aligment
	$x = $boxStartX             if ( $textHAlign eq TblDrawEnums->TextHAlign_LEFT );
	$x = $boxStartX + $boxW / 2 if ( $textHAlign eq TblDrawEnums->TextHAlign_CENTER );
	$x = $boxStartX + $boxW     if ( $textHAlign eq TblDrawEnums->TextHAlign_RIGHT );

	# Compute vertical aligment
	$y = $boxStartY if ( $textVAlign eq TblDrawEnums->TextVAlign_BOT );
	$y = $boxStartY + ( $boxH - $size ) / 2 if ( $textVAlign eq TblDrawEnums->TextVAlign_CENTER );
	$y = $boxStartY + ( $boxH - $size )     if ( $textVAlign eq TblDrawEnums->TextVAlign_TOP );

	my $textWidth = $size * 1000 / 6.56;    # Compute regular size of text
	$textWidth *= 1.2 if ( $textFont eq TblDrawEnums->Font_BOLD );

	my $magicConstant = 0.00328;            # InCAM need text width converted with this constant , took keep required width in µm
	$textWidth *= $magicConstant;

	my $trackTextNeg = PrimitiveText->new( $text,
										   Point->new( $x / $self->{"unitConv"}, $y / $self->{"unitConv"} ),
										   $size / $self->{"unitConv"},
										   $size / $self->{"unitConv"},
										   $textWidth, 0, 0, DrawingEnums->Polar_POSITIVE );

	$self->{"drawing"}->AddPrimitive($trackTextNeg);

	#	$txt->translate( $x / $self->{"unitConv"}, $y / $self->{"unitConv"} );
	#
	#	$txt->text($text)        if ( $textHAlign eq TblDrawEnums->TextHAlign_LEFT );
	#	$txt->text_center($text) if ( $textHAlign eq TblDrawEnums->TextHAlign_CENTER );
	#	$txt->text_right($text)  if ( $textHAlign eq TblDrawEnums->TextHAlign_RIGHT );

}

sub DrawTextMultiLine {
	my $self           = shift;
	my $boxStartX      = shift;
	my $boxStartY      = shift;
	my $boxW           = shift;
	my $boxH           = shift;
	my $textLines      = shift;
	my $size           = shift;    # not scaled
	my $scaleX         = shift;
	my $scaleY         = shift;
	my $textClr        = shift;
	my $textFont       = shift;
	my $textFontFamily = shift;
	my $textVAlign     = shift;
	my $textHAlign     = shift;

 

	die "No text lines" unless ( scalar( @{$textLines} ) );

	my $lH = $boxH / scalar( @{$textLines} );

	my $curPos = $boxStartY;
	for ( my $i = 0 ; $i < scalar( @{$textLines} ) ; $i++ ) {

		$self->DrawTextLine( $boxStartX, $curPos,  $boxW,     $lH,             $textLines->[$i], $size, $scaleX,
							 $scaleY,    $textClr, $textFont, $textFontFamily, $textVAlign,      $textHAlign );
		$curPos += $lH;
	}

}

sub DrawTextParagraph {
	my $self           = shift;
	my $boxStartX      = shift;
	my $boxStartY      = shift;
	my $boxW           = shift;
	my $boxH           = shift;
	my $text           = shift;
	my $size           = shift;    # not scaled
	my $scaleX         = shift;
	my $scaleY         = shift;
	my $textClr        = shift;
	my $textFont       = shift;
	my $textFontFamily = shift;
	my $textVAlign     = shift;
	my $textHAlign     = shift;

	die "DrawTextParagraph is not implemented";

}

sub Finish {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	CamLayer->WorkLayer( $inCAM, $self->{"outputLayer"} );
	$self->{"drawing"}->Draw();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

