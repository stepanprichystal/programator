
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <LayerData> and operations with this items
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::LayerData::LayerDataList;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::OutputData::Enums';

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

sub AddLayer {
	my $self  = shift;
	my $layer = shift;

	$layer->{"number"} = undef;

	push( @{ $self->{"layers"} }, $layer );
}

sub GetLayers {
	my $self = shift;

	return @{ $self->{"layers"} };
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

