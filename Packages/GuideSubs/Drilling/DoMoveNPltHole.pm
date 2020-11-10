#-------------------------------------------------------------------------------------------#
# Description: Move small nonplated hole to plated layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Drilling::DoMoveNPltHole;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::Drilling::MoveDrillHoles';
use aliased 'Packages::CAMJob::Drilling::NPltDrillCheck';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStep';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Go through all edit steps and move small NPTH hole from NPTH to PTH layer
sub MoveSmallNpth2Pth {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $step = "o+1";

	my $unMaskedCntRef   = 0;
	my $unMaskAttrValRef = "";

	my $maxTool  = 1000;
	my $pltLayer = "m";

	if ( CamHelper->LayerExists( $inCAM, $jobId, $pltLayer ) ) {

		my @childs = CamStep->GetJobEditSteps( $inCAM, $jobId );
		my @nplt =
		  map { $_->{"gROWname"} }
		  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_nplt_nDrill ] );

		foreach my $s (@childs) {

			foreach my $npltLayer (@nplt) {

				my $checkRes = {};
				unless ( NPltDrillCheck->SmallNPltHoleCheck( $inCAM, $jobId, $s, $npltLayer, $pltLayer, $maxTool, $checkRes ) ) {

					my $movedHoleCntRef     = -1;
					my $movedHoleAttrValRef = -1;
					my $res = MoveDrillHoles->MoveSmallNpth2Pth( $inCAM, $jobId, $s, $npltLayer, $pltLayer, $maxTool, \$movedHoleCntRef,
																 \$movedHoleAttrValRef );

					if ($res) {

						my $lTmp = "moved_npth_holes";

						CamLayer->WorkLayer( $inCAM, $pltLayer );
						if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".string", $movedHoleAttrValRef ) ) {

							CamLayer->CopySelOtherLayer( $inCAM, [$lTmp], 0, 0 );
							CamLayer->WorkLayer( $inCAM, $lTmp );

							$inCAM->COM( "sel_change_sym", "symbol" => "cross3500x3500x500x500x50x50xr" );

							CamLayer->DisplayLayers( $inCAM, [ $lTmp, $pltLayer  ] );

							my @mess = ();
							push( @mess,
								      "V neprokovené vrstvě: $npltLayer byly nalezeny otvory ("
									. $movedHoleCntRef
									. ") o průměru <= "
									. $maxTool
									. "µm." );

							push( @mess, "<g>Otvory byly přesunuty do prokovené vrstvy: $pltLayer.</g>" );
							push( @mess, "Zkontroluj je, jestli je vše ok. Pozice otvorů jsou zkopírované v pomocné vrstvě: $lTmp." );
							push( @mess, "" );
							push( @mess, "<b>Přesouvají se pouze následující otvory:</b>" );
							push( @mess, " - Průměr nástroje  <= " . $maxTool . "µm" );
							push( @mess, " - neobsahující atribut .pilot_holes" );
							push( @mess, " - neobsahující toleranci v DTM" );
							push( @mess, "" );

							$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );        #  Script se zastavi
							$inCAM->PAUSE("Zkontroluj presunute neprokovene otvory. Vrstva: $lTmp ");

							CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );
							CamLayer->ClearLayers($inCAM);

						}

					}
					else {

						die "Error durin moving NPTH holes";
					}

				}
			}
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Drilling::DoMoveNPltHole';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d298152";

	my $notClose = 0;

	my $res = DoMoveNPltHole->MoveSmallNpth2Pth( $inCAM, $jobId );

	#my $res2 = DoUnmaskNC->UnMaskBGAThroughHole( $inCAM, $jobId );

}

1;

