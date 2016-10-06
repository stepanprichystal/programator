
#-------------------------------------------------------------------------------------------#
# Description: Dimension of production panel
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::ProductionPanel::PanelDimension;


use aliased 'Enums::EnumsProducPanel';

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

1;