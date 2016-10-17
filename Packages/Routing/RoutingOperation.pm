#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with routing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutingOperation;

#3th party library
use strict;
use warnings;
use Math::Polygon;
use List::Util qw[max];

#local library

use aliased 'Helpers::GeneralHelper';

use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Polygon::Features::PolyLineFeatures::PolyLineFeatures';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

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

		if ( $layer{"minTool"} && $layer{"minTool"} > 5000 ) {

			$areaExceed = 1;
		}
	}

	# Test plated rout layers

	unless ($areaExceed) {

		my @rLayers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill );

		foreach my $r (@rLayers) {

			my $lName = $r->{"gROWname"};

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


	$inCAM->COM("set_filter_type","filter_name" => "","lines" => "yes","pads" => "yes","surfaces" => "yes","arcs" => "yes","text" => "yes");
	$inCAM->COM("set_filter_polarity","filter_name" => "","positive" => "yes","negative" => "yes");

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
	$inCAM->COM("sel_delete");

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

#Return final thickness of pcb base on Cu layer number
sub AddPilotHole {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $layer    = shift;

	CamHelper->OpenJobAndStep( $inCAM, $jobId, $stepName );

	my $usrName = CamHelper->GetUserName($inCAM);

	# roout tools
	my @tools = ();

	#determine if take user or site file rout_size.tab
	my $toolTable = EnumsPaths->InCAM_users . $usrName . "\\hooks\\rout_size.tab";

	unless ( -e $toolTable ) {
		$toolTable = EnumsPaths->InCAM_hooks . "rout_size.tab";
	}

	@tools = @{ FileHelper->ReadAsLines($toolTable) };
	@tools = sort { $a <=> $b } @tools;

	# Get information about all chains
	my $route = RouteFeatures->new();
	$route->Parse( $inCAM, $jobId, $stepName, $layer );

	my @chains = $route->GetChains();

	foreach my $chain (@chains) {

		my $chainNum  = $chain->{".rout_chain"};
		my $chainSize = $chain->{".tool_size"} / 1000;                # in mm
		my $pilotSize = $self->GetPilotHole( \@tools, $chainSize );
		$inCAM->COM("chain_list_reset");
		$inCAM->COM( "chain_list_add",  "chain" => $chainNum );
		$inCAM->COM( "chain_del_pilot", "layer" => $layer );          # delete pilot if exist

		$inCAM->COM(
					 "chain_add_pilot",
					 "layer"          => $layer,
					 "pilot_size"     => $pilotSize,
					 "mode"           => "plunge",
					 "ext_layer"      => $layer,
					 "offset_along"   => "0",
					 "offset_perpend" => "0"
		);
	}

}

# Return best pilot hole for chain size
sub GetPilotHole {
	my $self       = shift;
	my @drillTools = @{ shift(@_) };    #available drill tool size
	my $routSize   = shift;             #rout size

	my $lastTool;

	for ( my $i = 0 ; $i < scalar(@drillTools) ; $i++ ) {

		my $drill = $drillTools[$i];
		chomp($drill);

		if ( $drill <= $routSize ) {

			$lastTool = $drill;
		}
		else {

			last;
		}
	}
	return $lastTool;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Routing::RoutingOperation';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "f13609";
	my $inCAM = InCAM->new();

	my $step  = "panel";
	 
	my $max   = RoutingOperation->PlatedAreaExceed( $inCAM, $jobId, $step );

	print $max;

}

1;
