
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <LayerData> and operations with this items
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::ProduceData::LayerData::LayerDataList;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::LayerData::LayerData';
use aliased 'Packages::Pdf::ControlPdf::FinalPreview::Enums';
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
 
	my @l = ();
	$self->{"layers"} = \@l;
 

	return $self;
}

 
sub AddLayer{
	my $self      = shift;
	my $layer      = shift;
	
	push(@{$self->{"layers"}}, $layer);
} 
 

sub GetLayers {
#	my $self      = shift;
#	my $printable = shift;
#
#	my @layers = @{ $self->{"layers"} };
#
#	@layers = grep { $_->PrintLayer() } @layers;
#
#	return @layers;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

