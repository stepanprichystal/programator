#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with InCAM layer
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamLayer;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Return hash, kyes are "top"/"bot", values are 0/1
sub ExistSolderMasks {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $second = shift // 0;    # second solder mask

	my %masks = $second ? HegMethods->GetSolderMaskColor2($jobId) : HegMethods->GetSolderMaskColor($jobId);

	unless ( defined $masks{"top"} ) {
		$masks{"top"} = 0;
	}
	else {
		$masks{"top"} = 1;
	}
	unless ( defined $masks{"bot"} ) {
		$masks{"bot"} = 0;
	}
	else {
		$masks{"bot"} = 1;
	}
	return %masks;
}

#Return hash, kyes are "top"/"bot", values are 0/1
sub ExistSilkScreens {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $second = shift // 0;    # second silkscreen

	my %silk = $second ? HegMethods->GetSilkScreenColor2($jobId) : HegMethods->GetSilkScreenColor($jobId);

	unless ( defined $silk{"top"} ) {
		$silk{"top"} = 0;
	}
	else {
		$silk{"top"} = 1;
	}

	unless ( defined $silk{"bot"} ) {
		$silk{"bot"} = 0;
	}
	else {
		$silk{"bot"} = 1;
	}
	return %silk;
}

# flattern layer
# create tem flattern layer, delete original layer and place flatern data to original layer
sub FlatternLayer {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;

	my $tmpLayer = GeneralHelper->GetGUID();

	$inCAM->COM( 'flatten_layer', "source_layer" => $layerName, "target_layer" => $tmpLayer );

	$self->WorkLayer( $inCAM, $layerName );
	$inCAM->COM('sel_delete');

	$inCAM->COM(
				 'copy_layer',
				 "source_job"   => $jobId,
				 "source_step"  => $stepName,
				 "source_layer" => $tmpLayer,
				 "dest"         => 'layer_name',
				 "dest_layer"   => $layerName,
				 "mode"         => 'replace',
				 "invert"       => 'no'
	);

	$inCAM->COM( 'delete_layer', "layer" => $tmpLayer );
	$self->ClearLayers($inCAM);
}

# Flattern NC layer
# Create tem flattern layer, delete original layer and place flatern data to original layer
# Difference from function FlatternLayer is, that this methd consider user column values in DTM
# FlatternLayer delete all user column values in flattned layer
sub FlatternNCLayer {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;

	# 1)  When lazer is flattening, chech if nested step has some "?" or "0" value in finish size
	# if so, values, from DTM user columns are not coppied, so change "?" to proper value
	my @childSteps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $stepName );

	foreach my $stepChild (@childSteps) {

		my $change = 0;

		my @tools = CamDTM->GetDTMTools( $inCAM, $jobId, $stepChild->{"stepName"}, $layerName );
		my $DTMType = CamDTM->GetDTMType( $inCAM, $jobId, $stepChild->{"stepName"}, $layerName );

		foreach my $t (@tools) {

			if ( !defined $t->{"gTOOLfinish_size"} || $t->{"gTOOLfinish_size"} eq "" || $t->{"gTOOLfinish_size"} == 0 ) {

				$t->{"gTOOLfinish_size"} = $t->{"gTOOLdrill_size"};

				if ( $DTMType eq EnumsDrill->DTM_VYSLEDNE ) {
					$t->{"gTOOLfinish_size"} -= 100;
				}

				$change = 1;
			}
		}

		if ($change) {

			CamDTM->SetDTMTools( $inCAM, $jobId, $stepChild->{"stepName"}, $layerName, \@tools, $DTMType );
		}
	}

	CamHelper->SetStep( $inCAM, $stepName );

	# 2)  if rout layer, change to drill before flatten, in other case "user column" will not be considered (InCAM BUG)
	my $chahngedToDrill = 0;
	my $layerType = CamHelper->LayerType( $inCAM, $jobId, $layerName );

	if ( $layerType eq "rout" ) {

		$chahngedToDrill = 1;
		$self->SetLayerTypeLayer( $inCAM, $jobId, $layerName, "drill" );
	}

	$self->FlatternLayer( $inCAM, $jobId, $stepName, $layerName );

	# 3) change back to rout
	if ($chahngedToDrill) {
		$self->SetLayerTypeLayer( $inCAM, $jobId, $layerName, "rout" );
	}

	$self->ClearLayers($inCAM);

}

# Remove temporary layers with mark plus
# RV
# Example c+++, s+++....
sub RemoveTempLayerPlus {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	$inCAM->INFO( 'entity_type' => 'matrix', 'entity_path' => "$jobId/matrix", 'data_type' => 'ROW' );
	my $totalRows = ${ $inCAM->{doinfo}{gROWrow} }[-1];
	for ( my $count = 0 ; $count < $totalRows ; $count++ ) {
		my $rowName    = ${ $inCAM->{doinfo}{gROWname} }[$count];
		my $rowContext = ${ $inCAM->{doinfo}{gROWcontext} }[$count];

		if ( $rowContext eq "misc" ) {
			if ( $rowName =~ /\+\+\+/g ) {
				$inCAM->COM( 'delete_layer', layer => "$rowName" );
			}
		}
	}
}

# Display single layer and set as work layer
sub SetLayerTypeLayer {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layer = shift;
	my $type  = shift;

	$inCAM->COM( "matrix_layer_type", "job" => $jobId, "matrix" => "matrix", "layer" => $layer, "type" => $type );

}

# Set polarity of layer
sub SetLayerPolarityLayer {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $layer    = shift;
	my $polarity = shift;

	$inCAM->COM( "matrix_layer_polar", "job" => $jobId, "matrix" => "matrix", "layer" => $layer, "polarity" => $polarity );

}

# Set Context of layer
sub SetLayerContextLayer {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $layer   = shift;
	my $context = shift;

	$inCAM->COM( "matrix_layer_context", "job" => $jobId, "matrix" => "matrix", "layer" => $layer, "context" => $context );

}

# Display single layer and set as work layer
sub WorkLayer {
	my $self  = shift;
	my $inCAM = shift;
	my $layer = shift;

	$self->ClearLayers($inCAM);

	$inCAM->COM( "display_layer", "name" => $layer, "display" => "yes" );
	$inCAM->COM( 'work_layer', name => $layer );

}

# Display single layer from other step
sub DisplayFromOtherStep {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $offsetX = shift // 0;
	my $offsetY = shift // 0;

	$inCAM->COM(
				 'display_layer_from_other_step',
				 name     => $layer,
				 display  => 'yes',
				 oper     => '',
				 x_anchor => 0,
				 y_anchor => 0,
				 x_offset => $offsetX,
				 y_offset => $offsetY,
				 job      => $jobId,
				 step     => $step
	);

}

# Hide all layers and all layers are not affected
sub DisplayLayers {
	my $self   = shift;
	my $inCAM  = shift;
	my $layers = shift;

	$inCAM->COM('clear_layers');

	foreach my $l ( @{$layers} ) {
		$inCAM->COM( 'display_layer', "name" => "$l", "display" => "yes" );
	}
}

# Hide all layers and all layers are not affected
sub ClearLayers {
	my $self  = shift;
	my $inCAM = shift;

	$inCAM->COM('clear_layers');
	$inCAM->COM( 'affected_layer', mode => "all", affected => "no" );
}

# Affect layer in matrix
sub AffectLayers {
	my $self   = shift;
	my $inCAM  = shift;
	my $layers = shift;

	$inCAM->COM('clear_layers');
	$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "no" );

	foreach my $layer ( @{$layers} ) {

		#$inCAM->COM("display_layer","name" => $layer,"display" => "yes");
		$inCAM->COM( 'affected_layer', name => "$layer", mode => "single", affected => "yes" );

	}

}

# InvertPolarity of layer in some specified area
sub NegativeLayerData {
	my $self  = shift;
	my $inCAM = shift;
	my $layer = shift;
	my %dim   = %{ shift(@_) };

	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'misc', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );
	$self->WorkLayer( $inCAM, $lName );

	$inCAM->COM("add_surf_fill");
	$inCAM->COM( "add_surf_strt",      "surf_type" => "feature" );
	$inCAM->COM( "add_surf_poly_strt", "x"         => $dim{"xMin"}, "y" => $dim{"yMin"} );
	$inCAM->COM( "add_surf_poly_seg",  "x"         => $dim{"xMin"}, "y" => $dim{"yMax"} );
	$inCAM->COM( "add_surf_poly_seg",  "x"         => $dim{"xMax"}, "y" => $dim{"yMax"} );
	$inCAM->COM( "add_surf_poly_seg",  "x"         => $dim{"xMax"}, "y" => $dim{"yMin"} );
	$inCAM->COM( "add_surf_poly_seg",  "x"         => $dim{"xMin"}, "y" => $dim{"yMin"} );
	$inCAM->COM("add_surf_poly_end");
	$inCAM->COM( "add_surf_end", "polarity" => "positive", "attributes" => "no" );

	$self->WorkLayer( $inCAM, $layer );
	$inCAM->COM(
				 "sel_move_other",
				 "target_layer" => $lName,
				 "invert"       => "yes",
				 "dx"           => "0",
				 "dy"           => "0",
				 "size"         => "0",
				 "x_anchor"     => "0",
				 "y_anchor"     => "0"
	);

	$self->WorkLayer( $inCAM, $lName );
	$inCAM->COM(
				 "sel_move_other",
				 "target_layer" => $layer,
				 "invert"       => "no",
				 "dx"           => "0",
				 "dy"           => "0",
				 "size"         => "0",
				 "x_anchor"     => "0",
				 "y_anchor"     => "0"
	);

	$inCAM->COM( "delete_layer", "layer" => $lName );

	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );
}

# Return layer with filled rectangle defined by profile limits
sub FilledProfileLim {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $margin  = shift // 0;
	my $profLim = shift // { CamJob->GetProfileLimits2( $inCAM, $jobId, $step ) };

	my $lName = GeneralHelper->GetGUID();

	# Create full surface by profile
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	my @pointsLim = ();
	push( @pointsLim, { "x" => $profLim->{"xMin"}, "y" => $profLim->{"yMin"} } );
	push( @pointsLim, { "x" => $profLim->{"xMin"}, "y" => $profLim->{"yMax"} } );
	push( @pointsLim, { "x" => $profLim->{"xMax"}, "y" => $profLim->{"yMax"} } );
	push( @pointsLim, { "x" => $profLim->{"xMax"}, "y" => $profLim->{"yMin"} } );
	push( @pointsLim, { "x" => $profLim->{"xMin"}, "y" => $profLim->{"yMin"} } );    # last point = first point

	$self->WorkLayer( $inCAM, $lName );
	CamSymbolSurf->AddSurfacePolyline( $inCAM, \@pointsLim, 1, "positive" );

	$self->ResizeFeatures( $inCAM, $margin ) if ( $margin != 0 );

	return $lName;

}

# Clipa read data by  rectangle
sub ClipLayerData {
	my $self       = shift;
	my $inCAM      = shift;
	my $layer      = shift;
	my %rect       = %{ shift(@_) };
	my $inside     = shift;
	my $counturCut = shift;

	my $type = "outside";

	if ($inside) {
		$type = "inside";
	}

	my $countour = "no";

	if ($counturCut) {
		$countour = "yes";
	}

	$self->WorkLayer( $inCAM, $layer );

	$inCAM->COM( "clip_area_strt", );
	$inCAM->COM( "clip_area_xy", "x" => $rect{"xMin"}, "y" => $rect{"yMin"} );
	$inCAM->COM( "clip_area_xy", "x" => $rect{"xMax"}, "y" => $rect{"yMax"} );
	$inCAM->COM(
				 "clip_area_end",
				 "layers_mode" => "layer_name",
				 "layer"       => $layer,
				 "area"        => "manual",
				 "area_type"   => "rectangle",
				 "inout"       => $type,
				 "contour_cut" => $countour,
				 "margin"      => "0",
				 "feat_types"  => "line\;pad;surface;arc;text",
				 "pol_types"   => "positive\;negative"
	);

	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );
}

sub ClipAreaByProf {
	my $self       = shift;
	my $inCAM      = shift;
	my $layer      = shift;
	my $margin     = shift;
	my $inside     = shift;
	my $counturCut = shift;

	my $type = "outside";

	if ($inside) {
		$type = "inside";
	}

	my $countour = "no";

	if ($counturCut) {
		$countour = "yes";
	}

	$self->WorkLayer( $inCAM, $layer );

	$inCAM->COM(
				 "clip_area_end",
				 "layers_mode" => "layer_name",
				 "layer"       => $layer,
				 "area"        => "profile",
				 "area_type"   => "rectangle",
				 "inout"       => $type,
				 "contour_cut" => $countour,
				 "margin"      => $margin,
				 "feat_types"  => "line\;pad;surface;arc;text",
				 "pol_types"   => "positive\;negative"
	);

	$inCAM->COM( 'display_layer', name => $layer, display => 'no', number => '1' );

}

# Rotate layer by degree
# Right step must be open and set
# Requested data must be selected
# Default rotaion ic CW
sub RotateLayerData {
	my $self   = shift;
	my $inCAM  = shift;
	my $layer  = shift;
	my $degree = shift;
	my $ccw    = shift;

	my $dir = "cw";

	if ($ccw) {
		$dir = "ccw";
	}

	$self->WorkLayer( $inCAM, $layer );

	$inCAM->COM( "sel_transform", "oper" => "rotate", "angle" => $degree, "direction" => $dir );

	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );
}

# Mirror layer data by:
# a) by x OR y axis if defined $axis
# b) by anchor point if defined $anchor
# Right step must be open and set
# Requested data must be selected
sub MirrorLayerData {
	my $self   = shift;
	my $inCAM  = shift;
	my $layer  = shift;
	my $axis   = shift;    # x/y
	my $anchor = shift;    # hash ref with key: "x", "y"

	$self->WorkLayer( $inCAM, $layer );

	if ( defined $axis ) {

		if ( $axis eq "x" ) {

			$inCAM->COM( "sel_transform", "oper" => "mirror\;rotate", "angle" => 180 );

		}
		elsif ( $axis eq "y" ) {

			$inCAM->COM( "sel_transform", "oper" => "mirror" );

		}

	}
	elsif ( defined $anchor ) {

		$inCAM->COM( "sel_transform", "oper" => "mirror", "mode" => "anchor", "x_anchor" => $anchor->{"x"}, "y_anchor" => $anchor->{"y"} );
	}
	else {

		die "Axis or anchor point must be defined";
	}

	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );
}

# Scale data
# (only cooerdinates will be scaled at text and all symbols, Surface is completelz scaled)
# Right step must be open and set
# Requested data must be selected
sub StretchLayerData {
	my $self     = shift;
	my $inCAM    = shift;
	my $layer    = shift;
	my $stretchX = shift;    # stretch at x axis percent / 100 (e.g.: Stretch by 1%, parameter value = 1.01)
	my $stretchY = shift;    # stretch at y axis percent / 100 (e.g.: Stretch by 1%, parameter value = 1.01)
	my $originX  = shift;
	my $originY  = shift;

	$inCAM->COM(
				 "sel_transform",
				 "oper"     => "scale",
				 "x_scale"  => $stretchX,
				 "y_scale"  => $stretchY,
				 "x_anchor" => $originX,
				 "y_anchor" => $originY,
	);

	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );
}

# Do intersection between layers and return temp layer with result
sub LayerIntersection {
	my $self   = shift;
	my $inCAM  = shift;
	my $layer1 = shift;
	my $layer2 = shift;
	my $lim    = shift;    # area which is processed and result is only fro this area

	my $lTmp1 = GeneralHelper->GetGUID();
	my $lTmp2 = GeneralHelper->GetGUID();

	# prepare 1st layer
	$inCAM->COM( "merge_layers", "source_layer" => $layer1, "dest_layer" => $lTmp1 );

	$self->WorkLayer( $inCAM, $lTmp1 );
	$self->NegativeLayerData( $inCAM, $lTmp1, $lim );
	$self->Contourize( $inCAM, $lTmp1 );

	# copy 2nd layer
	$inCAM->COM( "merge_layers", "source_layer" => $layer2, "dest_layer" => $lTmp2 );

	# copy mask temp negati to cu temp
	$inCAM->COM( "merge_layers", "source_layer" => $lTmp1, "dest_layer" => $lTmp2, "invert" => "yes" );
	$inCAM->COM( "delete_layer", "layer" => $lTmp1 );

	$self->ClipLayerData( $inCAM, $lTmp2, $lim );

	return $lTmp2;

}

# Mirror data by profile center
sub MirrorLayerByProfCenter {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;
	my $axis  = shift;

	$self->WorkLayer( $inCAM, $layer );

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );

	my $w = abs( $lim{"xMax"} - $lim{"xMin"} );
	my $h = abs( $lim{"yMax"} - $lim{"yMin"} );

	my $centerX = $lim{"xMin"} + $w / 2;
	my $centerY = $lim{"yMin"} + $h / 2;

	if ( $axis eq "x" ) {

		$inCAM->COM( "sel_transform", "x_anchor" => $centerX, "y_anchor" => $centerY, "oper" => "mirror\;rotate", "angle" => 180 );

	}
	elsif ( $axis eq "y" ) {

		$inCAM->COM( "sel_transform", "x_anchor" => $centerX, "y_anchor" => $centerY, "oper" => "mirror" );

	}

	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );
}

# Move selected layer data. Snapp point is left down
# Right step must be open and set
# If nothing selected , move all in layer
sub MoveSelSameLayer {
	my $self        = shift;
	my $inCAM       = shift;
	my $layer       = shift;
	my $sourcePoint = shift;
	my $targetPoint = shift;

	my $x = -1 * $sourcePoint->{"x"} + $targetPoint->{"x"};
	my $y = -1 * $sourcePoint->{"y"} + $targetPoint->{"y"};

	$inCAM->COM( "sel_move", "dx" => $x, "dy" => $y );

	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );
}

# Return if, lyer is board type
sub LayerIsBoard {

	my $self      = shift;
	my $inCAM     = shift;
	my $jobName   = shift;
	my $layerName = shift;

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'matrix',
				  entity_path     => "$jobName/matrix",
				  data_type       => 'ROW',
				  parameters      => 'context+layer_type+name'
	);

	my @layers  = @{ $inCAM->{doinfo}{gROWname} };
	my @types   = @{ $inCAM->{doinfo}{gROWlayer_type} };
	my @context = @{ $inCAM->{doinfo}{gROWcontext} };

	my $idx = ( grep { $layerName eq $layers[$_] } 0 .. $#layers )[0];

	if ( defined $idx ) {

		my $con = $context[$idx];

		if ( $con eq "board" ) {
			return 1;
		}
	}

	return 0;
}

# Compensate layer data by compensation
sub CompensateLayerData {
	my $self    = shift;
	my $inCAM   = shift;
	my $layer   = shift;
	my $compVal = shift;    # µm

	$self->WorkLayer( $inCAM, $layer );

	# resize all positive
	$inCAM->COM( "reset_filter_criteria", "filter_name" => "", "criteria" => "all" );
	$inCAM->COM( "set_filter_polarity", "filter_name" => "", "positive" => "yes", "negative" => "no" );
	$inCAM->COM("filter_area_strt");
	$inCAM->COM( "filter_area_end", "filter_name" => "popup", "operation" => "select" );
	$inCAM->COM('get_select_count');

	if ( $inCAM->GetReply() > 0 ) {
		$inCAM->COM( "sel_resize", "size" => $compVal, "corner_ctl" => "no" );
		$inCAM->COM("sel_clear_feat");
	}

	# resize all negative by oposite value of comp
	$inCAM->COM( "reset_filter_criteria", "filter_name" => "", "criteria" => "all" );
	$inCAM->COM( "set_filter_polarity", "filter_name" => "", "positive" => "no", "negative" => "yes" );
	$inCAM->COM("filter_area_strt");
	$inCAM->COM( "filter_area_end", "filter_name" => "popup", "operation" => "select" );
	$inCAM->COM('get_select_count');

	if ( $inCAM->GetReply() > 0 ) {
		$inCAM->COM( "sel_resize", "size" => ( -1 * $compVal ), "corner_ctl" => "no" );
		$inCAM->COM("sel_clear_feat");
	}

	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );

}

# Compensate NC layer
sub RoutCompensation {
	my $self  = shift;
	my $inCAM = shift;
	my $layer = shift;
	my $type  = shift;    # rout/document

	unless ( defined $type ) {

		$type = "rout";
	}

	my $lName = GeneralHelper->GetNumUID();
	$self->WorkLayer( $inCAM, $layer );

	$inCAM->COM( "compensate_layer", "source_layer" => $layer, "dest_layer" => $lName,   "dest_layer_type" => $type );
	$inCAM->COM( 'affected_layer',   name           => $layer, mode         => "single", affected          => "no" );

	return $lName;
}

# Countourize given layer
sub Contourize {
	my $self            = shift;
	my $inCAM           = shift;
	my $layer           = shift;
	my $clean_hole_mode = shift;    # "x_or_y", "area", "x_and_y"
	my $clean_hole_size = shift;

	unless ( defined $clean_hole_mode ) {
		$clean_hole_mode = "x_or_y";
	}

	unless ( defined $clean_hole_size ) {
		$clean_hole_size = "76.2";
	}

	$self->WorkLayer( $inCAM, $layer );

	$inCAM->COM(
				 "sel_contourize",
				 "accuracy"         => "6.35",
				 "break_to_islands" => "yes",
				 "clean_hole_size"  => $clean_hole_size,
				 "clean_hole_mode"  => $clean_hole_mode
	);

	$self->ClearLayers($inCAM);
}

# Copy selected features to other layer
sub CopySelOtherLayer {
	my $self   = shift;
	my $inCAM  = shift;
	my @layers = @{ shift(@_) };
	my $invert = shift;
	my $resize = shift;

	my $layerStr = join( "\\;", @layers );

	$inCAM->COM(
				 "sel_copy_other",
				 "dest"         => "layer_name",
				 "target_layer" => $layerStr,
				 "invert"       => $invert ? "yes" : "no",
				 "dx"           => "0",
				 "dy"           => "0",
				 "size"         => $resize ? $resize : 0,
				 "x_anchor"     => "0",
				 "y_anchor"     => "0 "
	);

}

# Move selected features to other layer
sub MoveSelOtherLayer {
	my $self   = shift;
	my $inCAM  = shift;
	my $layer  = shift;
	my $invert = shift;
	my $resize = shift;

	$inCAM->COM(
				 "sel_move_other",
				 "target_layer" => $layer,
				 "invert"       => $invert ? "yes" : "no",
				 "dx"           => "0",
				 "dy"           => "0",
				 "size"         => $resize ? $resize : 0,
				 "x_anchor"     => "0",
				 "y_anchor"     => "0 "
	);

}

# Do omptimiyation of levels
# remove data from original layer and put new oprimiyed data back to ori layer
sub OptimizeLevels {
	my $self       = shift;
	my $inCAM      = shift;
	my $layer      = shift;
	my $levelCount = shift;

	unless ($levelCount) {
		die "no level count defined";
	}

	my $lName = GeneralHelper->GetGUID();

	$inCAM->COM( "optimize_levels", "layer" => $layer, "opt_layer" => $lName, "levels" => $levelCount );

	$self->WorkLayer( $inCAM, $layer );
	$inCAM->COM('sel_delete');
	$self->WorkLayer( $inCAM, $lName );

	$inCAM->COM(
				 "sel_copy_other",
				 "dest"         => "layer_name",
				 "target_layer" => $layer,
				 "invert"       => "no"
	);
	$inCAM->COM( 'delete_layer', layer => $lName );

}

# Delete selected feature, if no selected, delete all
sub DeleteFeatures {
	my $self  = shift;
	my $inCAM = shift;

	$inCAM->COM("sel_delete");
}

# Do simple resize of selected/all(if not selected any) features
sub ResizeFeatures {
	my $self  = shift;
	my $inCAM = shift;
	my $val   = shift;

	$inCAM->COM( "sel_resize", "size" => $val, "corner_ctl" => "no" );
}

# Return number
sub GetSelFeaturesCnt {
	my $self  = shift;
	my $inCAM = shift;

	$inCAM->COM('get_select_count');

	return $inCAM->GetReply();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamLayer';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d113608";

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "o+1" );

	CamLayer->NegativeLayerData( $inCAM, "v3_", \%lim );

}

1;

1;
