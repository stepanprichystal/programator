#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with routing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutingOperation;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamSymbol';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

sub RoutCompensationDelRemains {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	CamHelper->SetStep( $inCAM, $step );

	CamLayer->WorkLayer( $inCAM, $layer );

	my $flatL = GeneralHelper->GetGUID();
	my $compL = GeneralHelper->GetGUID();

	$inCAM->COM( 'flatten_layer', "source_layer" => $layer, "target_layer" => $flatL );
	CamLayer->SetLayerTypeLayer( $inCAM, $jobId, $flatL, "rout" );
	$inCAM->COM( "compensate_layer", "source_layer" => $flatL, "dest_layer" => $compL, "dest_layer_type" => "document" );

	CamLayer->WorkLayer( $inCAM, $compL );

	my %limits = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

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
	
	# 3) Countourize and break
	
	$inCAM->COM( "delete_layer", "layer" => $flatL );
	
	return $compL;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Routing::RoutingOperation';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "d222768";
	my $inCAM = InCAM->new();

	my $step = "o+1";

	my $max = RoutingOperation->RoutCompensationDelRemains( $inCAM, $jobId, $step, "fcoverlayc" );

	print "area exceeded=" . $max . "---\n";


	

}

1;
