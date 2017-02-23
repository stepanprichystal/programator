
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
use aliased 'Packages::Gerbers::ProduceData::LayerData::LayerData';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::ValueConvertor';
use aliased 'Packages::CAMJob::OutputData::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;

	my @l = ();
	$self->{"layers"} = \@l;

	$self->{"stepName"} = undef;

	return $self;
}

sub AddLayers {
	my $self   = shift;
	my $layers = shift;    # layer, typ of Packages::Gerbers::OutputData::LayerData::LayerData

	foreach my $lOutput ( @{$layers} ) {

		# Process only layers, which has no parent
		if ( $lOutput->GetParent() ) {
			next;
		}

		my $name       = "";
		my $nameSuffix = 0;

		$self->__GetFileName( $lOutput, \$name, \$nameSuffix );

		my $l = LayerData->new( $lOutput->GetType(), $name, $nameSuffix, $lOutput->GetTitle(), $lOutput->GetInfo(), $lOutput->GetOutput() );
		push( @{ $self->{"layers"} }, $l );

		# Process parent layers

		foreach my $child ( @{$layers} ) {

			if ( defined $child->GetParent() && $child->GetParent() == $lOutput ) {

				my $lChild = LayerData->new( $child->GetType(), $name, $nameSuffix, $child->GetTitle(), $child->GetInfo(), $child->GetOutput() );
				push( @{ $self->{"layers"} }, $lChild );

				$lChild->{"parent"} = $l;
			}
		}
	}
}

sub __GetFileName {
	my $self       = shift;
	my $lOutput    = shift;
	my $name       = shift;
	my $nameSuffix = shift;

	# 1) get new name
	my $oriL = $lOutput->GetOriLayer();

	$$name = $self->{"jobId"} . ValueConvertor->GetFileNameByLayer($oriL);
 

	# 2) verify if same name exist (consider only layer without parent)

	my @same = grep { !defined $_->{"parent"} && $_->{"name"} eq $$name } @{ $self->{"layers"} };

	if ( scalar(@same) ) {

		if ( scalar(@same) == 1 ) {
			$same[0]->{"nameSuffix"} = 1;
		}

		$$nameSuffix = scalar(@same) + 1;
	}

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

