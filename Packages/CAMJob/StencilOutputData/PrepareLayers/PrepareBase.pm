
#-------------------------------------------------------------------------------------------#
# Description: Prepare stencil lazers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::StencilOutputData::PrepareLayers::PrepareBase;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::CAMJob::OutputData::LayerData::LayerData';
use aliased 'Packages::CAMJob::StencilOutputData::Enums';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::StencilOutputData::Helper';
use aliased 'Programs::Stencil::StencilSerializer::StencilSerializer';
use aliased 'Programs::Stencil::StencilCreator::Enums'           => 'StnclEnums';
use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper' => 'StnclHelper';

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

	$self->{"params"} = StencilSerializer->new( $self->{"jobId"} )->LoadStenciLParams();
	my %inf = StnclHelper->GetStencilInfo( $self->{"jobId"} );
	$self->{"stencilInf"} = \%inf;

	return $self;
}

sub Prepare {
	my $self   = shift;
	my $layers = shift;

	# prepare layers
	$self->__PrepareStencilDataLayer($layers);

	$self->__PrepareFiducialLayer($layers);

}

sub __PrepareStencilDataLayer {
	my $self   = shift;
	my $layers = shift;

	my $inCAM = $self->{"inCAM"};

	my $layer = ( grep { $_->{"gROWname"} =~ /^ds$/ || $_->{"gROWname"} =~ /^flc$/ } @{$layers} )[0];

	# Add layer with stencil data
	if ($layer) {
		my $lName = GeneralHelper->GetNumUID();

		my $enTit = undef;
		my $czTit = undef;

		if ( $self->{"params"}->GetStencilType() eq StnclEnums->StencilType_TOP ) {

			$enTit = "Production stencil data for TOP pcb side";
			$czTit = "Výrobní data pro vrchní stranu dps";

		}
		elsif ( $self->{"params"}->GetStencilType() eq StnclEnums->StencilType_BOT ) {

			$enTit = "Production stencil data for BOT pcb side";
			$czTit = "Výrobní data pro spodní stranu dps";

		}
		elsif ( $self->{"params"}->GetStencilType() eq StnclEnums->StencilType_TOPBOT ) {

			$enTit = "Production stencil data for TOP + BOTTOM pcb side";
			$czTit = "Výrobní data pro vrchní a spodní stranu dps";
		}

		my $enInf = "Production data are shown as viewed from the top.";
		my $czInf = "Výrobní data jsou zobrazena při pohledu z vrchu.";
		$inCAM->COM( "merge_layers", "source_layer" => $layer->{"gROWname"}, "dest_layer" => $lName );

		my $lData = LayerData->new( "", $layer, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);

	}
}

sub __PrepareFiducialLayer {
	my $self   = shift;
	my $layers = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $layer = ( grep { $_->{"gROWname"} =~ /^ds$/ || $_->{"gROWname"} =~ /^flc$/ } @{$layers} )[0];

	my $fiducInf = $self->{"params"}->GetFiducial();

	# Add layer with stencil data
	if ( $layer && $fiducInf->{"halfFiducials"} ) {

		my $lName = GeneralHelper->GetNumUID();

		my $enTit = undef;
		my $czTit = undef;

		my $readable = $fiducInf->{"fiducSide"} eq "readable" ? 1 : 0;

		if ( $self->{"stencilInf"}->{"tech"} eq StnclEnums->Technology_LASER ) {
			$enTit = "Half-lasered fiducial marks (from " . ( $readable ? "readable" : "nonreadable" ) . " stencil side)";
			$czTit = "Fiduciální značky vypálené do poloviny (z " . ( $readable ? "čitelné" : "nečitelné" ) . " strany šablony)";
		}
		elsif ( $self->{"stencilInf"}->{"tech"} eq StnclEnums->Technology_ETCH ) {
			$enTit = "Half-etched  fiducial marks (from " . ( $readable ? "readable" : "nonreadable" ) . " stencil side)";
			$czTit = "Fiduciální značky vyleptané do poloviny (z " . ( $readable ? "čitelné" : "nečitelné" ) . " strany šablony)";
		}
 
		my $enInf = "Production data are shown as viewed from TOP.";
		my $czInf = "Výrobní data jsou zobrazena při pohledu z vrchu.";
		
		CamLayer->WorkLayer( $inCAM, $layer->{"gROWname"} );
		if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".fiducial_name", "*" ) ) {

			CamLayer->CopySelected( $inCAM, [$lName] );
			 
		}else{
			
			die "No fiducial marks selected";
		}

		my $lData = LayerData->new( "", $layer, $enTit, $czTit, $enInf, $czInf, $lName );

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
