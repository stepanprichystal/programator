
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <LayerData> and operations with this items
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::StencilControlPdf::FinalPreview::LayerData::LayerDataList;
use base ('Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerDataListBase');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerData';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::FinalPreview::Enums';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Connectors::HeliosConnector::HegMethods';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"viewType"} = shift;

	$self->__InitLayers();

	return $self;
}

sub __InitLayers {
	my $self = shift;

	# layer data are sorted by final order of printing

	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_STNCLMAT ) );

	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_COVER ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_HOLES ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_DATAPROFILE ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_HALFFIDUC ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_PROFILE ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_CODES ) );
	push( @{ $self->{"layers"} }, LayerData->new( Enums->Type_FIDUCPOS ) );

}

sub SetLayers {
	my $self      = shift;
	my @allLayers = @{ shift(@_) };

	# Set layers fro VIEW from TOP

	if ( $self->{"viewType"} eq Enums->View_FROMTOP ) {

		foreach my $l (@allLayers) {

			if ( $l->{"gROWname"} =~ /^ds$/ || $l->{"gROWname"} =~ /^flc$/ ) {

				$self->_AddToLayerData( $l, Enums->Type_HOLES );
				$self->_AddToLayerData( $l, Enums->Type_HALFFIDUC );
				$self->_AddToLayerData( $l, Enums->Type_FIDUCPOS );

			}
		}

	}
}

sub SetColors {
	my $self   = shift;
	my $colors = shift;

	$self->_SetColors($colors);

}

# Return background color of final image
# if image has white mask, background will be pink
sub GetBackground {
	my $self = shift;

	return "255,255,255";    # white
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

