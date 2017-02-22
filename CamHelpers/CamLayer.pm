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
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamStepRepeat';


#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Return hash, kyes are "top"/"bot", values are 0/1
sub ExistSolderMasks {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my %masks = HegMethods->GetSolderMaskColor($jobId);

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
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my %silk = HegMethods->GetSilkScreenColor($jobId);

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

	# 2)  if rout layer, change to drill, in other hand user column will not be considered (InCAM BUG)
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
	for ( my $count = 0 ; $count <= $totalRows ; $count++ ) {
		my $rowName    = ${ $inCAM->{doinfo}{gROWname} }[$count];
		my $rowContext = ${ $inCAM->{doinfo}{gROWcontext} }[$count];

		if ( $rowContext eq "misc" ) {
			if ( $rowName =~ /\+\+\+/g ) {
				$inCAM->COM( 'delete_layer', layer => "$rowName" );
			}
		}
	}
}

#Return layers, where marking can be placed
sub GetMarkingLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @arr = CamJob->GetBoardLayers( $inCAM, $jobId );

	my @res = ();

	foreach my $l (@arr) {

		if (    $l->{"gROWlayer_type"} =~ /solder_mask/i
			 || $l->{"gROWlayer_type"} =~ /silk_screen/i
			 || ( $l->{"gROWlayer_type"} =~ /signal/i && $l->{"gROWname"} !~ /v/i ) )
		{
			push( @res, $l );
		}
	}

	return @res;
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

# Display single layer and set as work layer
sub WorkLayer {
	my $self  = shift;
	my $inCAM = shift;
	my $layer = shift;

	$self->ClearLayers($inCAM);

	$inCAM->COM( "display_layer", "name" => $layer, "display" => "yes" );
	$inCAM->COM( 'work_layer', name => $layer );

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
	my $margin 	   = shift;
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
	
	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );
	
}

# Rotate layer by degree
# Right step must be open and set
# Requested data must be selected
sub RotateLayerData {
	my $self   = shift;
	my $inCAM  = shift;
	my $layer  = shift;
	my $degree = shift;

	$self->WorkLayer( $inCAM, $layer );

	$inCAM->COM( "sel_transform", "oper" => "rotate", "angle" => $degree );

	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );
}

# Mirror layer by x OR y
# Right step must be open and set
# Requested data must be selected
sub MirrorLayerData {
	my $self  = shift;
	my $inCAM = shift;
	my $layer = shift;
	my $axis  = shift;

	$self->WorkLayer( $inCAM, $layer );

	if ( $axis eq "x" ) {

		$inCAM->COM( "sel_transform", "oper" => "mirror\;rotate", "angle" => 180 );

	}
	elsif ( $axis eq "y" ) {

		$inCAM->COM( "sel_transform", "oper" => "mirror" );

	}
	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );
}

# Move layer data. Snapp point is left down
# Right step must be open and set
sub MoveLayerData {
	my $self        = shift;
	my $inCAM       = shift;
	my $layer       = shift;
	my $sourcePoint = shift;
	my $targetPoint = shift;

	my $x = -1 * $sourcePoint->{"x"} + $targetPoint->{"x"};
	my $y = -1 * $sourcePoint->{"y"} + $targetPoint->{"y"};

	$self->WorkLayer( $inCAM, $layer );

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
	$inCAM->COM( "filter_area_end", "filter_name" => "popup",  "operation"  => "select" );
	$inCAM->COM( "sel_resize",      "size"        => $compVal, "corner_ctl" => "no" );
	$inCAM->COM("sel_clear_feat");

	# resize all negative by oposite value of comp
	$inCAM->COM( "reset_filter_criteria", "filter_name" => "", "criteria" => "all" );
	$inCAM->COM( "set_filter_polarity", "filter_name" => "", "positive" => "no", "negative" => "yes" );
	$inCAM->COM("filter_area_strt");
	$inCAM->COM( "filter_area_end", "filter_name" => "popup",           "operation"  => "select" );
	$inCAM->COM( "sel_resize",      "size"        => ( -1 * $compVal ), "corner_ctl" => "no" );
	$inCAM->COM("sel_clear_feat");

	$inCAM->COM( 'affected_layer', name => $layer, mode => "single", affected => "no" );

}

# InvertPolarity of layer
sub RoutCompensation {
	my $self  = shift;
	my $inCAM = shift;
	my $layer = shift;
	my $type  = shift;

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
	my $self  = shift;
	my $inCAM = shift;
	my $layer = shift;

	$self->WorkLayer( $inCAM, $layer );

	$inCAM->COM( "sel_contourize", "accuracy" => "6.35", "break_to_islands" => "yes", "clean_hole_size" => "76.2", "clean_hole_mode" => "x_or_y" );

	$self->ClearLayers($inCAM);
}

# Copy selected features to other layer
sub CopySelected {
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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	my $jobName   = "f13610";
	my $layerName = "fsch";

	use aliased 'CamHelpers::CamLayer';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $res = CamLayer->LayerIsBoard( $inCAM, $jobName, $layerName );

	print $res;

}

1;

1;
