
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare standard NC layers + drill maps
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::PrepareLayers::PrepareNCStandard;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];

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

#use aliased 'CamHelpers::CamFilter';
#use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::OutputNCLayer';
use aliased 'Packages::CAMJob::OutputData::OutputLayer::Enums' => 'OutEnums';

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

	$self->{"outputNClayer"} = OutputNCLayer->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

	return $self;
}

sub Prepare {
	my $self   = shift;
	my $layers = shift;
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	$self->__PrepareNCDRILL( $layers, $type );
	$self->__PrepareNCMILL( $layers, $type );

}

# Create layer and fill profile - simulate pcb material
sub __PrepareNCDRILL {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	@layers = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot

	} @layers;

	foreach my $l (@layers) {

		my $lName = GeneralHelper->GetNumUID();

		my $enTit = ValueConvertor->GetJobLayerTitle($l);
		my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($l);
		my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

		my $result = $self->{"outputNClayer"}->Prepare($l);

		foreach my $classRes ( $result->GetClassResults(1) ) {

			my $lName = GeneralHelper->GetGUID();
			$inCAM->COM( 'create_layer', "layer" => $lName, "context" => 'misc', "type" => 'document', "polarity" => 'positive', "ins_layer" => '' );

			my $t = $classRes->GetType();

			if ( $t eq OutEnums->Type_DRILL ) {

				my $layerResult = ( $classRes->GetLayers() )[0];
				my $drillLayer  = $layerResult->GetLayerName();

				#				my $drillMap = $self->__CreateDrillMaps( $l, $lName, Enums->Type_DRILLMAP, $enTit, $czTit, $enInf, $czInf );
				#
				#				if ($drillMap) {
				#					$drillMap->SetParent($lData);
				#					$self->{"layerList"}->AddLayer($drillMap);
				#				}

			}

			#$self->__ProcessLayerData( $classRes, $l, );
			#$self->__ProcessDrawing( $classRes, $l, $side, $drawingPos, $t );

		}

		$self->{"layerList"}->AddLayer($lData);

		#		# Add Drill map
		#
		#		my $drillMap = $self->__CreateDrillMaps( $l, $lName, Enums->Type_DRILLMAP, $enTit, $czTit, $enInf, $czInf );
		#
		#		if ($drillMap) {
		#			$drillMap->SetParent($lData);
		#			$self->{"layerList"}->AddLayer($drillMap);
		#		}

	}
}

# Create layer and fill profile - simulate pcb material
sub __PrepareNCMILL {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Scoring single + plated mill single

	my @layersSingle =
	  grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score } @layers;

	foreach my $l (@layersSingle) {

		my $enTit = ValueConvertor->GetJobLayerTitle($l);
		my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($l);
		my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

		# Compensate layer

		my $result = $self->{"outputNClayer"}->Prepare($l);

		my $lName = $result->MergeLayers();    # merge DRILL and ROUT result layer

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);

		# Add Drill map

		if ( $result->GetClassResult( OutEnums->Type_DRILL, 1 ) ) {

			my $drillResult = $result->GetClassResult( OutEnums->Type_DRILL, 1 );

			my $drillMap =
			  $self->__CreateDrillMaps( $l, $drillResult->GetSingleLayer()->GetLayerName(), Enums->Type_DRILLMAP, $enTit, $czTit, $enInf, $czInf );

			if ($drillMap) {
				$drillMap->SetParent($lData);
				$self->{"layerList"}->AddLayer($drillMap);
			}
		}
	}

	# Merge: mill, rs, k mill layers

	my @layersMill = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill
	} @layers;

	if ( scalar(@layersMill) ) {

		my $lName         = GeneralHelper->GetGUID();
		my $lNameDrillMap = GeneralHelper->GetGUID();

		# Choose layer, which 'data layer' take information from
		my $lMain = ( grep { $_->{"gROWname"} eq "f" } @layers )[0];
		unless ($lMain) {
			$lMain = $layersMill[0];
		}

		my $enTit = ValueConvertor->GetJobLayerTitle($lMain);
		my $czTit = ValueConvertor->GetJobLayerTitle( $lMain, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($lMain);
		my $czInf = ValueConvertor->GetJobLayerInfo( $lMain, 1 );

		# Merge all layers
		foreach my $l (@layersMill) {

			my $result = $self->{"outputNClayer"}->Prepare($l);

			my $lDrillRout = $result->MergeLayers();    # merged drill + rout layer

			$inCAM->COM(
						 "copy_layer",
						 "source_job"   => $jobId,
						 "source_step"  => $self->{"step"},
						 "source_layer" => $lDrillRout,
						 "dest"         => "layer_name",
						 "dest_step"    => $self->{"step"},
						 "dest_layer"   => $lName,
						 "mode"         => "append"
			);

			if ( $result->GetClassResult( OutEnums->Type_DRILL, 1 ) ) {

				my $drillResult = $result->GetClassResult( OutEnums->Type_DRILL, 1 );

				$inCAM->COM(
							 "copy_layer",
							 "source_job"   => $jobId,
							 "source_step"  => $self->{"step"},
							 "source_layer" => $drillResult->GetLayerName(),
							 "dest"         => "layer_name",
							 "dest_step"    => $self->{"step"},
							 "dest_layer"   => $lNameDrillMap,
							 "mode"         => "append"
				);

			}
		}

		# After merging layers, merge tools in DTM
		$inCAM->COM( "tools_merge", "layer" => $lNameDrillMap );

		# Compensate layer
		#my $lComp = CamLayer->RoutCompensation( $inCAM, $lName, "document" );
		#$inCAM->COM( "delete_layer", "layer" => $lName );

		my $lData = LayerData->new( $type, $lMain, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);

		# Add Drill map

		my $drillMap = $self->__CreateDrillMaps( $lMain, $lNameDrillMap, Enums->Type_DRILLMAP, $enTit, $czTit, $enInf, $czInf );

		if ($drillMap) {
			$drillMap->SetParent($lData);
			$self->{"layerList"}->AddLayer($drillMap);
		}
	}
}

# Create layer and fill profile - simulate pcb material
sub __CreateDrillMaps {
	my $self       = shift;
	my $oriLayer   = shift;
	my $drillLayer = shift;
	my $type       = shift;
	my $enTit      = shift;
	my $czTit      = shift;
	my $enInf      = shift;
	my $czInf      = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};

	my $lNameMap = GeneralHelper->GetNumUID();

	# 1) copy pads to new layer
	my $lNamePads = GeneralHelper->GetGUID();

	my $f = FeatureFilter->new( $inCAM, $jobId, $drillLayer );
	my @types = ("pad");
	$f->SetTypes( \@types );

	unless ( $f->Select() > 0 ) {
		return 0;
	}

	$inCAM->COM(
		"sel_copy_other",

		"dest"         => "layer_name",
		"target_layer" => $lNamePads
	);
	CamLayer->SetLayerTypeLayer( $inCAM, $self->{"jobId"}, $lNamePads, "drill" );

	# 2) create drill map

	$inCAM->COM(
		"cre_drills_map",
		"layer"           => $lNamePads,
		"map_layer"       => $lNameMap,
		"preserve_attr"   => "no",
		"draw_origin"     => "no",
		"define_via_type" => "no",
		"units"           => "mm",
		"mark_dim"        => "2000",
		"mark_line_width" => "400",
		"mark_location"   => "center",
		"sr"              => "no",
		"slots"           => "no",
		"columns"         => "Count\;Type",
		"notype"          => "plt",
		"table_pos"       => "right",         # alwazs right, because another option not work
		"table_align"     => "bottom"
	);

	$f = FeatureFilter->new( $inCAM, $jobId, $lNameMap );
	@types = ("text");
	$f->SetTypes( \@types );
	$f->SetText("*Drill*");

	if ( $f->Select() > 0 ) {

		$inCAM->COM( 'sel_change_txt', "text" => 'Finish' );
	}

	$inCAM->COM( "delete_layer", "layer" => $lNamePads );

	my $lDataMap = LayerData->new( $type, $oriLayer,
								   "Drill map: " . $enTit,
								   "Mapa vrtání: " . $czTit,
								   "Units [mm] " . $enInf,
								   "Jednotky [mm] " . $czInf, $lNameMap );

	return $lDataMap;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
