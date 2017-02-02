
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers before print as pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::ProduceData::OutputPrepare;

#3th party library
use threads;
use strict;
use warnings;
use PDF::API2;
use List::Util qw[max min];
use Math::Trig;
use Image::Size;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Gerbers::ProduceData::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Gerbers::ProduceData::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDTM';

#use aliased 'CamHelpers::CamToolDepth';
#use aliased 'CamHelpers::CamFilter';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamSymbol';

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

	$self->{"profileLim"} = undef;    # limits of pdf step

	return $self;
}

sub PrepareLayers {
	my $self   = shift;
	my $layers = shift;

	# get limits of step
	my %lim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, 1 );
	$self->{"profileLim"} = \%lim;

	# prepare layers
	$self->__PrepareLayers($layers);

}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __PrepareLayers {
	my $self   = shift;
	my $layers = shift;

	$self->__PrepareBASEBOARD( $layers, Enums->Type_BOARDLAYERS );
	$self->__PrepareNCDRILL( $layers, Enums->Type_NCLAYERS );
	$self->__PrepareNCMILL( $layers, Enums->Type_NCLAYERS );
	$self->__PrepareNCDEPTHMILL( $layers, Enums->Type_NCLAYERS );

	#$self->__PrepareOUTLINE( $layers, Enums->Type_OUTLINE );
	#$self->__PrepareDOCUMENT( $layers, Enums->Type_DOCUMENT );

}

# Create layer and fill profile - simulate pcb material
sub __PrepareBASEBOARD {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	@layers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} ne "drill" && $_->{"gROWlayer_type"} ne "rout" } @layers;

	foreach my $l (@layers) {

		my $tit = ValueConvertor->GetJobLayerTitle($l);
		my $inf = ValueConvertor->GetJobLayerInfo($l);

		my $lData = LayerData->new( $type, $l->{"gROWname"}, $tit, $inf, $l->{"gROWname"} );

		$self->{"layerList"}->AddLayer($lData);
	}
}

# Create layer and fill profile - simulate pcb material
sub __PrepareNCDRILL {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	@layers = grep {
		(     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill
		   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill
		   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop
		   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot )
		  && $_->{"gROWcontext"} eq "board"
	} @layers;

	foreach my $l (@layers) {

		my $tit   = ValueConvertor->GetJobLayerTitle($l);
		my $inf   = ValueConvertor->GetJobLayerInfo($l);
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

		$self->__ComputeNewDTMTools($lName);

		my $lData = LayerData->new( $type, $l->{"gROWname"}, $tit, $inf, $lName );

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

		$self->__ComputeNewDTMTools($lName);

		my $lData = LayerData->new( $type, $l->{"gROWname"}, $tit, $inf, $lName );

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

		my $tit = ValueConvertor->GetJobLayerTitle("f");
		my $inf = ValueConvertor->GetJobLayerInfo("f");

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

			$self->__ComputeNewDTMTools($lName);
			my $lData = LayerData->new( $type, "f", $tit, $inf, $lName );

			$self->{"layerList"}->AddLayer($lData);
		}
	}
}

# Create layer and fill profile - simulate pcb material
sub __PrepareNCDEPTHMILL {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# all depth nc layers

	@layers = grep {
		(     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
		   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop
		   || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot )
		  && $_->{"gROWcontext"} eq "board"
	  } @layers;
 

	  foreach my $l (@layers){

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

		$self->__ComputeNewDTMTools($lName);
		
		# add table with depth information		

		my $lData = LayerData->new( $type, $l->{"gROWname"}, $tit, $inf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	  }

	  
}

sub __ComputeNewDTMTools {
	my $self  = shift;
	my $lName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Prepare tool table for drill map and final sizes of data (depand on column DSize in DTM)

	my @tools = CamDTM->GetDTMColumns( $inCAM, $jobId, $self->{"step"}, $lName );

	my $DTMType = CamDTM->GetDTMUToolsType( $inCAM, $jobId, $self->{"step"}, $lName );

	# check if dest size are defined
	my @badSize = grep { !defined $_->{"gTOOLdrill_size"} || $_->{"gTOOLdrill_size"} == 0 || $_->{"gTOOLdrill_size"} eq "" } @tools;

	if (@badSize) {
		@badSize = map { $_->{"gTOOLfinish_size"} } @badSize;
		my $toolStr = join( ", ", @badSize );
		die "Tools: $toolStr, has not set drill size.\n";
	}

	# 1) If some tool has not finish size, correct it by putting there drill size (if vysledne resize -100µm)

	foreach my $t (@tools) {

		if ( !defined $t->{"gTOOLfinish_size"} || $t->{"gTOOLfinish_size"} == 0 || $t->{"gTOOLfinish_size"} eq "" ) {

			if ( $DTMType eq "vysledne" ) {

				$t->{"gTOOLfinish_size"} = $t->{"gTOOLdrill_size"} - 100;    # 100µm - this is size of plating

			}
			elsif ( $DTMType eq "vrtane" ) {
				$t->{"gTOOLfinish_size"} = $t->{"gTOOLdrill_size"};
			}

		}
	}

	# 2) Copy 'finish' value to 'drill size' value.
	# Drill size has to contain value of finih size, because all pads, lines has size depand on this column
	# And we want diameters size after plating

	foreach my $t (@tools) {

		if ( $DTMType eq "vysledne" ) {
			$t->{"gTOOLdrill_size"} = $t->{"gTOOLfinish_size"};    # 100µm - this is size of plating

		}
		elsif ( $DTMType eq "vrtane" ) {
			$t->{"gTOOLdrill_size"} = $t->{"gTOOLfinish_size"} - 100;
		}
	}

	# 3) Set new values to DTM
	CamDTM->SetDTMTools( $inCAM, $jobId, $self->{"step"}, $lName, \@tools );

	# 4) Adjust surfaces in layer. All must be -100µm
	CamLayer->WorkLayer( $inCAM, $lName );
	my @types = ("surface");
	if ( CamFilter->ByTypes( $inCAM, \@types ) > 0 ) {
		$inCAM->COM( "sel_resize", "size" => -100 );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
