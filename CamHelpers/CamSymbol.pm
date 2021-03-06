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

use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::Polygon::Enums' => 'EnumsPoly';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
 
#Return hash, kyes are "top"/"bot", values are 0/1
sub AddText {
	my $self       = shift;
	my $inCAM      = shift;
	my $text       = shift;
	my $position   = shift;
	my $textHeight = shift;                   # char height in mm
	my $textWidth  = shift // $textHeight;    # char width in mm (default same as height)
	my $lineWidth  = shift;                   # text lines width mm

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
		"type"       => "string",
		"polarity"   => $polarity,
		"x"          => $position->{"x"},
		"y"          => $position->{"y"},
		"text"       => $text,
		"fontname"   => "standard",
		"height"     => $textHeight,
		"style"      => "regular",
		"width"      => "normal",
		"mirror"     => $mirror,
		"angle"      => $angle,
		"direction"  => "ccw",
		"w_factor"   => $lineWidth,
		"attributes" => 'yes',

		#				 "x_size"    => $textHeight,
		#				 "y_size"    => $textWidth
	);

}

# Draw polyline
# (arc shape is supported)
sub AddPolyline {
	my $self  = shift;
	my $inCAM = shift;

	# Each point is defined by hash:
	# - x; y       = coordinate of next point
	# - xmid; ymid = coordinate of center of arc (if arc)
	# - dir        = direction of arc (cw/ccw)   (if arc)
	# Polygon points has to by closed (first point coordinate == last point coordinate)
	my @coord        = @{ shift(@_) };
	my $symbol       = shift;
	my $polarity     = shift;
	my $closePolygon = shift;

	if ( scalar(@coord) < 3 ) {
		die "Polyline has to have at lest 3 coordinates.\n";
	}

	$inCAM->COM("add_polyline_strt");

	foreach my $p (@coord) {

		if ( defined $p->{"xmid"} && defined $p->{"ymid"} && defined $p->{"dir"} ) {

			$inCAM->COM(
						 "add_polyline_crv",
						 "xe" => $p->{"x"},
						 "ye" => $p->{"y"},
						 "xc" => $p->{"xmid"},
						 "yc" => $p->{"ymid"},
						 "cw" => ( $p->{"dir"} eq EnumsPoly->Dir_CW ? "yes" : "no" )
			);

		}
		else {

			$inCAM->COM( "add_polyline_xy", "x" => $p->{"x"}, "y" => $p->{"y"} );
		}

	}

	if ($closePolygon) {
		$inCAM->COM( "add_polyline_xy", "x" => $coord[0]->{"x"}, "y" => $coord[0]->{"y"} );
	}

	$inCAM->COM(
				 "add_polyline_end",
				 "polarity"      => $polarity,
				 "attributes"    => "yes",
				 "symbol"        => $symbol,
				 "bus_num_lines" => "0",
				 "bus_dist_by"   => "pitch",
				 "bus_distance"  => "0",
				 "bus_reference" => "left"
	);

}

sub AddLine {
	my $self     = shift;
	my $inCAM    = shift;
	my $startP   = shift;    #hash x, y
	my $endP     = shift;
	my $symbol   = shift;
	my $polarity = shift;    #

	$polarity = defined $polarity ? $polarity : 'positive';

	return
	  $inCAM->COM(
				   'add_line',
				   attributes => 'yes',
				   "xs"       => $startP->{"x"},
				   "ys"       => $startP->{"y"},
				   "xe"       => $endP->{"x"},
				   "ye"       => $endP->{"y"},
				   "symbol"   => $symbol,
				   "polarity" => $polarity
	  );
}

sub AddPad {
	my $self     = shift;
	my $inCAM    = shift;
	my $symbol   = shift;
	my $pos      = shift;        #hash x, y
	my $mirror   = shift;
	my $polarity = shift;        #
	my $angle    = shift // 0;
	my $resize   = shift // 0;
	my $xscale   = shift // 1;
	my $yscale   = shift // 1;

	$polarity = defined $polarity ? $polarity : 'positive';

	if ($mirror) {
		$mirror = "yes";
	}
	else {
		$mirror = "no";
	}

	return
	  $inCAM->COM(
				   "add_pad",
				   "attributes" => 'yes',
				   "symbol"     => $symbol,
				   "polarity"   => $polarity,
				   "x"          => $pos->{"x"},
				   "y"          => $pos->{"y"},
				   "mirror"     => $mirror,
				   "angle"      => $angle,
				   "direction"  => "ccw",
				   "resize"     => $resize,
				   "xscale"     => $xscale,
				   "yscale"     => $yscale
	  );
}

sub AddTable {
	my $self       = shift;
	my $inCAM      = shift;
	my $position   = shift;             # position of table, hash x,y
	my @colWidths  = @{ shift(@_) };    # each column width in mm
	my $rowHeight  = shift;             # row height in mm
	my $textHeight = shift;             # font size in mm
	my $lineWidth  = shift;             # font width in mm
	my @rows       = @{ shift(@_) };

	# my compute dimension
	my $tableWidth  = sum(@colWidths);
	my $tableHeight = scalar(@rows) * $rowHeight;

	my $rowCnt = scalar(@rows);
	my $colCnt = scalar(@colWidths);

	my $rowPos = $position->{"y"};

	# add rows
	for ( my $i = 0 ; $i < $rowCnt ; $i++ ) {

		my %startP = ( "x" => $position->{"x"}, "y" => $rowPos );
		my %endP = ( "x" => $tableWidth, "y" => $rowPos );
		$self->AddLine( $inCAM, \%startP, \%endP, "r200" );
		$rowPos += $rowHeight;

		# add last row line
		if ( $i + 1 == $rowCnt ) {
			my %startP = ( "x" => $position->{"x"}, "y" => $rowPos );
			my %endP = ( "x" => $tableWidth, "y" => $rowPos );
			$self->AddLine( $inCAM, \%startP, \%endP, "r200" );
		}
	}

	my $colPos = $position->{"x"};

	# add cols
	for ( my $i = 0 ; $i < $colCnt ; $i++ ) {

		my %startP = ( "x" => $colPos, "y" => $position->{"y"} );
		my %endP   = ( "x" => $colPos, "y" => $position->{"y"} + $tableHeight );

		$self->AddLine( $inCAM, \%startP, \%endP, "r200" );
		$colPos += $colWidths[$i];

		# add last column line
		if ( $i + 1 == $colCnt ) {
			%startP = ( "x" => $colPos, "y" => $position->{"y"} );
			%endP   = ( "x" => $colPos, "y" => $position->{"y"} + $tableHeight );

			$self->AddLine( $inCAM, \%startP, \%endP, "r200" );
		}
	}

	# Fill table with text

	@rows = reverse(@rows);    # we fill from bot
	my $txtPosY = $position->{"y"};
	for ( my $i = 0 ; $i < $rowCnt ; $i++ ) {

		my $rowData = $rows[$i];

		my $txtPosX = $position->{"x"};

		for ( my $j = 0 ; $j < $colCnt ; $j++ ) {

			my $cellData = @{$rowData}[$j];
			unless ( defined $cellData ) {
				$cellData = "";
			}

			my %posTxt = ( "x" => $txtPosX + $colWidths[$j] * 0.05, "y" => $txtPosY + ( $rowHeight - $textHeight ) / 2 );

			$self->AddText( $inCAM, $cellData, \%posTxt, $textHeight, 1 );

			$txtPosX += $colWidths[$j];    # update position X
		}

		$txtPosY += $rowHeight;            # update position Y

	}
}

# Reset current attributes, which will be added to added symbol
sub ResetCurAttributes {
	my $self  = shift;
	my $inCAM = shift;

	$inCAM->COM("cur_atr_reset");

}

# Set current attributes, which will be added to added symbol
sub AddCurAttribute {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $attName = shift;
	my $attVal  = shift;

	# decide, which type is attribute
	my %attrInfo = CamAttributes->GetAttrParamsByName( $inCAM, $jobId, $attName );

	my $int    = 0;
	my $float  = 0;
	my $option = "";
	my $text   = "";

	if ( $attrInfo{"gATRtype"} eq "int" ) {

		$int = $attVal;

	}
	elsif ( $attrInfo{"gATRtype"} eq "float" ) {

		$float = $attVal;

	}
	elsif ( $attrInfo{"gATRtype"} eq "option" ) {

		$option = $attVal;

	}
	elsif ( $attrInfo{"gATRtype"} eq "text" ) {

		$text = $attVal;
	}

	$inCAM->COM(
				 'cur_atr_set',
				 "attribute" => $attName,
				 "int"       => $int,
				 "float"     => $float,
				 "option"    => $option,
				 "text"      => $text
	);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
	use aliased 'CamHelpers::CamSymbol';
	use aliased 'Packages::InCAM::InCAM';

	my $jobName   = "d266089";
	my $layerName = "c";

	my $inCAM = InCAM->new();

	$inCAM->COM("sel_delete");

	#	my %pos = ( "x" => 0, "y" => 0 );
	#
	#	my @colWidths = ( 70, 60, 60 );
	#
	#	my @row1 = ( "Tool [mm]", "Depth [mm]", "Tool angle" );
	#	my @row2 = ( 2000, 1.2, );
	#
	#	my @rows = ( \@row1, \@row2 );
	#
	#	CamSymbol->AddTable( $inCAM, \%pos, \@colWidths, 10, 5, 2, \@rows );
	#
	#	my %posTitl = ( "x" => 0, "y" => scalar(@rows) * 10 + 5 );
	#	CamSymbol->AddText( $inCAM, "Tool depths definition", \%posTitl, 6, 1 );

	my @points = ();
	my %point1 = ( "x" => 0, "y" => 0 );
	my %point2 = ( "x" => 100, "y" => 0 );
	my %point3 = ( "x" => 100, "y" => 100 );
	my %point4 = ( "x" => 0, "y" => 100 );

	@points = ( \%point1, \%point2, \%point3, \%point4 );

 
	CamSymbol->AddPolyline( $inCAM, \@points, "r200", "positive",1 )

}

1;

1;
