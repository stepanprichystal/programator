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
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return 1 if plated rout exceed area or if tool in "m" layer is bigger than 5,1mm
sub PlatedAreaExceed {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my $maxArea = 20.428;    # approx area of hole 5,1mm

	my $areaExceed = 0;

	# Test layer "m"

	if ( CamHelper->LayerExists( $inCAM, $jobId, "m" ) ) {
		my %layer = ( "gROWname" => "m" );
		my @layers = ( \%layer );

		CamDrilling->AddHistogramValues( $inCAM, $jobId, $stepName, \@layers );

		if ( $layer{"maxTool"} && $layer{"maxTool"} > 5100 ) {

			$areaExceed = 1;
		}
	}

	# Test plated rout layers

	unless ($areaExceed) {

		my @rLayers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill );

		# do not consider depth and tool angle at rzc and rzs layers
		my @rzcLayers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_bMillTop );
		my @rzsLayers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_bMillBot );

		foreach my $r ( ( @rLayers, @rzcLayers, @rzsLayers ) ) {

			my $lName = $r->{"gROWname"};

			my %featHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $stepName, $lName, 1 );
			next unless ( $featHist{"total"} );

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

	my %limits = CamJob->GetProfileLimits2( $inCAM, $jobId, $stepName );

	# plus 3 mm to each side, because pcb can contain sideplating on edge of pcb, thus count this milling too
	$limits{"xMin"} = int( $limits{"xMin"} - 3 );
	$limits{"xMax"} = int( $limits{"xMax"} + 3 );
	$limits{"yMin"} = int( $limits{"yMin"} - 3 );
	$limits{"yMax"} = int( $limits{"yMax"} + 3 );

	my $profileArea = abs( $limits{"xMin"} - $limits{"xMax"} ) * abs( $limits{"yMin"} - $limits{"yMax"} );

	# 1) delete small pieces (not routed) in milling

	CamLayer->NegativeLayerData( $inCAM, $compL, \%limits );

	CamLayer->WorkLayer( $inCAM, $compL );

	$inCAM->COM( "sel_contourize", "accuracy" => "6.35", "break_to_islands" => "yes", "clean_hole_size" => "76.2", "clean_hole_mode" => "x_or_y" );

	$inCAM->COM( "set_filter_type", "filter_name" => "", "lines" => "yes", "pads" => "yes", "surfaces" => "yes", "arcs" => "yes", "text" => "yes" );
	$inCAM->COM( "set_filter_polarity", "filter_name" => "", "positive" => "yes", "negative" => "yes" );

	$inCAM->COM('adv_filter_reset');
	$inCAM->COM('filter_area_strt');

	my $maxArea = $profileArea / 2;    # delete pieces smaller than half of pcb area

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

	# 2) sometimes there remain thin border after negative layer soo cover this border with negative lines

	CamLayer->WorkLayer( $inCAM, $compL );

	my @coord = ();
	push( @coord, { "x" => $limits{"xMin"}, "y" => $limits{"yMin"} } );
	push( @coord, { "x" => $limits{"xMin"}, "y" => $limits{"yMax"} } );
	push( @coord, { "x" => $limits{"xMax"}, "y" => $limits{"yMax"} } );
	push( @coord, { "x" => $limits{"xMax"}, "y" => $limits{"yMin"} } );

	CamSymbol->AddPolyline( $inCAM, \@coord, "r300", "negative", 1 );

	# 3) Do countours from milling

	CamLayer->Contourize( $inCAM, $compL, "x_or_y", "203200" );    # 203200 = max size of emptz space in InCAM which can be filled by surface
	CamLayer->WorkLayer( $inCAM, $compL );

	$inCAM->COM(
				 "sel_feat2outline",
				 "width"         => "100",
				 "location"      => "on_edge",
				 "offset"        => "0",
				 "polarity"      => "positive",
				 "keep_original" => "no",
				 "text2limit"    => "no"
	);

	# "simplify countour" Do long lines form short lines, do bigger arc from smaller arcs
	$inCAM->COM(
				 'sel_design2rout',
				 det_tol => '100',
				 con_tol => '100',
				 rad_tol => '52'
	);
	
	$inCAM->COM( "arc2lines", "arc_line_tol" => 70 );

	# remove small lines (smaller than 10µm) and arc in order to proper parsing of coutours 
	my $featFilter = FeatureFilter->new( $inCAM, $jobId, $compL );
	$featFilter->SetFeatureTypes( "line" => 1 );
	$featFilter->SetLineLength( 0, 0.01 );

	if ( $featFilter->Select() ) {

		# remove short lines
		$inCAM->COM("sel_delete");

		# connect lines with gap to 100µm
		$inCAM->COM(
					 'sel_design2rout',
					 det_tol => '100',
					 con_tol => '100',
					 rad_tol => '0'
		);
	}

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

	my $jobId = "d245351";
	my $inCAM = InCAM->new();

	my $step = "o+1";

	my $max = PlatedRoutArea->PlatedAreaExceed( $inCAM, $jobId, $step );

	print "area exceeded=" . $max . "---\n";

}

1;
