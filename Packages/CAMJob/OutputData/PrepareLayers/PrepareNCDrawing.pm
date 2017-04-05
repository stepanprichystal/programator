
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers which contains tool depth drawing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::PrepareLayers::PrepareNCDrawing;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use Math::Trig;
use Math::Geometry::Planar;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::OutputData::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputData::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAMJob::OutputData::Drawing::Drawing';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Enums::EnumsDrill';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamSymbol';

#use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"step"}      = shift;
	$self->{"layerList"} = shift;

	$self->{"profileLim"} = shift;    # limits of pdf step

	$self->{"pcbThick"} = JobHelper->GetFinalPcbThick( $self->{"jobId"} ) / 1000;    # in mm

	return $self;
}

sub Prepare {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	@layers = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot
	} @layers;

	foreach my $l (@layers) {

		# load UniDTM for layer
		$l->{"uniDTM"} = UniDTM->new( $inCAM, $jobId, $step, $l->{"gROWname"}, 1 );

		# check if depths are ok
		my $mess = "";
		unless ( $l->{"uniDTM"}->GetChecks()->CheckToolDepthSet( \$mess ) ) {
			die $mess;
		}

		$self->__ProcessNClayer( $l, $type );

	}

}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __ProcessNClayer {
	my $self = shift;
	my $l    = shift;
	my $type = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my @allTools = $l->{"uniDTM"}->GetTools();

	my $enTit = ValueConvertor->GetJobLayerTitle($l);
	my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
	my $enInf = ValueConvertor->GetJobLayerInfo($l);
	my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

	my $drawingPos = Point->new( 0, abs( $self->{"profileLim"}->{"yMax"} - $self->{"profileLim"}->{"yMin"} ) + 50 );    # starts 150

	#my %lines_arcs = %{ $l->{"symHist"}->{"lines_arcs"} };
	#my %pads       = %{ $l->{"symHist"}->{"pads"} };

	# Get if NC operation is from top/bot
	my $side = $l->{"gROWname"} =~ /c/ ? "top" : "bot";

	# 1) Proces slots (lines + arcs)

	my @lines_arcs = grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN && $_->GetSource() eq DTMEnums->Source_DTM } @allTools;

	foreach my $t (@lines_arcs) {

		my $depth = $t->GetDepth();
		my $lName = $self->__SeparateSymbol( $l, $t );

		# if features was selected, continue next
		unless ($lName) {
			next;
		}

		my $draw = Drawing->new( $inCAM, $jobId, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );

		my $toolSize = $t->GetDrillSize();

		# Test on special countersink tool
		if (  $t->GetSpecial() && defined $t->GetAngle() && $t->GetAngle() > 0 ) {

			# if slot/hole is plated, finial depth will be smaller -100µm
			if ( $l->{"plated"} ) {
				$depth -= 0.1;
			}

			#compute real milled hole/line diameter
			my $angle      = $t->GetAngle();
			my $newDiamter = ( tan( deg2rad( $angle / 2 ) ) * $depth * 2 ) * 1000;

			# change all symbols in layer to this new diameter
			CamLayer->WorkLayer( $inCAM, $lName );
			$inCAM->COM( "sel_change_sym", "symbol" => "r" . $newDiamter, "reset_angle" => "no" );

			$draw->Create( Enums->Depth_COUNTERSINK, Enums->Symbol_SLOT, $toolSize / 1000, $depth, $angle );

		}
		else {
			$draw->Create( Enums->Depth_ZAXIS, Enums->Symbol_SLOT, $toolSize / 1000, $depth );
		}

		# Add anew layerData to datalist

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );
		$self->{"layerList"}->AddLayer($lData);

	}

	# 2) Proces holes ( pads )

	my @pads = grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_HOLE && $_->GetSource() eq DTMEnums->Source_DTM } @allTools;

	foreach my $t ( @pads ) {

		my $toolSize = $t->GetDrillSize();

		my $depth = $t->GetDepth();
		my $lName = $self->__SeparateSymbol( $l, $t );

		# if features was selected, continue next
		unless ($lName) {
			next;
		}

		my $draw = Drawing->new( $inCAM, $jobId, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );

		# Test on special countersink tool
		if (  $t->GetSpecial() && defined $t->GetAngle() && $t->GetAngle() > 0 ) {

			# if slot/hole is plated, finial depth will be smaller -100µm
			if ( $l->{"plated"} ) {
				$depth -= 0.1;
			}

			#compute real milled hole/line diameter
			my $angle      = $t->GetAngle();
			my $newDiamter = ( tan( deg2rad( $angle / 2 ) ) * $depth * 2 ) * 1000;

			# change all symbols in layer to this new diameter
			CamLayer->WorkLayer( $inCAM, $lName );
			$inCAM->COM( "sel_change_sym", "symbol" => "r" . $newDiamter, "reset_angle" => "no" );

			$draw->Create( Enums->Depth_COUNTERSINK, Enums->Symbol_HOLE, $toolSize / 1000, $depth, $angle );

		}
		else {
			$draw->Create( Enums->Depth_ZAXIS, Enums->Symbol_HOLE, $toolSize / 1000, $depth );
		}

		# Add anew layerData to datalist

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );
		$self->{"layerList"}->AddLayer($lData);

	}

	# 3) Process surfaces

	my @surfaces = grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN && $_->GetSource() eq DTMEnums->Source_DTMSURF } @allTools;

	foreach my $t ( @surfaces ) {

		my $toolSize = $t->GetDrillSize();

		my $depth = $t->GetDepth();
		my $lName = $self->__SeparateSymbol( $l, $t );

		# if features was selected, continue next
		unless ($lName) {
			next;
		}

		# if surface is plated, finial depth will be smaller -100µm
		if ( $l->{"plated"} ) {
			$depth -= 0.1;
		}

		my $draw = Drawing->new( $inCAM, $jobId, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );
		$draw->Create( Enums->Depth_ZAXIS, Enums->Symbol_SURFACE, undef, $depth );

		# Add anew layerData to datalist

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );
		$self->{"layerList"}->AddLayer($lData);

	}

	# Do control, if prcesssed layer is empty. All symbols hsould be moved

	my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $l->{"gROWname"} );
	if ( $hist{"total"} > 0 ) {

		die "Some featuers was no processed and left in layer " . $l->{"gROWname"} . "\n.";
	}

}

# Copy type of symbols to new layer and return layer name
sub __SeparateSymbol {
	my $self    = shift;
	my $sourceL = shift;
	my $tool    = shift;    # UniTool

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) copy source layer to

	my $lName = GeneralHelper->GetNumUID();

	my $f = FeatureFilter->new( $inCAM, $jobId, $sourceL->{"gROWname"} );

	if ( $tool->GetTypeProcess() eq DTMEnums->TypeProc_HOLE ) {

		my @types = ("pad");
		$f->SetTypes( \@types );

		my @syms = ( "r" . $tool->GetDrillSize() );
		$f->AddIncludeSymbols( \@syms );

	}
	elsif ( $tool->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN ) {

		if ( $tool->GetSource() eq DTMEnums->Source_DTM ) {

			my @types = ( "line", "arc" );
			$f->SetTypes( \@types );

			my @syms = ( "r" . $tool->GetDrillSize() );
			$f->AddIncludeSymbols( \@syms );

		}
		elsif ( $tool->GetSource() eq DTMEnums->Source_DTMSURF ) {

			my @types = ("surface");
			$f->SetTypes( \@types );

			# TODO chzba incam,  je v inch misto mm
			my %num = ( "min" => $tool->GetDrillSize() / 1000 / 25.4, "max" => $tool->GetDrillSize() / 1000 / 25.4 );
			$f->AddIncludeAtt( ".rout_tool", \%num );
		}
	}

	unless ( $f->Select() > 0 ) {
		return 0;
	}
	else {

		$inCAM->COM(
			"sel_move_other",

			# "dest"         => "layer_name",
			"target_layer" => $lName
		);

		# if slot or surface, do compensation
		if ( $tool->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN ) {

			CamLayer->WorkLayer( $inCAM, $lName );
			my $lComp = CamLayer->RoutCompensation( $inCAM, $lName, "document" );

			CamLayer->WorkLayer( $inCAM, $lName );
			$inCAM->COM("sel_delete");

			$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
			$inCAM->COM( "delete_layer", "layer" => $lComp );
		}

	}

	return $lName;
}

# Copy type of symbols to new layer and return layer name
sub __GetSymbolDepth {
	my $self     = shift;
	my $sourceL  = shift;
	my $symbol   = shift;
	my $toolType = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my ($toolSize) = $symbol =~ /^\w(\d*)/;

	my $depth = $sourceL->{"uniDTM"}->GetToolDepth( $toolSize, $toolType );

	if ( !defined $depth || $depth == 0 ) {
		die "Depth is not defined for tool $symbol in layer " . $sourceL->{"gROWname"} . ".\n";
	}

	return $depth;
}
#
## Return depth of surafaces in given layer
## Layer shoul contain same depth for all surfaces
#sub __GetSurfaceDepth {
#	my $self   = shift;
#	my $l      = shift;
#	my $symbol = shift;
#
#	my $inCAM = $self->{"inCAM"};
#	my $jobId = $self->{"jobId"};
#
#	my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $self->{"step"}, $l->{"gROWname"} );
#
#	unless ( defined $attHist{".rout_tool"} ) {
#		die "No .rout_tool attribute is defined in surface. \n";
#	}
#
#	# TODO chzba incam, hloubka je v inch misto mm
#	my $toolSize = sprintf( "%.1f", $attHist{".rout_tool"} * 25.4 );
#
#	my $depth = $sourceL->{"uniDTM"}->GetToolDepth( $toolSize, DTMEnums->TypeProc_CHAIN );
#
#	if ( !defined $depth || $depth == 0 ) {
#		die "Depth is not defined for tool $symbol in layer " . $sourceL->{"gROWname"} . ".\n";
#	}
#
#	return $d;
#}

# Create layer and fill profile - simulate pcb material
sub __PrepareNCDEPTHMILL {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	@layers = grep { $_->{"type"} && $_->{"gROWcontext"} eq "board" } @layers;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# all depth nc layers

	@layers = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot
	} @layers;

	foreach my $l (@layers) {

		my $tit = ValueConvertor->GetJobLayerTitle($l);
		my $inf = ValueConvertor->GetJobLayerInfo($l);

		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM(
					 "copy_layer",
					 "source_job"   => $jobId,
					 "source_step"  => $self->{"step"},
					 "source_layer" => $l->{"gROWname"},
					 "dest"         => "layer_name",
					 "dest_step"    => $self->{"step"},
					 "dest_layer"   => $lName,
					 "mode"         => "append"
		);

		$self->__ComputeNewDTMTools( $lName, $l->{"plated"} );

		# add table with depth information
		$self->__InsertDepthTable($lName);

		my $lData = LayerData->new( $type, ValueConvertor->GetFileNameByLayer($l), $tit, $inf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}

}

sub __PrepareOUTLINE {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};

	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	CamLayer->WorkLayer( $inCAM, $lName );

	$inCAM->COM( "profile_to_rout", "layer" => $lName, "width" => "200" );

	@layers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} ne "drill" && $_->{"gROWlayer_type"} ne "rout" } @layers;

	foreach my $l (@layers) {

		my $tit = "Outline layer";
		my $inf = "";

		my $lData = LayerData->new( $type, "dim", $tit, $inf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
