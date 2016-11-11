
#-------------------------------------------------------------------------------------------#
# Description: Dimension of production panel
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::ProductionPanel::PanelDimension;


use aliased 'Enums::EnumsProducPanel';
use aliased 'Packages::ProductionPanel::PanelDimension';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub GetDimensionPanel {
	my $self  = shift;
	my $inCAM = shift;
	my $panelSizeName = shift;
	my %dimsPanel = ();

		    if ($panelSizeName eq EnumsProducPanel->SIZE_MULTILAYER_SMALL) {
				$dimsPanel{'PanelSizeX'} = 307;
				$dimsPanel{'PanelSizeY'} = 407;
				$dimsPanel{'BorderLeft'} = 21;
				$dimsPanel{'BorderRight'} = 21;
				$dimsPanel{'BorderTop'} = 41.6;
				$dimsPanel{'BorderBot'} = 41.6;
							
		}elsif ($panelSizeName eq EnumsProducPanel->SIZE_MULTILAYER_BIG) {
				$dimsPanel{'PanelSizeX'} = 307;
				$dimsPanel{'PanelSizeY'} = 486.2;
				$dimsPanel{'BorderLeft'} = 21;
				$dimsPanel{'BorderRight'} = 21;
				$dimsPanel{'BorderTop'} = 41.6;
				$dimsPanel{'BorderBot'} = 41.6;

		}elsif ($panelSizeName eq EnumsProducPanel->SIZE_STANDARD_SMALL) {
				$dimsPanel{'PanelSizeX'} = 295;
				$dimsPanel{'PanelSizeY'} = 355;
				$dimsPanel{'BorderLeft'} = 15;
				$dimsPanel{'BorderRight'} = 15;
				$dimsPanel{'BorderTop'} = 15;
				$dimsPanel{'BorderBot'} = 15;

		}elsif ($panelSizeName eq EnumsProducPanel->SIZE_STANDARD_BIG) {
				$dimsPanel{'PanelSizeX'} = 295;
				$dimsPanel{'PanelSizeY'} = 460;
				$dimsPanel{'BorderLeft'} = 15;
				$dimsPanel{'BorderRight'} = 15;
				$dimsPanel{'BorderTop'} = 15;
				$dimsPanel{'BorderBot'} = 15;

		}else{
			return(0);
		}
	return(%dimsPanel);
}

sub GetPanelName {
		my $self = shift;
		my $inCAM = shift;
		my $jobName = shift;
		my $fileName = shift;
		my @nameOfPanel = ();
		my $panelSizeName = 0;
		
		
		use XML::Simple;
		use Data::Dumper;

		my $getStructure = XMLin("$fileName");
		
		
		
				if (HegMethods->GetTypeOfPcb($jobName) eq 'Vicevrstvy') {
						@nameOfPanel = (EnumsProducPanel->SIZE_MULTILAYER_SMALL, EnumsProducPanel->SIZE_MULTILAYER_BIG);
				}else{
						@nameOfPanel = (EnumsProducPanel->SIZE_STANDARD_SMALL, EnumsProducPanel->SIZE_STANDARD_BIG);
				}

				foreach my $panel (@nameOfPanel){
								my %dimsPanelHash = PanelDimension->GetDimensionPanel($inCAM, $panel);
								
										if (_CompareTolerance($dimsPanelHash{'PanelSizeX'}, ($getStructure->{panel_width} + $dimsPanelHash{'BorderLeft'} + $dimsPanelHash{'BorderRight'} )) == 1 and 
											_CompareTolerance($dimsPanelHash{'PanelSizeY'}, ($getStructure->{panel_height} + $dimsPanelHash{'BorderTop'} + $dimsPanelHash{'BorderBot'} )) == 1) {
													$panelSizeName = $panel;
										}
				}
		return ($panelSizeName);
				

}



# return 1 when dimmension $reference and $testValue are in tolerance
sub _CompareTolerance {
		my $reference = shift;
		my $testValue = shift;
		my $tolerance = 2; #in mm
		
		my $minTolerace = $reference - $tolerance;
		my $maxTolerace = $reference + $tolerance;
		
		
		if ($testValue >= $minTolerace and $testValue <= $maxTolerace) {
				return(1);
		}else{
				return(0);
		}
}
1;