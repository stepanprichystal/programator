#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with InCAM layer
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamSymbol;

#3th party library
use strict;
use warnings;
use List::Util qw[sum];

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

sub AddPolyline {
	my $self     = shift;
	my $inCAM    = shift;
	my @coord    = @{ shift(@_) };    #hash x, y
	my $symbol   = shift;
	my $polarity = shift;             #

	if ( scalar(@coord) < 3 ) {
		die "Polyline has to have at lest 3 coordinates.\n";
	}

	$inCAM->COM("add_polyline_strt");

	foreach my $c (@coord) {

		$inCAM->COM( "add_polyline_xy", "x" => $c->{"x"}, "y" => $c->{"y"} );
	}

	#last is frst
	$inCAM->COM( "add_polyline_xy", "x" => $coord[0]->{"x"}, "y" => $coord[0]->{"y"} );
	$inCAM->COM(
				 "add_polyline_end",
				 "polarity"      => $polarity,
				 "attributes"    => "no",
				 "symbol"        => $symbol,
				 "bus_num_lines" => "0",
				 "bus_dist_by"   => "pitch",
				 "bus_distance"  => "0",
				 "bus_reference" => "left"
	);

}

sub AddTable {
	my $self       = shift;
	my $inCAM      = shift;
	my $position   = shift;
	my @colWidths  = @{ shift(@_) };
	my $rowHeight  = shift;
	my $textHeight = shift;            # font size in mm
	my $lineWidth  = shift;            # font size in mm
	my @rows       = shift;

	my $rowCnt     = scalar(@rows);
	my $colCnt     = scalar(@colWidths);
	my $tableWidth = sum(@colWidths);

	my $rowPos = $position->{"y"};
	my $colPos = $position->{"x"};

	# add rows
	for ( my $i = 0 ; $i < $rowCnt ; $i++ ) {

		my %startP = ( "x" => $position->{"x"}, "y" => $rowPos );
		my %endP = ( "x" => $tableWidth, "y" => $rowPos );
		$self->AddLine();
		$rowPos += $rowHeight;

		# add last row line
		if ( $i + 1 == $rowCnt ) {
			my %startP = ( "x" => $position->{"x"}, "y" => $rowPos );
			my %endP = ( "x" => $tableWidth, "y" => $rowPos );
			$self->AddLine();
		}
	}
	
	# add cols
	for ( my $i = 0 ; $i < $rowCnt ; $i++ ) {

		my %startP = ( "x" => $position->{"x"}, "y" => $rowPos );
		my %endP = ( "x" => $tableWidth, "y" => $rowPos );
		$self->AddLine();
		$rowPos += $rowHeight;

		# add last row line
		if ( $i + 1 == $rowCnt ) {
			my %startP = ( "x" => $position->{"x"}, "y" => $rowPos );
			my %endP = ( "x" => $tableWidth, "y" => $rowPos );
			$self->AddLine();
		}
	}

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
