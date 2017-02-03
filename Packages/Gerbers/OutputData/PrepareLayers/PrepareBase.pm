
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers before print as pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::OutputData::PrepareLayers::PrepareBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Gerbers::ProduceData::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Gerbers::OutputData::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';
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

}

# Create layer and fill profile - simulate pcb material
sub __PrepareBASEBOARD {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	@layers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} ne "drill" && $_->{"gROWlayer_type"} ne "rout" } @layers;

	foreach my $l (@layers) {

		my $enTit = ValueConvertor->GetJobLayerTitle($l);
		my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($l);
		my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $l->{"gROWname"} );

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

		my $enTit = "Outline pcb";
		my $czTit = "Obrys dps";
		my $enInf = "";
		my $czInf = "";

		my $lData = LayerData->new( $type, undef, "dim", $enTit, $czTit, $enInf, $czInf, $lName );

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
