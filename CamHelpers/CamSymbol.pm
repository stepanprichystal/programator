#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with InCAM layer
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamSymbol;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Return hash, kyes are "top"/"bot", values are 0/1
sub AddText {
	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $step       = shift;
	my $layer      = shift;
	my $text       = shift;
	my $position   = shift;
	my $textHeight = shift;    # font size in mm
	my $lineWidth  = shift;    # font size in mm

	# optional
	my $mirror   = shift;
	my $polarity = shift;
	my $angle    = shift;

	if ($mirror) {
		$mirror = "yes";
	}
	else {
		$mirror = "no";
	}

	unless ($polarity) {
		$polarity = "positive";
	}

	unless ($angle) {
		$angle = 0;
	}

	$inCAM->COM(
		"add_text",
		"type"      => "string",
		"polarity"  => $polarity,
		"x"         => $position->{"x"},
		"y"         => $position->{"y"},
		"text"      => $text,
		"fontname"  => "standard",
		"height"    => $textHeight,
		"style"     => "regular",
		"width"     => "normal",
		"mirror"    => $mirror,
		"angle"     => $angle,
		"direction" => "cw",
		"w_factor"  => $lineWidth
	);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#
	#	my $jobName          = "f13610";
	#	my $layerName          = "fsch";
	#
	#
	#	use aliased 'CamHelpers::CamLayer';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $res = CamLayer->LayerIsBoard($inCAM, $jobName, $layerName);
	#
	#	print $res;

}

1;

1;
