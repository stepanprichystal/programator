
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
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputData::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';
use aliased 'Packages::CAMJob::OutputData::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputData::Helper';
use aliased 'CamHelpers::CamGoldArea';

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

		my $enTit = ValueConvertor->GetJobLayerTitle($l);
		my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($l);
		my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

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

	my $enTit = ValueConvertor->GetJobLayerTitle( \%l );
	my $czTit = ValueConvertor->GetJobLayerTitle( \%l, 1 );
	my $enInf = ValueConvertor->GetJobLayerInfo( \%l );
	my $czInf = ValueConvertor->GetJobLayerInfo( \%l, 1 );

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

		my $enTit = ValueConvertor->GetJobLayerTitle($l);
		my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($l);
		my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

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
			
			if($cnt == 0){
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

		my $enTit = ValueConvertor->GetJobLayerTitle($l);
		my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($l);
		my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

		$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

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
