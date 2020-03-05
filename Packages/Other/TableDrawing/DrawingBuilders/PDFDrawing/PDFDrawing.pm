
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for one layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::TableDrawing::DrawingBuilders::PDFDrawing::PDFDrawing;

#use base('Packages::Export::NifExport::NifBuilders::NifBuilderBase');

use Class::Interface;
&implements('Packages::Other::TableDrawing::IDrawingBuilder');

#3th party library
use strict;
use warnings;
use PDF::API2;

#local library
use aliased 'Packages::Other::TableDrawing::Enums' => 'EnumsDraw';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"units"}      = shift;
	$self->{"mediaSize"}  = shift;
	$self->{"margin"}     = shift // 0;
	$self->{"outputPath"} = shift;

	$self->{"coord"} = EnumsDraw->CoordSystem_LEFTBOT;

	if ( $self->{"units"} eq EnumsDraw->Units_MM ) {
		$self->{"unitConv"} = mm;
	}
	else {

		die;
	}

	$self->{"pdf"} = undef;
	$self->{"counter"} = 1;

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

	my $w = $self->{"mediaSize"}->[0];
	my $h = $self->{"mediaSize"}->[1];

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

	die "PDF file already exists" if ( -e $self->{"outputPath"} );

	$self->{"pdf"} = PDF::API2->new( -file => $self->{"outputPath"} );

	# Init some fonts

	$self->{"fonts"} = {
						 EnumsDraw->FontFamily_ARIAL => {
														  EnumsDraw->Font_BOLD   => $self->{"pdf"}->corefont( 'Arial-Bold',   -encoding => 'latin1' ),
														  EnumsDraw->Font_NORMAL => $self->{"pdf"}->corefont( 'Arial',        -encoding => 'latin1' ),
														  EnumsDraw->Font_ITALIC => $self->{"pdf"}->corefont( 'Arial-Italic', -encoding => 'latin1' ),
						 },
						 EnumsDraw->FontFamily_TIMES => {
														  EnumsDraw->Font_BOLD   => $self->{"pdf"}->corefont( 'Times-Bold',   -encoding => 'latin1' ),
														  EnumsDraw->Font_NORMAL => $self->{"pdf"}->corefont( 'Times',        -encoding => 'latin1' ),
														  EnumsDraw->Font_ITALIC => $self->{"pdf"}->corefont( 'Times-Italic', -encoding => 'latin1' ),
						 },
	};

	$self->{"page"} = $self->{"pdf"}->page();
	$self->{"page"}->mediabox( $self->{"mediaSize"}->[0] / $self->{"unitConv"}, $self->{"mediaSize"}->[1] / $self->{"unitConv"} );

	#$self->{"page"}->bleedbox( $self->{"mediaSize"}->[0] / $self->{"unitConv"}, $self->{"mediaSize"}->[1] / $self->{"unitConv"} );
	#$self->{"page"}->cropbox( $self->{"mediaSize"}->[0] / $self->{"unitConv"}, $self->{"mediaSize"}->[1] / $self->{"unitConv"} );
	#$self->{"page"}->artbox( $self->{"mediaSize"}->[0] / $self->{"unitConv"}, $self->{"mediaSize"}->[1] / $self->{"unitConv"} );

}

sub DrawRectangle {
	my $self       = shift;
	my $sX         = shift;
	my $sY         = shift;
	my $width      = shift;
	my $height     = shift;
	my $backgStyle = shift;


	my $box = $self->{"page"}->gfx();    # Render first (text is rendered on top of it)

	$self->{"counter"}++;
	if ( $backgStyle->GetBackgStyle() eq EnumsDraw->BackgStyle_SOLIDCLR ) {
		my $clr = $backgStyle->GetBackgColor()->GetHexCode();
		$box->fillcolor($clr);

		#$box->fillcolor('#0000ff');
	}

	$box->rect( $sX / $self->{"unitConv"}, $sY / $self->{"unitConv"}, $width / $self->{"unitConv"}, $height / $self->{"unitConv"} );

	$box->fill();

}

sub DrawSolidStroke {
	my $self        = shift;
	my $sX          = shift;
	my $sY          = shift;
	my $eX          = shift;
	my $eY          = shift;
	my $strokeWidth = shift;
	my $strokeColor = shift;
	my $dashLen     = shift;
	my $gapLen      = shift;

	my $stroke = $self->{"page"}->gfx;

	my $clr = $strokeColor->GetHexCode();

	$stroke->strokecolor($clr);
	$stroke->move( $sX / $self->{"unitConv"}, $sY / $self->{"unitConv"} );
	$stroke->linewidth( $strokeWidth / $self->{"unitConv"} );
	$stroke->line( $eX / $self->{"unitConv"}, $eY / $self->{"unitConv"} );
	$stroke->stroke;

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

	my $stroke = $self->{"page"}->gfx;

	my $clr = $strokeColor->GetHexCode();

	$stroke->strokecolor($clr);
	$stroke->move( $sX / $self->{"unitConv"}, $sY / $self->{"unitConv"} );
	$stroke->linewidth( $strokeWidth / $self->{"unitConv"} );
	$stroke->linedash( $dashLen / $self->{"unitConv"}, $gapLen / $self->{"unitConv"} );
	$stroke->line( $eX / $self->{"unitConv"}, $eY / $self->{"unitConv"} );
	$stroke->stroke;

	$stroke->linedash();
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

	my $txt     = $self->{"page"}->text;
	my $pdfFont = $self->{"fonts"}->{$textFontFamily}{$textFont};

	die "Text font is not defined. Font Family: ; Font: " unless ( defined $pdfFont );

	$size *= $scaleX;

	$txt->font( $pdfFont, $size / $self->{"unitConv"} );

	$txt->fillcolor( $textClr->GetHexCode() );

	my $x = undef;
	my $y = undef;

	# Compute horizontal aligment
	$x = $boxStartX             if ( $textHAlign eq EnumsDraw->TextHAlign_LEFT );
	$x = $boxStartX + $boxW / 2 if ( $textHAlign eq EnumsDraw->TextHAlign_CENTER );
	$x = $boxStartX + $boxW     if ( $textHAlign eq EnumsDraw->TextHAlign_RIGHT );

	# Compute vertical aligment
	$y = $boxStartY if ( $textVAlign eq EnumsDraw->TextVAlign_BOT );
	$y = $boxStartY + ( $boxH - $size ) / 2 if ( $textVAlign eq EnumsDraw->TextVAlign_CENTER );
	$y = $boxStartY + ( $boxH - $size )     if ( $textVAlign eq EnumsDraw->TextVAlign_TOP );

	$txt->translate( $x / $self->{"unitConv"}, $y / $self->{"unitConv"} );

	$txt->text($text)        if ( $textHAlign eq EnumsDraw->TextHAlign_LEFT );
	$txt->text_center($text) if ( $textHAlign eq EnumsDraw->TextHAlign_CENTER );
	$txt->text_right($text)  if ( $textHAlign eq EnumsDraw->TextHAlign_RIGHT );

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

	my $txt = $self->{"page"}->text;
	$txt->textstart;
	my $pdfFont = $self->{"fonts"}->{$textFontFamily}{$textFont};

	die "Text font is not defined. Font Family: ; Font: " unless ( defined $pdfFont );

	$size *= $scaleX;

	my $x = undef;
	my $y = undef;

	# Compute horizontal aligment
	$x = $boxStartX;

	# Compute vertical aligment
	$y = $boxStartY;

	$txt->textstart;

	$txt->lead( $size / $self->{"unitConv"} );
	$txt->font( $pdfFont, $size / $self->{"unitConv"} );
	$txt->fillcolor( $textClr->GetHexCode() );
	$txt->translate( $x / $self->{"unitConv"}, ( $y + $boxH ) / $self->{"unitConv"} );
	$txt->paragraph( $text, $boxW / $self->{"unitConv"}, $boxH / $self->{"unitConv"} );

}

sub Finish {
	my $self = shift;
	$self->{"pdf"}->save();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

