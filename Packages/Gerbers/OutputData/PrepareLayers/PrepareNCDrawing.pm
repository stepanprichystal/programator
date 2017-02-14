
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers before print as pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::OutputData::PrepareLayers::PrepareNCDrawing;

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
use aliased 'Packages::Gerbers::OutputData::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Gerbers::OutputData::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamToolDepth';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::Gerbers::OutputData::Drawing::Drawing';
use aliased 'Packages::CAM::SymbolDrawing::Point';

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

		$self->__ProcessNClayer( $l, $type );

	}

}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __ProcessNClayer {
	my $self = shift;
	my $l    = shift;
	my $type = shift;

	my $enTit = ValueConvertor->GetJobLayerTitle($l);
	my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
	my $enInf = ValueConvertor->GetJobLayerInfo($l);
	my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

	my $drawingPos = Point->new( 0, abs( $self->{"profileLim"}->{"yMax"} - $self->{"profileLim"}->{"yMin"} ) + 50 );    # starts 150

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my %lines_arcs = %{ $l->{"symHist"}->{"lines_arcs"} };
	my %pads       = %{ $l->{"symHist"}->{"pads"} };

	# Get if NC operation is from top/bot
	my $side = $l->{"gROWname"} =~ /c/ ? "top" : "bot";

	# 1) Proces slots (lines + arcs)

	foreach my $sym ( keys %lines_arcs ) {

		my ($toolSize) = $sym =~ /^\w(\d*)/;

		if ( $lines_arcs{$sym} > 0 ) {

			my $depth = $self->__GetSymbolDepth( $l, $sym );
			my $lName = $self->__SeparateSymbol( $l, Enums->Symbol_SLOT, $sym, $depth );

			my $draw = Drawing->new( $inCAM, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );

			# Test on special countersink tool
			if ( ( !$l->{"plated"} && $toolSize == 6500 ) || ( $l->{"plated"} && $toolSize == 6400 ) ) {

				# if slot/hole is plated, finial depth will be smaller -100µm
				if ( $l->{"plated"} ) {
					$depth -= 0.1;
				}

				#compute real milled hole/line diameter
				# TODO zmenit 90 stupnu je zde natvrdo
				my $angle      = 90;
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

	}

	# 2) Proces holes ( pads )

	foreach my $sym ( keys %pads ) {

		my ($toolSize) = $sym =~ /^\w(\d*)/;

		if ( $pads{$sym} > 0 ) {

			my $depth = $self->__GetSymbolDepth( $l, $sym );
			my $lName = $self->__SeparateSymbol( $l, Enums->Symbol_HOLE, $sym, $depth );

			my $draw = Drawing->new( $inCAM, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );

			# Test on special countersink tool
			if ( ( !$l->{"plated"} && $toolSize == 6500 ) || ( $l->{"plated"} && $toolSize == 6400 ) ) {

				# if slot/hole is plated, finial depth will be smaller -100µm
				if ( $l->{"plated"} ) {
					$depth -= 0.1;
				}

				#compute real milled hole/line diameter
				# TODO ymenit 90 stupnu je zde natvrdo
				my $angle      = 90;
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
	}

	# 3) Process surfaces
	if ( $l->{"fHist"}->{"surf"} > 0 ) {

		my $depth = $self->__GetSurfaceDepth($l);
		my $lName = $self->__SeparateSymbol( $l, Enums->Symbol_SURFACE, undef, $depth, $l->{"plated"} );

		# if surface is plated, finial depth will be smaller -100µm
		if ( $l->{"plated"} ) {
			$depth -= 0.1;
		}

		my $draw = Drawing->new( $inCAM, $lName, $drawingPos, $self->{"pcbThick"}, $side, $l->{"plated"} );
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
	my $type    = shift;    # slot / hole / surface
	my $symbol  = shift;
	my $depth   = shift;

	my $inCAM = $self->{"inCAM"};

	# 1) copy source layer to

	my $lName = GeneralHelper->GetGUID();

	my $f = FeatureFilter->new( $inCAM, $sourceL->{"gROWname"} );

	if ( $type eq Enums->Symbol_HOLE ) {

		my @types = ("pad");
		$f->SetTypes( \@types );

		my @syms = ($symbol);
		$f->AddIncludeSymbols( \@syms );

	}
	elsif ( $type eq Enums->Symbol_SLOT ) {

		my @types = ( "line", "arc" );
		$f->SetTypes( \@types );

		my @syms = ($symbol);
		$f->AddIncludeSymbols( \@syms );

	}
	elsif ( $type eq Enums->Symbol_SURFACE ) {

		my @types = ("surface");
		$f->SetTypes( \@types );

	}

	unless ( $f->Select() > 0 ) {
		die "no features selected.\n";
	}

	$inCAM->COM(
		"sel_move_other",

		# "dest"         => "layer_name",
		"target_layer" => $lName
	);

	# if slot or surface, do compensation
	if ( $type eq Enums->Symbol_SLOT || $type eq Enums->Symbol_SURFACE ) {

		CamLayer->WorkLayer( $inCAM, $lName );
		my $lComp = CamLayer->RoutCompensation( $inCAM, $lName, "document" );

		CamLayer->WorkLayer( $inCAM, $lName );
		$inCAM->COM("sel_delete");

		$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
		$inCAM->COM( "delete_layer", "layer" => $lComp );
	}

	return $lName;

}

# Copy type of symbols to new layer and return layer name
sub __GetSymbolDepth {
	my $self    = shift;
	my $sourceL = shift;
	my $symbol  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @tools = CamDTM->GetDTMColumns( $inCAM, $jobId, $self->{"step"}, $sourceL->{"gROWname"} );

	my ($toolSize) = $symbol =~ /^\w(\d*)/;

	my $tool = ( grep { $_->{"gTOOLdrill_size"} == $toolSize } @tools )[0];

	my $depth = $tool->{"userColumns"}->{"depth"};

	if ( !defined $depth || $depth == 0 ) {
		die "Depth is not defined for tool $symbol in layer " . $sourceL->{"gROWname"} . ".\n";
	}

	return $depth;
}

# Return depth of surafaces in given layer
# Layer shoul contain same depth for all surfaces
sub __GetSurfaceDepth {
	my $self   = shift;
	my $l      = shift;
	my $symbol = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $self->{"step"}, $l->{"gROWname"} );

	unless ( defined $attHist{".depth"} ) {
		die "No .depth in attribute in surface. \n";
	}

	my @depths = @{ $attHist{".depth"} };

	unless ( scalar(@depths) ) {
		die "No .depth value in attribute in surface. \n";
	}

	if ( !defined $depths[0] || $depths[0] == 0 ) {
		die "Depth is not defined for surfaces in layer " . $l->{"gROWname"} . ".\n";
	}

	# TODO chzba incam, hloubka je v inch misto mm
	my $d = sprintf( "%.1f", $depths[0] * 25.4 );

	return $d;
}

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

sub __GetDepthTable {
	my $self  = shift;
	my $lName = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};

	my @rows = ();    # table row

	# 1) get depths for all diameter
	my @toolDepths = CamToolDepth->GetToolDepths( $inCAM, $jobId, $stepName, $lName );

	$inCAM->INFO(
				  units       => 'mm',
				  entity_type => 'layer',
				  entity_path => "$jobId/$stepName/$lName",
				  data_type   => 'TOOL',
				  parameters  => 'drill_size+shape',
				  options     => "break_sr"
	);
	my @toolSize  = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
	my @toolShape = @{ $inCAM->{doinfo}{gTOOLshape} };

	# 2) check if tool depth is set
	for ( my $i = 0 ; $i < scalar(@toolSize) ; $i++ ) {

		my $tSize = $toolSize[$i];

		#for each hole diameter, get depth (in mm)
		my $tDepth;

		my $prepareOk = CamToolDepth->PrepareToolDepth( $tSize, \@toolDepths, \$tDepth );

		unless ($prepareOk) {

			die "$tSize doesn't has set deep of milling/drilling.\n";
		}

		# TODO - az bude sprovoznene pridavani flagu na specialni nastroje, tak dodelat
		# pak to pro nastroj 6.5 vrati 90stupnu atp
		my $tInfo = "";

		my @row = ();

		push( @row, ( sprintf( "%0.2f", $tSize / 1000 ), sprintf( "%0.2f", $tDepth ), $tInfo ) );

		push( @rows, \@row );
	}

	return @rows;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
