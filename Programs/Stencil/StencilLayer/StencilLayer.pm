
#-------------------------------------------------------------------------------------------#
# Description: Prepare stencil layer, based on stencil parametrs from StencilCreator app
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Stencil::StencilLayer::StencilLayer;

#3th party library
use threads;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::Stencil::StencilCreator::Helpers::DataHelper';
use aliased 'Programs::Stencil::StencilCreator::Enums';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsDrill';
use aliased 'Programs::Stencil::StencilSerializer::StencilParams';
use aliased 'Programs::Stencil::StencilSerializer::StencilSerializer';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}         = shift;
	$self->{"jobId"}         = shift;
	$self->{"stencilParams"} = shift;    # stencil params
	$self->{"finalLayer"}    = shift;

	my %inf = Helper->GetStencilInfo( $self->{"jobId"} );
	$self->{"stencilInfo"} = \%inf;

	# PROPERTIES
	$self->{"stencilStep"} = "o+1";
	$self->{"finalLayer"} = $self->{"stencilInfo"}->{"tech"} eq Enums->Technology_DRILL ? "flc" : "ds"
	  unless ( defined $self->{"finalLayer"} );

	return $self;
}

# Create o+1 and panel step
sub PrepareSteps {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $par   = $self->{"stencilParams"};

	# 1) Create steps  o+1

	if ( CamHelper->StepExists( $inCAM, $jobId, $self->{"stencilStep"} ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $self->{"stencilStep"}, "type" => "step" );
	}

	$inCAM->COM(
				 'create_entity',
				 "job"     => $jobId,
				 "name"    => $self->{"stencilStep"},
				 "db"      => "",
				 "is_fw"   => 'no',
				 "type"    => 'step',
				 "fw_type" => 'form'
	);

	CamHelper->SetStep( $inCAM, $self->{"stencilStep"} );

	$inCAM->COM( "profile_rect", "x1" => "0", "y1" => "0", "x2" => $par->GetStencilSizeX(), "y2" => $par->GetStencilSizeY() );

	# 2) crate panel
	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => "panel", "type" => "step" );
	}

	my $panel = SRStep->new( $inCAM, $jobId, "panel" );
	$panel->Create( $par->GetStencilSizeX(), $par->GetStencilSizeY(), 0, 0, 0, 0 );
	$panel->AddSRStep( $self->{"stencilStep"}, 0, 0, 0, 1, 1, 0, 0 );

	

}


sub PrepareLayer {
	my $self = shift;

	my %layers = $self->__PrepareOriLayers();
 
	$self->__PrepareFinalLayer( \%layers );
	$self->__PrepareSchema();
	$self->__PreparePcbNumber();

}

# Prepare source paste layers in ori step
sub __PrepareOriLayers {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $par   = $self->{"stencilParams"};

	my $step = $par->GetStencilStep();
	CamHelper->SetStep( $self->{"inCAM"}, $step );
	my $srExist = CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $step );

	my %layers = ();

	if ( $par->GetStencilType() eq Enums->StencilType_TOP ) {

		my %inf = ( "ori" => Helper->GetStencilOriLayer( $inCAM, $jobId, "top" )->{"gROWname"}, "prepared" => GeneralHelper->GetGUID() );
		$layers{"top"} = \%inf;

	}
	elsif ( $par->GetStencilType() eq Enums->StencilType_BOT ) {

		my %inf = ( "ori" => Helper->GetStencilOriLayer( $inCAM, $jobId, "bot" )->{"gROWname"}, "prepared" => GeneralHelper->GetGUID() );
		$layers{"bot"} = \%inf;
	}
	elsif ( $par->GetStencilType() eq Enums->StencilType_TOPBOT ) {

		my %inf = ( "ori" => Helper->GetStencilOriLayer( $inCAM, $jobId, "top" )->{"gROWname"}, "prepared" => GeneralHelper->GetGUID() );
		$layers{"top"} = \%inf;
		my %inf2 = ( "ori" => Helper->GetStencilOriLayer( $inCAM, $jobId, "bot" )->{"gROWname"}, "prepared" => GeneralHelper->GetGUID() );
		$layers{"bot"} = \%inf2;
	}

	# prepare

	foreach my $lType ( keys %layers ) {

		my $oriLayer = $layers{$lType}->{"ori"};
		my $prepared = $layers{$lType}->{"prepared"};

		my $pcbProf = $lType eq "top" ? $par->GetTopProfile() : $par->GetBotProfile();

		# 1) flatten layer in needed
		if ($srExist) {
			$inCAM->COM( 'flatten_layer', "source_layer" => $oriLayer, "target_layer" => $prepared );

		}
		else {

			# only copy to targer layer
			$inCAM->COM( "merge_layers", "source_layer" => $oriLayer, "dest_layer" => $prepared );
		}

		# 2) Move to zero, test if left down corner is in zero
		CamLayer->WorkLayer( $inCAM, $prepared );

		# 3) mirror layer by y axis profile
		if ( $par->GetStencilType() eq Enums->StencilType_TOPBOT && $lType eq "bot" ) {

			CamLayer->MirrorLayerByProfCenter( $inCAM, $jobId, $step, $prepared, "y" );
			CamLayer->WorkLayer( $inCAM, $prepared );
		}

		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step, 1 );

		if ( int( $lim{"xMin"} ) != 0 || int( $lim{"yMin"} ) != 0 ) {

			# move to zero
			$inCAM->COM(
						 "sel_transform",
						 "oper"      => "",
						 "x_anchor"  => "0",
						 "y_anchor"  => "0",
						 "angle"     => "0",
						 "direction" => "ccw",
						 "x_scale"   => "1",
						 "y_scale"   => "1",
						 "x_offset"  => -$lim{"xMin"},
						 "y_offset"  => -$lim{"yMin"},
						 "mode"      => "anchor",
						 "duplicate" => "no"
			);

		}

		# 4) Rotate data 90? CW
		if ( $pcbProf->{"isRotated"} ) {

			CamLayer->RotateLayerData( $inCAM, $prepared, 90 );    # rotated about left-down corner CCW
			my %source = ( "x" => 0, "y" => 0 );
			my %target = ( "x" => 0, "y" => $pcbProf->{"h"} );     # move to zero again
			CamLayer->WorkLayer( $inCAM, $prepared );
			CamLayer->MoveSelSameLayer( $inCAM, $prepared, \%source, \%target );
		}

	}

	return %layers;

}


# Create final stencil layer intended for export ("ds" or "f")
sub __PrepareFinalLayer {
	my $self   = shift;
	my %layers = %{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $par   = $self->{"stencilParams"};
	my $step  = $par->GetStencilStep();
	
	

	# 1) Create final layer
	my $type = 'document';
	if ( $self->{"stencilInfo"}->{"tech"} eq Enums->Technology_DRILL ) {
		$type = "rout";
	}

	if ( CamHelper->LayerExists( $inCAM, $jobId, $self->{"finalLayer"} ) ) {

		$inCAM->COM( 'delete_layer', "layer" => $self->{"finalLayer"} );
	}

	$inCAM->COM( 'create_layer', layer => $self->{"finalLayer"}, context => 'board', type => $type, polarity => 'positive', ins_layer => '' );

	# 2) copy prepared data to layer
	CamHelper->SetStep( $inCAM, $self->{"stencilStep"} );
	
	foreach my $lType ( keys %layers ) {

		my $oriLayer = $layers{$lType}->{"ori"};
		my $prepared = $layers{$lType}->{"prepared"};

		# copy to final step

		$inCAM->COM(
			"copy_layer",
			"dest"         => "layer_name",
			"source_job"   => $jobId,
			"source_step"  => $step,
			"source_layer" => $prepared,

			"dest_step"  => $self->{"stencilStep"},
			"dest_layer" => $prepared,
			"mode"       => "append",
			"invert"     => "no"
		);

		# copy data to final layer
		CamLayer->WorkLayer( $inCAM, $prepared );

		my $dataPos = $lType eq "top" ? $par->GetTopProfilePos() : $par->GetBotProfilePos();

		$inCAM->COM(
			"sel_copy_other",
			"dest"         => "layer_name",
			"target_layer" => $self->{"finalLayer"},
			"dx"           => $dataPos->{"x"},
			"dy"           => $dataPos->{"y"},

		);

		$inCAM->COM( 'delete_layer', layer => $prepared );

	}

	$self->__CreatePads( $self->{"finalLayer"} );

	# if drilled stencil, recompute drill tools
	if ( $self->{"stencilInfo"}->{"tech"} eq Enums->Technology_DRILL ) {
		$self->__RecomputeTools();
	}

}

sub __PrepareSchema {
	my $self = shift;

	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};
	my $par     = $self->{"stencilParams"};
	my $schema  = $par->GetSchema();
	my $schType = $schema->{"type"};

	CamLayer->WorkLayer( $inCAM, $self->{"finalLayer"} );

	# Standard schema with holes
	if ( $schType eq Enums->Schema_STANDARD ) {

		my $d = $schema->{"holeSize"};

		foreach ( @{ $schema->{"holePositions"} } ) {

			CamSymbol->AddPad( $inCAM, "r" . $d * 1000, $_ );
		}

	}

	# vlepeni do ramu
	elsif ( $schType eq Enums->Schema_FRAME ) {

		my $area = $par->GetStencilActiveArea();

		$inCAM->COM(
					 "sr_fill",
					 "type"                    => "predefined_pattern",
					 "predefined_pattern_type" => "dots",
					 "indentation"             => "odd",
					 "dots_shape"              => "circle",
					 "dots_diameter"           => "2000",
					 "dots_grid"               => "2800",
					 "step_margin_x"           => "6",
					 "step_margin_y"           => "11",
					 "step_max_dist_x"         => ( $par->GetStencilSizeX() - $area->{"w"} ) / 2,
					 "step_max_dist_y"         => ( $par->GetStencilSizeY() - $area->{"h"} ) / 2,
					 "consider_feat"           => "no",
					 "feat_margin"             => "20",
					 "dest"                    => "layer_name",
					 "layer"                   => $self->{"finalLayer"}
		);

	}

	# do not add anything
	elsif ( $schType eq Enums->Schema_INCLUDED ) {

	}
}

sub __PreparePcbNumber {
	my $self  = shift;
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $par   = $self->{"stencilParams"};

	if ( $par->GetAddPcbNumber() ) {

		CamLayer->WorkLayer( $inCAM, $self->{"finalLayer"} );

		my $mirror = 0;
		my %pos = ( "x" => 20, "y" => 2.8 );

		if ( $par->GetStencilType() eq Enums->StencilType_BOT ) {

			$mirror = 1;
			$pos{"x"} = $par->GetStencilSizeX() - 20;    # 30 is length of mirrored pcbid text
		}

		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", "pcbid" );

		CamSymbol->AddText( $inCAM, uc($jobId), \%pos, 5.08, undef, 2, $mirror );

		CamSymbol->ResetCurAttributes($inCAM);
	}
}

# If some pad is surface or line, create pad from him
sub __CreatePads {
	my $self  = shift;
	my $lName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"stencilStep"};

	CamLayer->WorkLayer( $inCAM, $lName );
	$inCAM->COM('sel_break');
	$inCAM->COM( 'sel_contourize', "accuracy" => '6.35', "break_to_islands" => 'yes', "clean_hole_size" => '60', "clean_hole_mode" => 'x_and_y' );

	# due to InCAM Bug do break and counturization again - workaround from Orbotech
	# (sometimes InCAM create one big surface - no island)
	$inCAM->COM( 'sel_contourize', "accuracy" => '6.35', "break_to_islands" => 'yes', "clean_hole_size" => '60', "clean_hole_mode" => 'x_and_y' );
	$inCAM->COM( 'sel_decompose', "overlap" => "no" );

	$inCAM->COM( 'sel_cont2pad', "match_tol" => '25.4', "restriction" => '', "min_size" => '127', "max_size" => '12000' );

	# test on  lines presence
	my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $lName );
	if ( $fHist{"line"} > 0 || $fHist{"arc"} > 0 ) {

		die "Error during convert featrues to apds. Layer ("
		  . $self->{"workLayer"}
		  . ") can't contain line and arcs. Only pad and surfaces are alowed.";
	}

	# check error on surfaces
	if ( $fHist{"surf"} == 1 && $fHist{"pad"} == 0 ) {
		die "Error during creating pads in stencil";
	}

}

sub __RecomputeTools {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"stencilStep"};
	my $lName = $self->{"finalLayer"};

	my @tools = CamDTM->GetDTMTools( $inCAM, $jobId, $step, $lName );

	my $DTMType = CamDTM->GetDTMType( $inCAM, $jobId, $step, $lName );

	# Set finish size same as drill size
	foreach my $t (@tools) {

		$t->{"gTOOLfinish_size"} = $t->{"gTOOLdrill_size"};
	}

	# 3) Set new values to DTM
	CamDTM->SetDTMTools( $inCAM, $jobId, $step, $lName, \@tools );

	CamDTM->RecalcDTMTools( $inCAM, $jobId, $self->{"stencilStep"}, $self->{"finalLayer"}, EnumsDrill->DTM_VRTANE );

	 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
