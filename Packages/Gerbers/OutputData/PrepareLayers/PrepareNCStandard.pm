
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers before print as pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::OutputData::PrepareLayers::PrepareNCStandard;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];

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
 
#use aliased 'CamHelpers::CamFilter';
#use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';

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
		
		my $lName = GeneralHelper->GetGUID();

		my $enTit = ValueConvertor->GetJobLayerTitle($l);
		my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($l);
		my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );
		
		 $inCAM->COM(	"copy_layer",
						 "source_job"   => $jobId,
						 "source_step"  => $self->{"step"},
						 "source_layer" => $l->{"gROWname"},
						 "dest"         => "layer_name",
						 "dest_step"    => $self->{"step"},
						 "dest_layer"   => $lName,
						 "mode"         => "append"
		 );

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);

		# Add Drill map

		my $drillMap = $self->__CreateDrillMaps( $l, $lName, Enums->Type_DRILLMAP, $enTit, $czTit, $enInf, $czInf );

		if ($drillMap) {
			$drillMap->SetParent($lData);
			$self->{"layerList"}->AddLayer($drillMap);
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
		my $lComp = CamLayer->RoutCompensation($inCAM, $l->{"gROWname"}, "document");

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lComp );

		$self->{"layerList"}->AddLayer($lData);

		# Add Drill map

		# Add Drill map

		my $drillMap = $self->__CreateDrillMaps( $l, $lComp,  Enums->Type_DRILLMAP, $enTit, $czTit, $enInf, $czInf );

		if ($drillMap) {
			$drillMap->SetParent($lData);
			$self->{"layerList"}->AddLayer($drillMap);
		}
	}

	# Merge: mill, rs, k mill layers

	my @layersMill = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill
	} @layers;

	if ( scalar(@layersMill) ) {

		my $lName = GeneralHelper->GetGUID();

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
		}

		# After merging layers, merge tools in DTM
		$inCAM->COM( "tools_merge", "layer" => $lName );
		
		 # Compensate layer
		my $lComp = CamLayer->RoutCompensation($inCAM, $lName, "document");
		$inCAM->COM("delete_layer", "layer"=> $lName);

		my $lData = LayerData->new( $type, $lMain, $enTit, $czTit, $enInf, $czInf, $lComp );

		$self->{"layerList"}->AddLayer($lData);

		# Add Drill map

		my $drillMap = $self->__CreateDrillMaps( $lMain, $lComp, Enums->Type_DRILLMAP, $enTit, $czTit, $enInf, $czInf );

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

	my $lNameMap = GeneralHelper->GetGUID();

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
		"table_pos"       => "right",                 # alwazs right, because another option not work
		"table_align"     => "bottom"
	);
	
	$f = FeatureFilter->new( $inCAM, $jobId, $lNameMap );
	@types = ("text");
	$f->SetTypes( \@types );
	$f->SetText("*Drill*");
	
	if($f->Select() > 0){
		
		$inCAM -> COM ('sel_change_txt',"text" =>'Finish');																	
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
