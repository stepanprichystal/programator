
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
use aliased 'Packages::Gerbers::OutputData::Enums';

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

		my $oriL = $lOutput->GetOriLayer();

		my $fileName = ValueConvertor->GetFileNameByLayer($oriL);
 
		if ( defined $lOutput->GetNumber() ) {
			$fileName .= "_" . $lOutput->GetNumber();
		}
		
		if(  $lOutput->GetType() eq Enums->Type_DRILLMAP){
			$fileName .= "_map";
		}
		
	
		$fileName = $self->{"jobId"}.$fileName.".ger";

		my $l = LayerData->new( $lOutput->GetType(), $fileName, $lOutput->GetTitle(), $lOutput->GetInfo(), $lOutput->GetOutput() );

		push( @{ $self->{"layers"} }, $l );

	}
}

sub GetLayers {
	my $self      = shift;
 
	return  @{ $self->{"layers"} };
}

sub GetLayersByType {
	my $self      = shift;
 	my $type      = shift;
 	
 	
 	my @layers = grep { $_->GetType() eq $type } @{ $self->{"layers"} };
 	
	return @layers ;
}

sub GetStepName {
	my $self      = shift;
 
	return  $self->{"stepName"};
}


sub SetStepName {
	my $self      = shift;
 
	$self->{"stepName"} = shift;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

