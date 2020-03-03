
#-------------------------------------------------------------------------------------------#
# Description: Dimension of production panel
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::ProductionPanel::PanelDimension;

use aliased 'Enums::EnumsProducPanel';
use aliased 'Packages::ProductionPanel::PanelDimension';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub GetDimensionPanel {
	my $self          = shift;
	my $inCAM         = shift;
	my $panelSizeName = shift;
	my %dimsPanel     = ();

	if ( $panelSizeName eq EnumsProducPanel->SIZE_MULTILAYER_SMALL ) {
		$dimsPanel{'PanelSizeX'}  = 307;
		$dimsPanel{'PanelSizeY'}  = 407;
		$dimsPanel{'BorderLeft'}  = 21;
		$dimsPanel{'BorderRight'} = 21;
		$dimsPanel{'BorderTop'}   = 41.6;
		$dimsPanel{'BorderBot'}   = 41.6;

	}
	elsif ( $panelSizeName eq EnumsProducPanel->SIZE_MULTILAYER_BIG ) {
		$dimsPanel{'PanelSizeX'}  = 307;
		$dimsPanel{'PanelSizeY'}  = 486.2;
		$dimsPanel{'BorderLeft'}  = 21;
		$dimsPanel{'BorderRight'} = 21;
		$dimsPanel{'BorderTop'}   = 41.6;
		$dimsPanel{'BorderBot'}   = 41.6;

	}
	elsif ( $panelSizeName eq EnumsProducPanel->SIZE_MULTILAYER_538 ) {
		$dimsPanel{'PanelSizeX'}  = 308;
		$dimsPanel{'PanelSizeY'}  = 538;
		$dimsPanel{'BorderLeft'}  = 21;
		$dimsPanel{'BorderRight'} = 21;
		$dimsPanel{'BorderTop'}   = 36.5;
		$dimsPanel{'BorderBot'}   = 36.5;
	}
	elsif ( $panelSizeName eq EnumsProducPanel->SIZE_STANDARD_SMALL ) {
		$dimsPanel{'PanelSizeX'}  = 295;
		$dimsPanel{'PanelSizeY'}  = 355;
		$dimsPanel{'BorderLeft'}  = 15;
		$dimsPanel{'BorderRight'} = 15;
		$dimsPanel{'BorderTop'}   = 15;
		$dimsPanel{'BorderBot'}   = 15;

	}
	elsif ( $panelSizeName eq EnumsProducPanel->SIZE_STANDARD_BIG ) {
		$dimsPanel{'PanelSizeX'}  = 295;
		$dimsPanel{'PanelSizeY'}  = 460;
		$dimsPanel{'BorderLeft'}  = 15;
		$dimsPanel{'BorderRight'} = 15;
		$dimsPanel{'BorderTop'}   = 15;
		$dimsPanel{'BorderBot'}   = 15;

	}
	elsif ( $panelSizeName eq EnumsProducPanel->SIZE_STANDARD_508 ) {
		$dimsPanel{'PanelSizeX'}  = 297;
		$dimsPanel{'PanelSizeY'}  = 508;
		$dimsPanel{'BorderLeft'}  = 15;
		$dimsPanel{'BorderRight'} = 15;
		$dimsPanel{'BorderTop'}   = 15;
		$dimsPanel{'BorderBot'}   = 15;
	}
	else {
		return (0);
	}
	return (%dimsPanel);
}

sub GetPanelName {
	my $self          = shift;
	my $inCAM         = shift;
	my $jobName       = shift;
	my $fileName      = shift;
	my @nameOfPanel   = ();
	my $panelSizeName = 0;

	use XML::Simple;
	use Data::Dumper;

	my $sufixFile = substr $fileName, -3;

	if ( $sufixFile =~ /[Xx][Mm][Ll]/ ) {

		my $getStructure = XMLin("$fileName");

		$panelSizeName = $self->GetPanelTypeByActiveArea( $inCAM, $jobName, $getStructure->{panel_width}, $getStructure->{panel_height} );

		return ($panelSizeName);
	}
	else {
		return (0);
	}

}

# Return type of "produce panel" from Enums::EnumsProducPanel
# computed
sub GetPanelType {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $pnlType  = undef;
	my %lim      = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );
	my $h        = abs( $lim{"yMin"} - $lim{"yMax"} );
	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	if ( $layerCnt <= 2 ) {

		if ( $h <= 355 ) {

			$pnlType = EnumsProducPanel->SIZE_STANDARD_SMALL;

		}
		elsif ( $h <= 460 ) {

			$pnlType = EnumsProducPanel->SIZE_STANDARD_BIG;

		}
		elsif ( $h <= 508 ) {
			$pnlType = EnumsProducPanel->SIZE_STANDARD_508;
		}

	}
	else {
		if ( $h <= 407 ) {
			$pnlType = EnumsProducPanel->SIZE_MULTILAYER_SMALL;
		}
		elsif ( $h <= 487 ) {
			$pnlType = EnumsProducPanel->SIZE_MULTILAYER_BIG;
		}
		elsif ( $h <= 538 ) {
			$pnlType = EnumsProducPanel->SIZE_MULTILAYER_538;
		}
	}

	return $pnlType;
}

# Return panel type based on active area
sub GetPanelTypeByActiveArea {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobName = shift;
	my $areaW   = shift;
	my $areaH   = shift;

	my $resultName = undef;

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobName );

	if ( $layerCnt > 2 ) {
		@nameOfPanel = ( EnumsProducPanel->SIZE_MULTILAYER_SMALL, EnumsProducPanel->SIZE_MULTILAYER_BIG, EnumsProducPanel->SIZE_MULTILAYER_538 );
	}
	else {
		@nameOfPanel = ( EnumsProducPanel->SIZE_STANDARD_SMALL, EnumsProducPanel->SIZE_STANDARD_BIG, EnumsProducPanel->SIZE_STANDARD_508 );
	}

	foreach my $name (@nameOfPanel) {
		my %dimsPanelHash = PanelDimension->GetDimensionPanel( $inCAM, $name );

		if (     _CompareTolerance( $dimsPanelHash{'PanelSizeX'}, ( $areaW + $dimsPanelHash{'BorderLeft'} + $dimsPanelHash{'BorderRight'} ) ) == 1
			 and _CompareTolerance( $dimsPanelHash{'PanelSizeY'}, ( $areaH + $dimsPanelHash{'BorderTop'} + $dimsPanelHash{'BorderBot'} ) ) == 1 )
		{
			$resultName = $name;
			last;
		}
	}

	return $resultName;
}

# return 1 when dimmension $reference and $testValue are in tolerance
sub _CompareTolerance {
	my $reference = shift;
	my $testValue = shift;
	my $tolerance = 10;      #in mm

	my $minTolerace = $reference - $tolerance;
	my $maxTolerace = $reference + $tolerance;

	if ( $testValue >= $minTolerace and $testValue <= $maxTolerace ) {
		return (1);
	}
	else {
		return (0);
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased "Packages::ProductionPanel::PanelDimension";
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "f77339";
	my $inCAM = InCAM->new();

	my $type = PanelDimension->GetPanelType( $inCAM, $jobId );

}

1;
