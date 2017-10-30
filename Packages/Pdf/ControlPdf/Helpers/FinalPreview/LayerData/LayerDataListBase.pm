
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <LayerData> and operations with this items
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerDataListBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerData';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
 

	$self->{"layers"} = [];
 

	return $self;
}
 

sub GetLayers {
	my $self      = shift;
	my $printable = shift;

	my @layers = @{ $self->{"layers"} };

	@layers = grep { $_->PrintLayer() } @layers;

	return @layers;
}

sub GetLayerByType {
	my $self = shift;
	my $type = shift;

	my $layer = ( grep { $_->GetType() eq $type } @{ $self->{"layers"} } )[0];

	return $layer;

}

 

sub _SetColors {
	my $self   = shift;
	my $colors = shift;

	foreach my $l ( @{ $self->{"layers"} } ) {

		my $surface = $colors->{ $l->GetType() };
		$l->SetSurface($surface);
	}
  
}
 

sub _AddToLayerData {
	my $self      = shift;
	my $singleL   = shift;
	my $lDataType = shift;

	my $lData = $self->GetLayerByType($lDataType);
	$lData->AddSingleLayer($singleL);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

