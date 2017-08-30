#-------------------------------------------------------------------------------------------#
# Description: Helper module for InCAM Drill tool manager
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::ProductionPanel::CheckPanel;

#3th party library
use strict;
use warnings;

#loading of locale modules
#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Managers::MessageMngr::MessageMngr';

use aliased 'Enums::EnumsGeneral';

use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamGoldArea';


use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::Stackup::StackupOperation';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub RunCheckOfPanel {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my @errorList = ();

	push @errorList, _CheckCountOfPcb( $inCAM, $jobId );
	push @errorList, _CheckPolarityInnerLayer( $inCAM, $jobId );
	push @errorList, _CheckDimDepensMaterial( $inCAM, $jobId );
	push @errorList, _CheckDimGalvanicGold( $inCAM, $jobId );

	#push @errorList, _CheckBlindAndGalvGold($inCAM, $jobId);

	@errorList = grep { $_ ne '' } @errorList;
	if ( scalar @errorList ) {	
		_AppearsGUI( $jobId, @errorList );
	}
}


# Warning when you have panel more then 407 for galvanic gold.
sub _CheckDimGalvanicGold {
	my $inCAM = shift;
	my $jobId = shift;
	my $info;
	
	my %dim = JobDim->GetDimension( $inCAM, $jobId );
	my %result = CamGoldArea->GetGoldFingerArea(18, 1.50, $inCAM, $jobId, 'panel');	# If exist attr .gold_plating
	my $surface = HegMethods->GetPcbSurface($jobId);									# If exist surface 'plosne galvanicke zlaceni'

		if ($result{"exist"} == 1 or $surface eq 'G') {
				if ($dim{"vyrobni_panel_y"} > 407 ) {
						$info ='- Pozor, panel vetsi nez 407 nelze pouzit pro zlaceni! Uprav velikost panelu!';
				}
		}
	return ($info);
}

# Warning that your panel has width 305 but not AL_core
sub _CheckDimDepensMaterial {
	my $inCAM = shift;
	my $jobId = shift;
	my $info;

	my %dim = JobDim->GetDimension( $inCAM, $jobId );
	
	

			if ($dim{"vyrobni_panel_x"} == 305 or $dim{"vyrobni_panel_x"} == 230) {
					unless (HegMethods->GetMaterialKind( $jobId, 0 ) eq 'AL_CORE') {
						
						$info ='- Zkontroluj nestandardni rozmer panelu, ' . $dim{"vyrobni_panel_x"} . 'x' . $dim{"vyrobni_panel_y"};
					}
			}
	
	return ($info);
}	
	
# Check count of pcb in HEG against panel pcb
# because whe exist offer so exist count of pcb in HEG
sub _CheckCountOfPcb {
	my $inCAM = shift;
	my $jobId = shift;
	my $info;
	my $nasInPanel = 0;

	my @infoPcbOffer = HegMethods->GetAllByPcbId($jobId);
	my $nasInHeg     = $infoPcbOffer[0]{'n_nasobnost'};

	my %dim = JobDim->GetDimension( $inCAM, $jobId );

	$nasInPanel = $dim{"nasobnost"};

	if ($nasInHeg) {
		if ( $nasInHeg != $nasInPanel ) {
			$info =
'- Zkontroluj nasobnost v HEGu a nasobnost panelu, jelikoz se neshoduje.';
		}
	}

	return ($info);
}

sub _CheckBlindAndGalvGold {
	my $inCAM = shift;
	my $jobId = shift;
	my $info;

	#return($info);
}

sub _CheckPolarityInnerLayer {
	my $inCAM = shift;
	my $jobId = shift;
	my $info;

	if ( HegMethods->GetTypeOfPcb($jobId) eq 'Vicevrstvy' ) {

		my @layerList = CamJob->GetSignalLayerNames( $inCAM, $jobId );
		my @innerLayerList = grep { $_ =~ /v\d{1,}/ } @layerList;

		my %layAttrPanel   = ();
		my %layAttrStackup = ();
		foreach my $layer (@innerLayerList) {
			my %layerAttr =
			  CamAttributes->GetLayerAttr( $inCAM, $jobId, 'panel', $layer );

			$layAttrStackup{$layer} =
			  StackupOperation->GetSideByLayer( $jobId, $layer );

			$layAttrPanel{$layer} = $layerAttr{'layer_side'};
		}

		foreach my $layerID ( keys %layAttrStackup ) {
			unless ( $layAttrStackup{$layerID} eq $layAttrPanel{$layerID} ) {
				$info =
'- Zkontroluj nastaveni vnitrnich vrstev TOP / BOT , protoze nesedi se slozenim.';
			}
		}
	}
	return ($info);
}

sub _AppearsGUI {
	my $jobId     = shift;
	my @errorList = @_;

	my $messMngr = MessageMngr->new($jobId);

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@errorList )
	  ;    #  Script se zastavi

}

1;
