
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
use aliased 'Packages::Gerbers::ProduceData::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Gerbers::OutputData::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamToolDepth';

#use aliased 'CamHelpers::CamFilter';
#use aliased 'CamHelpers::CamHelper';
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

		my $enTit = ValueConvertor->GetJobLayerTitle($l);
		my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($l);
		my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $l->{"gROWname"} );

		$self->{"layerList"}->AddLayer($lData);
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

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $l->{"gROWname"} );

		$self->{"layerList"}->AddLayer($lData);
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
		unless($lMain){
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
		$inCAM->COM("tools_merge", "layer" => $lName);

		my $lData = LayerData->new( $type, $lMain, $enTit, $czTit, $enInf, $czInf, $lName );

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
