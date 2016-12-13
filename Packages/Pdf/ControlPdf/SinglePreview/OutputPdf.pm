
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::Outputdf;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::ControlPdf::Enums';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	return $self;
}

sub OutputData {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my @prepared = $self->__PrepareLayers( \@layers );

}

sub __PrepareLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my @finalL = ();


	foreach my $lData (@layers) {
		
		my @singleL = $lData->GetSingleLayers();
		

		if ( $lData eq Enums->LayerData_STANDARD ) {
			
			
			if($lData->GetLayerCnt() == 1){
				
				@singleL
				
				
			}else{
				
				foreach my $sl (@singleL){
					
					
				}
				
				
			}
			
			
			$inCAM->COM( "merge_layers", "source_layer" => $plotL->{"outputLayer"}, "dest_layer" => $outputLName );
			

			CamLayer->RoutCompensation

			
			
			

		}
		elsif ( $lData eq Enums->LayerData_DRILLMAP ) {

		}
		elsif ( $lData eq Enums->LayerData_SUMMARY ) {

		}
	}
	
	return @finalL;

}

sub __OutputLayer {
	my $self = shift;
	my @layers = @{ shift(@_) };

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

