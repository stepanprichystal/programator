
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare non NC layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::PrepareLayers::PrepareBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputData::LayerData::LayerData';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::CAMJob::OutputData::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputData::Helper';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputParserNC';

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

	$self->{"outputNClayer"} = OutputParserNC->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

	return $self;
}

sub Prepare {
	my $self   = shift;
	my $layers = shift;

	# prepare layers
	$self->__PrepareLayers($layers);

}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __PrepareLayers {
	my $self   = shift;
	my $layers = shift;

	$self->__PrepareBASEBOARD( $layers, Enums->Type_BOARDLAYERS );
	$self->__PrepareOUTLINE( $layers, Enums->Type_OUTLINE );
	$self->__PrepareSPECIALSURF( $layers, Enums->Type_SPECIALSURF );
	$self->__PrepareFILLEDHOLES( $layers, Enums->Type_FILLEDHOLES );

}

# Create layer and fill profile - simulate pcb material
sub __PrepareBASEBOARD {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};

	@layers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} ne "drill" && $_->{"gROWlayer_type"} ne "rout" } @layers;
	@layers = grep { $_->{"gROWname"} !~ /^([lg]|gold)[cs]$/i } @layers;    # special surfaces (goldc, gc, lc, etc)

	foreach my $l (@layers) {

		my $lName = GeneralHelper->GetNumUID();

		my $enTit = Helper->GetJobLayerTitle( $l, $type );
		my $czTit = Helper->GetJobLayerTitle( $l, $type, 1 );
		my $enInf = Helper->GetJobLayerInfo($l);
		my $czInf = Helper->GetJobLayerInfo( $l, 1 );

		$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}
}

sub __PrepareOUTLINE {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};

	my $lName = GeneralHelper->GetNumUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	CamLayer->WorkLayer( $inCAM, $lName );

	$inCAM->COM( "profile_to_rout", "layer" => $lName, "width" => "200" );

	# fake layer 'o'
	my %l = ( "gROWname" => "o" );

	my $enTit = Helper->GetJobLayerTitle( \%l, $type );
	my $czTit = Helper->GetJobLayerTitle( \%l, $type, 1 );
	my $enInf = Helper->GetJobLayerInfo( \%l );
	my $czInf = Helper->GetJobLayerInfo( \%l, 1 );

	my $lData = LayerData->new( $type, \%l, $enTit, $czTit, $enInf, $czInf, $lName );

	$self->{"layerList"}->AddLayer($lData);

}

# gold fingers, grafit paste
sub __PrepareSPECIALSURF {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	@layers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} ne "drill" && $_->{"gROWlayer_type"} ne "rout" } @layers;

	# 1)  # special surfaces (goldc, gc - where are only affected pads by "reference" layer considered)
	my @lPadConsider = grep { $_->{"gROWname"} =~ /^(g|gold)[cs]$/i } @layers;

	foreach my $l (@lPadConsider) {

		my $enTit = Helper->GetJobLayerTitle( $l, $type );
		my $czTit = Helper->GetJobLayerTitle( $l, $type, 1 );
		my $enInf = Helper->GetJobLayerInfo($l);
		my $czInf = Helper->GetJobLayerInfo( $l, 1 );

		my $refL    = $l->{"gROWname"};
		my $baseCuL = ( $refL =~ m/^([pmlg]|gold)?([cs])$/ )[1];
		my $maskL   = "m" . $baseCuL;

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $maskL ) ) {
			$maskL = 0;
		}

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $refL ) ) {
			die "Reference layer $refL doesn't exist.";
		}

		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		my $lName = Helper->FeaturesByRefLayer( $inCAM, $jobId, $baseCuL, $refL, $maskL, $self->{"profileLim"} );

		# if layer is gold[cs] - add info about gold finger count
		if ( $refL =~ m/gold(c|s)/ ) {

			my $cnt = CamGoldArea->GetGoldFingerCount( $inCAM, $jobId, $step, $1 );
			$enInf .= "gold finger count: $cnt";
			$czInf .= "poèet zlacených plošek: $cnt";

			if ( $cnt == 0 ) {
				next;
			}
		}

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}

	# 2) # special surfaces where is used  "reference" layer
	my @lRefLayer = grep { $_->{"gROWname"} =~ /^l[cs]$/i } @layers;

	foreach my $l (@lRefLayer) {

		my $lName = GeneralHelper->GetNumUID();

		my $enTit = Helper->GetJobLayerTitle( $l, $type );
		my $czTit = Helper->GetJobLayerTitle( $l, $type, 1 );
		my $enInf = Helper->GetJobLayerInfo($l);
		my $czInf = Helper->GetJobLayerInfo( $l, 1 );

		$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}

}

# gold fingers, grafit paste
sub __PrepareFILLEDHOLES {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my @lFilled = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} eq "drill" } @layers;

	CamDrilling->AddNCLayerType( \@lFilled );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@lFilled );

	@lFilled = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot
	} @lFilled;

	my %lFilledMatrix = ();
	push( @{ $lFilledMatrix{ $_->{"gROWdrl_start"} . "_" . $_->{"gROWdrl_end"} . "_" . $_->{"gROWdrl_dir"} } }, $_ ) foreach (@lFilled);

	foreach my $k ( keys %lFilledMatrix ) {

		die "Wrong key format ($k)" if ( $k !~ /\d+_\d+_(top2bot|bot2top)/ );

		my @l = @{ $lFilledMatrix{$k} };

		my $lName = GeneralHelper->GetNumUID();
		my $lMain = $l[0];

		my $enTit = Helper->GetJobLayerTitle( $lMain, $type );
		my $czTit = Helper->GetJobLayerTitle( $lMain, $type, 1 );
		my $enInf = Helper->GetJobLayerInfo($lMain);
		my $czInf = Helper->GetJobLayerInfo( $lMain, 1 );

		# Merge all layers
		foreach my $lFill (@l) {

			my $result = $self->{"outputNClayer"}->Prepare($lFill);

			my $lDrillRout = $result->MergeLayers();    # merge DRILLBase and ROUTBase result layer

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

		}

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
