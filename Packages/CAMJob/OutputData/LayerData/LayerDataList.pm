
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

	# test if exist data layer with already used type of 'original layer'
	# E.g. type nplt_mill_top is already used, so increase  property 'number' in datalayer
	# This regardin only NC layers
#
#	if ( $layer->GetType() eq Enums->Type_DRILLMAP ) {
#
#			$layer->{"number"} = $layer->GetParent()->GetNumber();
#
#	}else {
#		
#		my $ori = $layer->GetOriLayer();
#
#		if ( defined $ori->{"type"} ) {
#
#			# filter NC layers
#			my @nc = grep { defined $_->GetOriLayer() && defined $_->GetOriLayer()->{"type"} } @{ $self->{"layers"} };
#
#			my @lSame = grep { $_->GetOriLayer()->{"type"} eq $ori->{"type"} } @nc;
#
#			if ( scalar(@lSame) ) {
#				
#				# if only one layer is same type, add number
#				if ( scalar(@lSame) == 1 ){
#					 $lSame[0]->{"number"} = 1;
#				}
#
#				
#				$layer->{"number"} = scalar(@lSame) + 1;
#			}
#		}
#	}

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

