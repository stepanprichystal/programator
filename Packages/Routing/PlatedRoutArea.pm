#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with routing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::PlatedRoutArea;

#3th party library
use strict;
use warnings;
use Math::Polygon;
use List::Util qw[max];

#local library

use aliased 'Helpers::GeneralHelper';

use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return 1 if plated rout exceed area or if tool in "m" layer is bigger than 5mm
sub PlatedAreaExceed {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	
	my $maxArea = 19.5;    # approx area of hole 5mm

	my $areaExceed = 0;

	# Test layer "m"

	if ( CamHelper->LayerExists( $inCAM, $jobId, "m" ) ) {
		my %layer = ( "gROWname" => "m" );
		my @layers = ( \%layer );

		CamDrilling->AddHistogramValues( $inCAM, $jobId, \@layers );

		if ( $layer{"minTool"} && $layer{"maxTool"} > 5000 ) {

			$areaExceed = 1;
		}
	}

	# Test plated rout layers

	unless ($areaExceed) {

		my @rLayers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill );

		foreach my $r (@rLayers) {

			my $lName = $r->{"gROWname"};

			# test if step has nested..
			# if so, test if has only one type
			if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $stepName ) ) {

				my @uniqueStps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $stepName );

				if ( scalar(@uniqueStps) == 1 ) {

					$stepName = $uniqueStps[0]->{"stepName"};
				}
			}

			my $area = $self->GetMaxAreaOfRout( $inCAM, $jobId, $stepName, $lName );

			if ( $area > $maxArea ) {
				$areaExceed = 1;
				last;
			}
		}
	}

	return $areaExceed;

}

sub GetMaxAreaOfRout {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $layer    = shift;

	my @areas = $self->GetAreasOfRout( $inCAM, $jobId, $stepName, $layer );

	my $max = max(@areas);

	return $max;

}

# List of computed areas for each plated rout in flatterned step in layer "r"
sub GetAreasOfRout {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $layer    = shift;

	CamHelper->SetStep( $inCAM, $stepName );

	CamLayer->WorkLayer( $inCAM, $layer );

	my $flatL = GeneralHelper->GetGUID();
	my $compL = GeneralHelper->GetGUID();

	$inCAM->COM( 'flatten_layer', "source_layer" => $layer, "target_layer" => $flatL );
	CamLayer->SetLayerTypeLayer( $inCAM, $jobId, $flatL, "rout" );
	$inCAM->COM( "compensate_layer", "source_layer" => $flatL, "dest_layer" => $compL, "dest_layer_type" => "document" );

	CamLayer->WorkLayer( $inCAM, $compL );

	my %limits = CamJob->GetProfileLimits( $inCAM, $jobId, $stepName );
	my $profileArea = abs( $limits{"xmin"} - $limits{"xmax"} ) * abs( $limits{"ymin"} - $limits{"ymax"} );

	$limits{"xMin"} = $limits{"xmin"};
	$limits{"xMax"} = $limits{"xmax"};
	$limits{"yMin"} = $limits{"ymin"};
	$limits{"yMax"} = $limits{"ymax"};

	CamLayer->NegativeLayerData( $inCAM, $compL, \%limits );

	CamLayer->WorkLayer( $inCAM, $compL );

	$inCAM->COM( "sel_contourize", "accuracy" => "6.35", "break_to_islands" => "yes", "clean_hole_size" => "76.2", "clean_hole_mode" => "x_or_y" );

	$inCAM->COM( "set_filter_type", "filter_name" => "", "lines" => "yes", "pads" => "yes", "surfaces" => "yes", "arcs" => "yes", "text" => "yes" );
	$inCAM->COM( "set_filter_polarity", "filter_name" => "", "positive" => "yes", "negative" => "yes" );

	$inCAM->COM('adv_filter_reset');
	$inCAM->COM('filter_area_strt');

	my $maxArea = $profileArea / 2;

	$inCAM->COM(
				 "adv_filter_set",
				 "filter_name"   => "popup",
				 "active"        => "yes",
				 "limit_box"     => "no",
				 "bound_box"     => "no",
				 "srf_values"    => "yes",
				 "min_islands"   => "0",
				 "max_islands"   => "0",
				 "min_holes"     => "0",
				 "max_holes"     => "0",
				 "min_edges"     => "0",
				 "max_edges"     => "0",
				 "srf_area"      => "yes",
				 "min_area"      => "0",
				 "max_area"      => $maxArea,
				 "mirror"        => "any",
				 "ccw_rotations" => ""
	);

	$inCAM->COM( "filter_area_end", "filter_name" => "popup", "operation" => "select" );
	if ( $inCAM->GetReply() > 0 ) {
		$inCAM->COM("sel_delete");
	}

	CamLayer->NegativeLayerData( $inCAM, $compL, \%limits );

	CamLayer->WorkLayer( $inCAM, $compL );

	$inCAM->COM( "sel_contourize", "accuracy" => "6.35", "break_to_islands" => "yes", "clean_hole_size" => "76.2", "clean_hole_mode" => "x_or_y" );

	$inCAM->COM(
				 "sel_feat2outline",
				 "width"         => "100",
				 "location"      => "on_edge",
				 "offset"        => "0",
				 "polarity"      => "positive",
				 "keep_original" => "no",
				 "text2limit"    => "no"
	);
	$inCAM->COM( "arc2lines", "arc_line_tol" => 25 );

	my $polyLine = PolyLineFeatures->new();
	$polyLine->Parse( $inCAM, $jobId, $stepName, $compL );

	my @points = $polyLine->GetPolygonsPoints();
	my @areas  = ();

	foreach my $p (@points) {

		my $p    = Math::Polygon->new( @{$p} );
		my $area = $p->area;

		push( @areas, $area );

	}

	$inCAM->COM( "delete_layer", "layer" => $flatL );
	$inCAM->COM( "delete_layer", "layer" => $compL );

	return @areas;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Routing::PlatedRoutArea';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "f13610";
	my $inCAM = InCAM->new();

	my $step = "panel";

	my $max = PlatedRoutArea->PlatedAreaExceed( $inCAM, $jobId, $step );

	print "area exceeded=" . $max . "---\n";

}

1;
