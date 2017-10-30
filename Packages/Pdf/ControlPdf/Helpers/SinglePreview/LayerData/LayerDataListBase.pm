
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <Packages::CAMJob::OutputData::LayerData::LayerData>
# and operations with this items
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::Helpers::SinglePreview::LayerData::LayerDataListBase;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::SinglePreview::Enums';
use aliased 'Helpers::ValueConvertor';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	
	$self->{"lang"} = shift;
	$self->{"stepName"} = undef;

	my @l = ();
	$self->{"layers"} = \@l;    # list of all exported layers <LayerData> type

	return $self;
}

sub SetLayers {
	my $self   = shift;
	my $layers = shift;         # layer, typ of Packages::Gerbers::OutputData::LayerData::LayerData

	push( @{ $self->{"layers"} }, @{$layers} );

}

sub GetLayers {
	my $self = shift;

	return @{ $self->{"layers"} };
}

sub GetLayersByType {
	my $self = shift;
	my $type = shift;

	my @layers = grep { $_->GetType() eq $type } @{ $self->{"layers"} };

	return @layers;
}

sub GetStepName {
	my $self = shift;

	return $self->{"stepName"};
}

sub SetStepName {
	my $self = shift;

	$self->{"stepName"} = shift;
}

sub GetLayerCnt {
	my $self = shift;

	return @{ $self->{"layers"} };
}

sub GetPageData {
	my $self    = shift;
	my $pageNum = shift;

	die "Must be overriden";
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

