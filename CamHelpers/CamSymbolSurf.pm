#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with surface symbols
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamSymbolSurf;

#3th party library
use strict;
use warnings;
use List::Util qw[sum];

#loading of locale modules

use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub AddSurfaceCircle {
	my $self    = shift;
	my $inCAM   = shift;
	my $radius  = shift;
	my $centerP = shift;
	my $pattern = shift;
	my $polarity = shift;  

	# if pattern is not defined, use solid pattern
	unless ($pattern) {
		$self->AddSurfaceSolidPattern($inCAM);
	}

	$polarity = defined $polarity ? $polarity : 'positive';

	$inCAM->COM( "add_surf_strt", "surf_type" => "feature" );
	
	$inCAM->COM( "add_surf_poly_strt", "x" =>$centerP->{"x"} + $radius, "y" => $centerP->{"y"} );

	$inCAM->COM( "add_surf_poly_crv", "xc" => $centerP->{"x"}, "yc" => $centerP->{"y"}, "xe" => $centerP->{"x"} + $radius, "ye" => $centerP->{"y"} );

	 
	$inCAM->COM("add_surf_poly_end");
	$inCAM->COM( "add_surf_end", "polarity" => $polarity, "attributes" => "no" );

	

}

sub AddSurfacePolyline {
	my $self     = shift;
	my $inCAM    = shift;
	my @points   = @{ shift(@_) };    #hash x, y
	my $pattern  = shift;
	my $polarity = shift;             #

	if ( scalar(@points) < 3 ) {
		die "Minimal count of surface points is 3.\n";
	}

	# if pattern is not defined, use solid pattern
	unless ($pattern) {
		$self->AddSurfaceSolidPattern($inCAM);
	}

	$polarity = defined $polarity ? $polarity : 'positive';

	push( @points, $points[0] );    # push first poin to last in order close poly gon

	$inCAM->COM( "add_surf_strt", "surf_type" => "feature" );

	my $startP = $points[0];
	$inCAM->COM( "add_surf_poly_strt", "x" => $startP->{"x"}, "y" => $startP->{"y"} );

	for ( my $i = 1 ; $i < scalar(@points) ; $i++ ) {

		my $p = $points[$i];
		$inCAM->COM( "add_surf_poly_seg", "x" => $p->{"x"}, "y" => $p->{"y"} );
	}

	$inCAM->COM("add_surf_poly_end");
	$inCAM->COM( "add_surf_end", "polarity" => $polarity, "attributes" => "no" );

}

sub AddSurfaceSolidPattern {
	my $self           = shift;
	my $inCAM          = shift;
	my $outline_draw   = shift;
	my $outline_width  = shift;    # outline width in µm
	my $outline_invert = shift;

	$outline_draw = $outline_draw ? "yes" : 'no';

	unless ( defined $outline_width ) {
		$outline_width = 0;
	}

	$outline_invert = $outline_invert ? "yes" : 'no';

	$inCAM->COM(
				 "add_surf_fill",
				 "type"                    => "predefined_pattern",
				 "cut_prims"               => "no",
				 "outline_draw"            => $outline_draw,
				 "outline_width"           => $outline_width,
				 "outline_invert"          => $outline_invert,
				 "predefined_pattern_type" => "solid"
	);
}

sub AddSurfaceLinePattern {
	my $self           = shift;
	my $inCAM          = shift;
	my $outline_draw   = shift;
	my $outline_width  = shift;    # outline width in µm
	my $lines_angle    = shift;
	my $outline_invert = shift;
	my $lines_width    = shift;
	my $lines_dist     = shift;

	$outline_draw = $outline_draw ? "yes" : 'no';

	unless ( defined $outline_width ) {
		$outline_width = 0;
	}

	$outline_invert = $outline_invert ? "yes" : 'no';

	$inCAM->COM(
				 "add_surf_fill",
				 "type"                    => "predefined_pattern",
				 "cut_prims"               => "no",
				 "outline_draw"            => $outline_draw,
				 "outline_width"           => $outline_width,
				 "outline_invert"          => $outline_invert,
				 "predefined_pattern_type" => "lines",
				 "indentation"             => "even",
				 "lines_angle"             => $lines_angle,
				 "lines_witdh"             => $lines_width,
				 "lines_dist"              => $lines_dist
	);
}

# surface cross_hatch pattern
# $setToExisting:
# - 1 - set surface pattern to existing selected surface
# - 0 - activate surface pattern, when new surface will be created
sub SurfaceCrossHatchPattern {
	my $self              = shift;
	my $inCAM             = shift;
	my $setToExisting     = shift;
	my $outline_draw      = shift;
	my $outline_width     = shift;    # outline width in µm
	my $cross_hatch_angle = shift;
	my $outline_invert    = shift;
	my $cross_hatch_width = shift;
	my $cross_hatch_dist  = shift;
	my $cut_prims         = shift;

	$outline_draw = $outline_draw ? "yes" : 'no';

	unless ( defined $outline_width ) {
		$outline_width = 0;
	}

	$outline_invert = $outline_invert ? "yes" : 'no';

	$cut_prims = $cut_prims ? "yes" : 'no';

	my $mode = $setToExisting ? "sel_fill" : "add_surf_fill";

	$inCAM->COM(
				 $mode,
				 "type"                    => "predefined_pattern",
				 "cut_prims"               => $cut_prims,
				 "outline_draw"            => $outline_draw,
				 "outline_width"           => $outline_width,
				 "outline_invert"          => $outline_invert,
				 "predefined_pattern_type" => "cross_hatch",
				 "indentation"             => "even",
				 "cross_hatch_angle"       => $cross_hatch_angle,
				 "cross_hatch_witdh"       => $cross_hatch_width,
				 "cross_hatch_dist"        => $cross_hatch_dist
	);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
	use aliased 'CamHelpers::CamSymbolSurf';
	use aliased 'Packages::InCAM::InCAM';

	my $jobName   = "f13608";
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
	 

	my @points = ();
	my %point1 = ( "x" => 0, "y" => 0 );
	my %point2 = ( "x" => 100, "y" => 0 );
	my %point3 = ( "x" => 100, "y" => 100 );
	my %point4 = ( "x" => 0, "y" => 100 );

	@points = ( \%point1, \%point2, \%point3, \%point4 );

	CamSymbolSurf->AddSurfaceLinePattern( $inCAM, 1, 100, undef, 45, 50, 1000 );

	CamSymbolSurf->AddSurfacePolyline( $inCAM, \@points, 1 )

}

1;

1;
