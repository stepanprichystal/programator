
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <LayerData> and operations with this items
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::Helpers::FinalPreview::LayerData::LayerDataListBase;

#3th party library
use strict;
use warnings;
use Storable qw(dclone);

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

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"viewType"} = shift;

	$self->{"layers"} = [];

	return $self;
}

sub GetLayers {
	my $self        = shift;
	my $type        = shift;
	my $visibleFrom = shift;
	my $active      = shift // 1;

	my @layers = @{ $self->{"layers"} };

	@layers = grep { $_->GetType() eq $type } @layers               if ( defined $type );
	@layers = grep { $_->GetVisibleFrom() eq $visibleFrom } @layers if ( defined $visibleFrom );
	@layers = grep { $_->GetIsActive() } @layers                    if ( defined $active );

	return @layers;
}

# Return all output (intended for pdf outut) layer data strucutre
sub GetOutputLayers {
	my $self = shift;

	return grep { $_->OutputLayer() } @{ $self->{"layers"} };
}


sub _SetLayers{
	my $self   = shift;
	my $layers = shift;	
	
	@{$self->{"layers"}} = reverse(@{$layers}); 
}

sub _SetColors {
	my $self   = shift;
	my $colors = shift;

	foreach my $l ( @{ $self->{"layers"} } ) {

		my $surface = $colors->{ $l->GetType() };
		
		$l->SetSurface(dclone($surface));
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

