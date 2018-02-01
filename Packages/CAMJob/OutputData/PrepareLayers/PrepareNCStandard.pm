
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
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamHelper';
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

	$self->{"outputNClayer"} = shift;

	return $self;
}

sub Prepare {
	my $self   = shift;
	my $layers = shift;
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	$self->__PrepareNCDRILLBase( $layers, $type );
	$self->__PrepareNCMILL( $layers, $type );

}

# Create layer and fill profile - simulate pcb material
sub __PrepareNCDRILLBase {
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

		my $enTit = ValueConvertor->GetJobLayerTitle($l);
		my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($l);
		my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

		my $result = $self->{"outputNClayer"}->Prepare($l);

		my $lName = $result->MergeLayers($inCAM);    # merge DRILLBase and ROUTBase result layer

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);

		# Add Drill map

		if ( $result->GetClassResult( OutEnums->Type_DRILLBase, 1 ) ) {

			my $drillResult = $result->GetClassResult( OutEnums->Type_DRILLBase, 1 );

			my $drillMap =
			  $self->__CreateDrillMaps( $l, $drillResult->GetSingleLayer()->GetLayerName(), Enums->Type_DRILLBaseMAP, $enTit, $czTit, $enInf, $czInf );

			if ($drillMap) {
				$drillMap->SetParent($lData);
				$self->{"layerList"}->AddLayer($drillMap);
			}
		}

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

		my $lName = $result->MergeLayers();    # merge DRILLBase and ROUTBase result layer

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);

		# Add Drill map, if exist holes in layer

		if ( $result->GetClassResult( OutEnums->Type_DRILLBase, 1 ) ) {

			my $drillResult = $result->GetClassResult( OutEnums->Type_DRILLBase, 1 );

			if ($drillResult) {
				my $drillMap =
				  $self->__CreateDrillMaps( $l, $drillResult->GetSingleLayer()->GetLayerName(), Enums->Type_DRILLBaseMAP, $enTit, $czTit, $enInf,
											$czInf );

				if ($drillMap) {
					$drillMap->SetParent($lData);
					$self->{"layerList"}->AddLayer($drillMap);
				}
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

		my $lName         = GeneralHelper->GetNumUID();
		my $lNameDrillMap = GeneralHelper->GetNumUID();

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

			my $lDrillRout = $result->MergeLayers($inCAM);    # merged drill + rout layer

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

			$inCAM->COM( "delete_layer", "layer" => $lDrillRout );

			if ( $result->GetClassResult( OutEnums->Type_DRILLBase, 1 ) ) {

				my $drillResult = $result->GetClassResult( OutEnums->Type_DRILLBase, 1 );

				if ($drillResult) {
					$inCAM->COM(
								 "copy_layer",
								 "source_job"   => $jobId,
								 "source_step"  => $self->{"step"},
								 "source_layer" => $drillResult->GetSingleLayer()->GetLayerName(),
								 "dest"         => "layer_name",
								 "dest_step"    => $self->{"step"},
								 "dest_layer"   => $lNameDrillMap,
								 "mode"         => "append"
					);
				}
			}
		}

		my $lData = LayerData->new( $type, $lMain, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);

		# Add Drill map, only if exist holes ($lNameDrillMap ha sto be created)
		if ( CamHelper->LayerExists( $inCAM, $jobId, $lNameDrillMap ) ) {

			# After merging layers, merge tools in DTM
			$inCAM->COM( "tools_merge", "layer" => $lNameDrillMap );

			my $drillMap = $self->__CreateDrillMaps( $lMain, $lNameDrillMap, Enums->Type_DRILLBaseMAP, $enTit, $czTit, $enInf, $czInf );

			if ($drillMap) {
				$drillMap->SetParent($lData);
				$self->{"layerList"}->AddLayer($drillMap);
			}

			$inCAM->COM( "delete_layer", "layer" => $lNameDrillMap );
		}
	}
}

# Create layer and fill profile - simulate pcb material
sub __CreateDrillMaps {
	my $self       = shift;
	my $oriLayer   = shift;
	my $drillLayer = shift; # layer with pads
	my $type       = shift;
	my $enTit      = shift;
	my $czTit      = shift;
	my $enInf      = shift;
	my $czInf      = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};

	my $lNameMap = GeneralHelper->GetNumUID();

	# 1) Check if only pads exist in layer
	my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $stepName, $drillLayer );
	
	if($fHist{"total"} != $fHist{"pad"}){
		die "Layer: $drillLayer doien't contain only holes";
	}
 
	# 2) copy pads to new layer
	my $lNamePads = GeneralHelper->GetGUID();
 
 	CamLayer->WorkLayer($inCAM, $drillLayer);
	$inCAM->COM(
		"sel_copy_other",

		"dest"         => "layer_name",
		"target_layer" => $lNamePads
	);
	CamLayer->SetLayerTypeLayer( $inCAM, $self->{"jobId"}, $lNamePads, "drill" );

	# 3) create drill map

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

	my $f = FeatureFilter->new( $inCAM, $jobId, $lNameMap );
	my @types = ("text");
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
