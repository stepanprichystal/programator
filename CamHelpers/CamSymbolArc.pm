#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with arc symbols
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamSymbolArc;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub AddArcStartCenterEnd {
	my $self     = shift;
	my $inCAM    = shift;
	my $startP   = shift;
	my $centerP  = shift;
	my $endP     = shift;
	my $direction     = shift;
	my $symbol   = shift;    #hash x, y
	my $polarity = shift;    #

	$polarity = defined $polarity ? $polarity : 'positive';
	$direction = defined $direction ? $direction : 'cw';

	$inCAM->COM(
		"add_arc",
		"symbol"     => $symbol,
		"polarity"   => $polarity,
		"attributes" => "no",
		"direction"  => $direction,
		"xs"         => $startP->{"x"},
		"ys"         => $startP->{"y"},
		"xe"         => $endP->{"x"},
		"ye"         => $endP->{"y"},
		"xc"         => $centerP->{"x"},
		"yc"         => $centerP->{"y"}
	);

}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
#	use aliased 'CamHelpers::CamSymbolSurf';
#	use aliased 'Packages::InCAM::InCAM';
#
#	my $jobName   = "f13608";
#	my $layerName = "c";
#
#	my $inCAM = InCAM->new();
#
#	$inCAM->COM("sel_delete");
#
#	 
#
#	my @points = ();
#	my %point1 = ( "x" => 0, "y" => 0 );
#	my %point2 = ( "x" => 100, "y" => 0 );
#	my %point3 = ( "x" => 100, "y" => 100 );
#	my %point4 = ( "x" => 0, "y" => 100 );
#
#	 
#
#	CamSymbolSurf->AddSurfaceLinePattern( $inCAM, 1, 100, undef, 45, 50, 1000 );
#
#	CamSymbolSurf->AddSurfacePolyline( $inCAM, \@points, 1 )

}

 

1;