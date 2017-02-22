
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" of each exported layers.
# This sctructure contain information
# about exported layers, like name, array of phzsic layer, titles + description
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::SinglePreview::LayerData::LayerDataList;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Pdf::ControlPdf::SinglePreview::Enums';
use aliased 'Packages::Pdf::ControlPdf::SinglePreview::LayerData::LayerData';
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

#
#sub GetLayerByName {
#	my $self = shift;
#	my $name = shift;
#
#	foreach my $lData ( @{ $self->{"layers"} } ) {
#
#		my @single = $lData->GetSingleLayers();
#
#		my $sl = ( grep { $_->{"gROWname"} eq $name } @single )[0];
#
#		if ($sl) {
#
#			return $lData;
#		}
#	}
#
#}

sub GetPageData {
	my $self    = shift;
	my $pageNum = shift;

	my @data = ();

	my @layers = @{ $self->{"layers"} };

	my $start = ( $pageNum - 1 ) * 4;

	for ( my $i = 0 ; $i < 4 ; $i++ ) {

		my $lData = $layers[ $start + $i ];

		if ($lData) {
			#my @singleLayers = $lData->GetSingleLayers();

			my $tit = $lData->GetTitle( $self->{"lang"} );
			my $inf = $lData->GetInfo( $self->{"lang"} );

			my %inf = ( "title" => $tit, "info" => $inf );
			push( @data, \%inf );
		}

	}

	return @data;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

