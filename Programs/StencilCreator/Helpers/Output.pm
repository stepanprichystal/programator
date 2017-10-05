
#-------------------------------------------------------------------------------------------#
# Description: Prepare stencil layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Helpers::Output;

#3th party library
use threads;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Programs::StencilCreator::Helpers::DataHelper';
use aliased 'Programs::StencilCreator::Enums';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Programs::StencilCreator::Helpers::Helper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsDrill';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"dataMngr"}    = shift;
	$self->{"stencilMngr"} = shift;

	my %inf = Helper->GetStencilInfo( $self->{"jobId"} );
	$self->{"stencilInfo"} = \%inf;

	# PROPERTIES
	$self->{"stencilStep"} = "o+1";
	$self->{"finalLayer"} = $self->{"stencilInfo"}->{"tech"} eq Enums->Technology_DRILL ? "f" : "ds";

	return $self;
}

sub PrepareLayer {
	my $self = shift;

	my %layers = $self->__PrepareOriLayers();

	$self->__PrepareFinalSteps();
	$self->__PrepareFinalLayer( \%layers );
	$self->__PrepareSchema();
	$self->__PreparePcbNumber();

}

# Prepare source paste layers in ori step
sub __PrepareOriLayers {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilMngr"};

	my $step = $self->{"dataMngr"}->GetStencilStep();
	CamHelper->SetStep( $self->{"inCAM"}, $step );
	my $srExist = CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $step );

	my %layers = ();

	if ( $dataMngr->GetStencilType() eq Enums->StencilType_TOP ) {

		my %inf = ( "ori" => Helper->GetStencilOriLayer( $inCAM, $jobId, "top" )->{"gROWname"}, "prepared" => GeneralHelper->GetGUID() );
		$layers{"top"} = \%inf;

	}
	elsif ( $dataMngr->GetStencilType() eq Enums->StencilType_BOT ) {

		my %inf = ( "ori" => Helper->GetStencilOriLayer( $inCAM, $jobId, "bot" )->{"gROWname"}, "prepared" => GeneralHelper->GetGUID() );
		$layers{"bot"} = \%inf;
	}
	elsif ( $dataMngr->GetStencilType() eq Enums->StencilType_TOPBOT ) {

		my %inf = ( "ori" => Helper->GetStencilOriLayer( $inCAM, $jobId, "top" )->{"gROWname"}, "prepared" => GeneralHelper->GetGUID() );
		$layers{"top"} = \%inf;
		my %inf2 = ( "ori" => Helper->GetStencilOriLayer( $inCAM, $jobId, "bot" )->{"gROWname"}, "prepared" => GeneralHelper->GetGUID() );
		$layers{"bot"} = \%inf2;
	}

	# prepare

	foreach my $lType ( keys %layers ) {

		my $oriLayer = $layers{$lType}->{"ori"};
		my $prepared = $layers{$lType}->{"prepared"};

		my $pcbProf = $lType eq "top" ? $stencilMngr->GetTopProfile() : $stencilMngr->GetBotProfile();

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

		# 3) mirror layer by y axis profile
		if ( $dataMngr->GetStencilType() eq Enums->StencilType_TOPBOT && $lType eq "bot" ) {

			CamLayer->MirrorLayerByProfCenter( $inCAM, $jobId, $step, $prepared, "y" );
		}

		# 4) Rotate data 90° CW
		if ( $pcbProf->GetIsRotated() ) {

			CamLayer->RotateLayerData( $inCAM, $prepared, 90 );    # rotated about left-down corner CCW
			my %source = ( "x" => 0, "y" => 0 );
			my %target = ( "x" => 0, "y" => $pcbProf->GetHeight() );    # move to zero again
			CamLayer->MoveLayerData( $inCAM, $prepared, \%source, \%target );
		}

	}

	return %layers;

}

# Create o+1 and panel step
sub __PrepareFinalSteps {
	my $self = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $dataMngr = $self->{"dataMngr"};

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

	$inCAM->COM( "profile_rect", "x1" => "0", "y1" => "0", "x2" => $dataMngr->GetStencilSizeX(), "y2" => $dataMngr->GetStencilSizeY() );

	# 2) crate panel
	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => "panel", "type" => "step" );
	}

	my $panel = SRStep->new( $inCAM, $jobId, "panel" );
	$panel->Create( $dataMngr->GetStencilSizeX(), $dataMngr->GetStencilSizeY(), 0, 0, 0, 0 );
	$panel->AddSRStep( $self->{"stencilStep"}, 0, 0, 0, 1, 1, 0, 0 );

	CamHelper->SetStep( $inCAM, $self->{"stencilStep"} );

}

# Create final stencil layer intended for export ("ds" or "f")
sub __PrepareFinalLayer {
	my $self   = shift;
	my %layers = %{ shift(@_) };

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilMngr"};
	my $step        = $self->{"dataMngr"}->GetStencilStep();

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

		my %dataPos = $lType eq "top" ? $stencilMngr->GetTopProfilePos() : $stencilMngr->GetBotProfilePos();

		$inCAM->COM(
			"sel_copy_other",
			"dest"         => "layer_name",
			"target_layer" => $self->{"finalLayer"},
			"dx"           => $dataPos{"x"},
			"dy"           => $dataPos{"y"},

		);

		$inCAM->COM( 'delete_layer', layer => $prepared );

		#if type is drilled, set DTM type "vrtane"
		if ( $self->{"stencilInfo"}->{"tech"} eq Enums->Technology_DRILL ) {
	 
			CamDTM->SetDTMTable( $inCAM, $jobId, $self->{"stencilStep"}, $self->{"finalLayer"}, EnumsDrill->DTM_VRTANE );
		}
	}

}

sub __PrepareSchema {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilMngr"};
	my $schType     = $dataMngr->GetSchemaType();

	CamLayer->WorkLayer( $inCAM, $self->{"finalLayer"} );

	# Standard schema with holes
	if ( $schType eq Enums->Schema_STANDARD ) {

		my $d = $self->{"dataMngr"}->GetHoleSize();

		foreach ( $stencilMngr->GetSchema()->GetHolePositions() ) {

			CamSymbol->AddPad( $inCAM, "r" . $d * 1000, $_ );
		}

	}

	# vlepeni do ramu
	elsif ( $schType eq Enums->Schema_FRAME ) {

		my %area = $stencilMngr->GetStencilActiveArea();

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
					 "step_max_dist_x"         => ( $dataMngr->GetStencilSizeX() - $area{"w"} ) / 2,
					 "step_max_dist_y"         => ( $dataMngr->GetStencilSizeY() - $area{"h"} ) / 2,
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
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $dataMngr    = $self->{"dataMngr"};
	my $stencilMngr = $self->{"stencilMngr"};
	my $schType     = $dataMngr->GetSchemaType();

	if ( $dataMngr->GetAddPcbNumber() ) {

		CamLayer->WorkLayer( $inCAM, $self->{"finalLayer"} );

		my $mirror = 0;
		my %pos = ( "x" => 20, "y" => 2.8 );

		if ( $dataMngr->GetStencilType() eq Enums->StencilType_BOT ) {

			$mirror = 1;
			$pos{"x"} = $dataMngr->GetStencilSizeX() - 20;    # 30 is length of mirrored pcbid text
		}

		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".string", "pcbid" );

		CamSymbol->AddText( $inCAM, uc($jobId), \%pos, 5.08, 2, $mirror );

		CamSymbol->ResetCurAttributes($inCAM);

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
