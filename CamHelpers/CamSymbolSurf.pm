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
use aliased 'Packages::Polygon::Enums' => 'EnumsPoly';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub AddSurfaceCircle {
	my $self     = shift;
	my $inCAM    = shift;
	my $radius   = shift;
	my $centerP  = shift;
	my $pattern  = shift;
	my $polarity = shift;

	# if pattern is not defined, use solid pattern
	unless ($pattern) {
		$self->AddSurfaceSolidPattern($inCAM);
	}

	$polarity = defined $polarity ? $polarity : 'positive';

	$inCAM->COM( "add_surf_strt", "surf_type" => "feature" );

	$inCAM->COM( "add_surf_poly_strt", "x" => $centerP->{"x"} + $radius, "y" => $centerP->{"y"} );

	$inCAM->COM( "add_surf_poly_crv", "xc" => $centerP->{"x"}, "yc" => $centerP->{"y"}, "xe" => $centerP->{"x"} + $radius, "ye" => $centerP->{"y"} );

	$inCAM->COM("add_surf_poly_end");
	$inCAM->COM( "add_surf_end", "polarity" => $polarity, "attributes" => "no" );

}

# Draw surface polyline
# (arc shape is supported)
sub AddSurfacePolyline {
	my $self  = shift;
	my $inCAM = shift;

	# Each point is defined by hash:
	# - x; y       = coordinate of next point
	# - xmid; ymid = coordinate of center of arc (if arc)
	# - dir        = direction of arc (cw/ccw)   (if arc)
	# Polygon points has to by closed (first point coordinate == last point coordinate)
	my @points   = @{ shift(@_) };
	my $pattern  = shift;
	my $polarity = shift;

	if ( scalar(@points) < 4 ) {
		die "Minimal count of surface points is 4.\n";
	}
	
	if ( $points[0]->{"x"} !=  $points[scalar(@points)-1]->{"x"} || $points[0]->{"y"} !=  $points[scalar(@points)-1]->{"y"}  ) {
		die "First and last polygon point coordinate has to by equal.\n";
	}

	# if pattern is not defined, use solid pattern
	unless ($pattern) {
		$self->AddSurfaceSolidPattern($inCAM);
	}

	$polarity = defined $polarity ? $polarity : 'positive';

	#push( @points, $points[0] );    # push first poin to last in order close poly gon

	$inCAM->COM( "add_surf_strt", "surf_type" => "feature" );

	my $startP = $points[0];
	$inCAM->COM( "add_surf_poly_strt", "x" => $startP->{"x"}, "y" => $startP->{"y"} );

	for ( my $i = 1 ; $i < scalar(@points) ; $i++ ) {

		my $p = $points[$i];

		if ( defined $p->{"xmid"} && defined $p->{"ymid"} && defined $p->{"dir"} ) {

			$inCAM->COM(
						 "add_surf_poly_crv",
						 "xe" => $p->{"x"},
						 "ye" => $p->{"y"},
						 "xc" => $p->{"xmid"},
						 "yc" => $p->{"ymid"},
						 "cw" => ( $p->{"dir"} eq EnumsPoly->Dir_CW ? "yes" : "no" )
			);

		}
		else {
			$inCAM->COM( "add_surf_poly_seg", "x" => $p->{"x"}, "y" => $p->{"y"} );
		}

	}

	$inCAM->COM("add_surf_poly_end");
	$inCAM->COM( "add_surf_end", "polarity" => $polarity, "attributes" => "yes" );

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
				 "type"           => "solid",
				 "solid_type"     => "surface",
				 "min_brush"      => "25.4",
				 "use_arcs"       => "yes",
				 "cut_prims"      => "no",
				 "outline_draw"   => $outline_draw,
				 "outline_width"  => $outline_width,
				 "outline_invert" => $outline_invert
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

# Surface symbol patter
sub AddSurfaceSymbolPattern {
	my $self           = shift;
	my $inCAM          = shift;
	my $outline_draw   = shift;
	my $outline_width  = shift // 0;    # outline width in µm
	my $outline_invert = shift;
	my $cut_prims      = shift;
	my $symbol         = shift;
	my $dx             = shift;
	my $dy             = shift;

	$outline_draw   = $outline_draw   ? "yes" : 'no';
	$outline_invert = $outline_invert ? "yes" : 'no';
	$cut_prims      = $cut_prims      ? "yes" : 'no';

	$inCAM->COM(
				 'add_surf_fill',
				 "type"           => "pattern",
				 "symbol"         => $symbol,
				 "dx"             => $dx,
				 "dy"             => $dy,
				 "x_off"          => "0",
				 "y_off"          => "0",
				 "break_partial"  => "yes",
				 "cut_prims"      => $cut_prims,
				 "outline_draw"   => $outline_draw,
				 "outline_width"  => $outline_width,
				 "outline_invert" => $outline_invert,
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

sub AddSurfaceFillSolid {
	my $self  = shift;
	my $inCAM = shift;

	# solid pattern parameters
	my $outline_draw   = shift;
	my $outline_width  = shift;        # outline width in µm
	my $outline_invert = shift // 0;

	$outline_draw   = $outline_draw   ? "yes" : 'no';
	$outline_invert = $outline_invert ? "yes" : 'no';

	# surface fill parameters
	my $step_margin_x = shift;
	my $step_margin_y = shift;
	my $sr_margin_x   = shift;
	my $sr_margin_y   = shift;
	my $consider_feat = shift;
	my $feat_margin   = shift;

	my $polarity = shift // "positive";    #

	$consider_feat = $consider_feat ? "yes" : 'no';

	$inCAM->COM(
		"sr_fill",
		"type"           => "solid",
		"solid_type"     => "surface",
		"min_brush"      => "25.4",
		"use_arcs"       => "no",
		"cut_prims"      => "no",
		"outline_draw"   => $outline_draw,
		"outline_width"  => $outline_width,
		"outline_invert" => $outline_invert,
		"polarity"       => $polarity,
		"step_margin_x"  => $step_margin_x,
		"step_margin_y"  => $step_margin_y,

		"sr_margin_x"   => $sr_margin_x,
		"sr_margin_y"   => $sr_margin_y,
		"sr_max_dist_x" => "0",
		"sr_max_dist_y" => "0",
		"nest_sr"       => "yes",
		"consider_feat" => $consider_feat,
		"feat_margin"   => $feat_margin,

		"dest"       => "affected_layers",
		"layer"      => ".affected",
		"attributes" => 'yes'
	);

}

sub AddSurfaceFillSymbol {
	my $self  = shift;
	my $inCAM = shift;

	# solid pattern parameters

	my $outline_draw   = shift;
	my $outline_width  = shift;        # outline width in µm
	my $outline_invert = shift // 0;

	my $symbol = shift;
	my $dx     = shift;
	my $dy     = shift;

	$outline_draw   = $outline_draw   ? "yes" : 'no';
	$outline_invert = $outline_invert ? "yes" : 'no';

	# surface fill parameters
	my $step_margin_x = shift;
	my $step_margin_y = shift;
	my $sr_margin_x   = shift;
	my $sr_margin_y   = shift;
	my $consider_feat = shift;
	my $feat_margin   = shift;

	my $polarity = shift // "positive";    #

	$consider_feat = $consider_feat ? "yes" : 'no';

	$inCAM->COM(
		"sr_fill",
		"type"           => "pattern",
		"symbol"         => $symbol,
		"dx"             => $dx,
		"dy"             => $dy,
		"x_off"          => "0",
		"y_off"          => "0",
		"break_partial"  => "yes",
		"cut_prims"      => "no",
		"outline_draw"   => $outline_draw,
		"outline_width"  => $outline_width,
		"outline_invert" => $outline_invert,
		"polarity"       => $polarity,
		"step_margin_x"  => $step_margin_x,
		"step_margin_y"  => $step_margin_y,

		"sr_margin_x"   => $sr_margin_x,
		"sr_margin_y"   => $sr_margin_y,
		"sr_max_dist_x" => "0",
		"sr_max_dist_y" => "0",
		"nest_sr"       => "yes",
		"consider_feat" => $consider_feat,
		"feat_margin"   => $feat_margin,

		"dest"       => "affected_layers",
		"layer"      => ".affected",
		"attributes" => 'yes'
	);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
	use aliased 'CamHelpers::CamSymbolSurf';
	use aliased 'Packages::InCAM::InCAM';

	my $jobName   = "d152456";
	my $layerName = "c";

	my $inCAM = InCAM->new();

	$inCAM->COM("sel_delete");

	my @points = ();
	my %point1 = ( "x" => 0, "y" => 0 );
	my %point2 = ( "x" => 100, "y" => 0 );
	my %point3 = ( "x" => 100, "y" => 100 );
	my %point4 = ( "x" => 0, "y" => 100 );
	my %point5 = ( "x" => 0, "y" => 0 );

	@points = ( \%point1, \%point2, \%point3, \%point4, \%point5 );

	#CamSymbolSurf->AddSurfaceLinePattern( $inCAM, 1, 100, undef, 45, 50, 1000 );

	CamSymbolSurf->AddSurfacePolyline( $inCAM, \@points )

}

1;

1;
