
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package  Packages::Other::TableDrawing::IDrawingBuilder;

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

use Class::Interface;
&interface;

sub GetUnits;

sub GetCoordSystem;

sub GetCanvasSize;

sub GetCanvasMargin;

sub Init;

sub DrawRectangle;

sub DrawTextLine;

sub DrawTextParagraph;

sub DrawSolidStroke;

sub DrawDashedStroke;

sub Finish;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

