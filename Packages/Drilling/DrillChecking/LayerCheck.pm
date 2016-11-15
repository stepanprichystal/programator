#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with drilling
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Drilling::DrillChecking::LayerCheck;

#3th party library

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::FileHelper';
#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#


 sub CheckWrongNames{
  	my $self = shift;
 	my $mess = shift; 
 	
 	my $succ = 0;
 	
 	
 	
 	
 }


 sub CheckBlindDrill{
 	my $self = shift;
 	my $inCAM = shift;
 	my $jobId = shift;
 	
 	my $mess = shift; 
 		
  	my @drillLayers = @{shift(@_)}; 	
 	
 	my $succ = 0;
 	
 	@layers  = grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop ||  $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot } @drillLayers;
 	
 	foreach my $l (@layers){
 		
 		 
 		
 		#get depths for all diameter
		my @toolDepths = $self->GetToolDepths( $inCAM, $jobId, "panel", $_->{"gROWname"} );
		@toolDepths
 		
 		
 		
 	}
 	
 	
 	
 }
 
 
 
# Function return max aspect ratio from all holes and their depths. For given layer
sub GetMaxAspectRatioByLayer {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;

	#get depths for all diameter
	my @toolDepths = $self->GetToolDepths( $inCAM, $jobId, "panel", $layerName );

	$inCAM->INFO(
				  units       => 'mm',
				  entity_type => 'layer',
				  entity_path => "$jobId/$stepName/$layerName",
				  data_type   => 'TOOL',
				  parameters  => 'drill_size+shape',
				  options     => "break_sr"
	);
	my @toolSize  = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
	my @toolShape = @{ $inCAM->{doinfo}{gTOOLshape} };

	my $aspectRatio;

	for ( my $i = 0 ; $i < scalar(@toolSize) ; $i++ ) {

		my $tSize = $toolSize[$i];
		my $s     = $toolShape[$i];

		if ( $s ne 'hole' ) {
			next;
		}

		#for each hole diameter, get depth (in mm)
		my $tDepth;

		my $prepareOk = $self->PrepareToolDepth( $tSize, \@toolDepths, \$tDepth );
		unless ($prepareOk) {
			next;
		}

		my $tmp = ( $tDepth * 1000 ) / $tSize;

		if ( !defined $aspectRatio || $tmp > $aspectRatio ) {

			$aspectRatio = $tmp;
		}

	}
	return $aspectRatio;
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $test = StackupLayerHelper->GetStackupPress("F14742");

 
	#print $test;

}

1;
