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
	my $self      = shift;
	my $inCAM     = shift;
	my $startP    = shift;
	my $centerP   = shift;
	my $endP      = shift;
	my $direction = shift;
	my $symbol    = shift;    #hash x, y
	my $polarity  = shift;    #

	$polarity  = defined $polarity  ? $polarity  : 'positive';
	$direction = defined $direction ? $direction : 'cw';

	return
	  $inCAM->COM(
				   "add_arc",
				   "symbol"     => $symbol,
				   "polarity"   => $polarity,
				   "attributes" => "yes",
				   "direction"  => $direction,
				   "xs"         => $startP->{"x"},
				   "ys"         => $startP->{"y"},
				   "xe"         => $endP->{"x"},
				   "ye"         => $endP->{"y"},
				   "xc"         => $centerP->{"x"},
				   "yc"         => $centerP->{"y"}
	  );

}

sub AddArcStartCenterEnd {
	my $self      = shift;
	my $inCAM     = shift;
	my $startP    = shift;
	my $centerP   = shift;
	my $endP      = shift;
	my $direction = shift;
	my $symbol    = shift;    #hash x, y
	my $polarity  = shift;    #

	$polarity  = defined $polarity  ? $polarity  : 'positive';
	$direction = defined $direction ? $direction : 'cw';

	return
	  $inCAM->COM(
				   "add_arc",
				   "symbol"     => $symbol,
				   "polarity"   => $polarity,
				   "attributes" => "yes",
				   "direction"  => $direction,
				   "xs"         => $startP->{"x"},
				   "ys"         => $startP->{"y"},
				   "xe"         => $endP->{"x"},
				   "ye"         => $endP->{"y"},
				   "xc"         => $centerP->{"x"},
				   "yc"         => $centerP->{"y"}
	  );

}

# add circle by radius an center
sub AddCircleRadiusCenter {
	my $self      = shift;
	my $inCAM     = shift;
	my $radius    = shift;
	my $centerP   = shift;
	my $direction = shift;
	my $symbol    = shift;    #hash x, y
	my $polarity  = shift;    #
	
	
	my $startP    = { "x" =>  $centerP->{"x"} - $radius, "y" =>  $centerP->{"y"} - $radius };
	my $endP      = $startP;

	$self->AddArcStartCenterEnd($inCAM, $startP, $centerP, $endP, $direction, $symbol, $polarity);
 
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#	use aliased 'CamHelpers::CamSymbolArc';
#	use aliased 'Packages::InCAM::InCAM';
#
#	my $jobName   = "f52456";
#	my $layerName = "f";
#
#	my $inCAM = InCAM->new();
#
#	$inCAM->COM("sel_delete");
#
#	my @points = ();
#	my %point1 = ( "x" => 0, "y" => 0 );
#	my %point2 = ( "x" => 100, "y" => 0 );
#	my %point3 = ( "x" => 100, "y" => 100 );
#	my %point4 = ( "x" => 0, "y" => 100 );
#
#	CamSymbolSurf->AddSurfaceLinePattern( $inCAM, 1, 100, undef, 45, 50, 1000 );
#
#	CamSymbolSurf->AddSurfacePolyline( $inCAM, \@points, 1 )

}

1;
