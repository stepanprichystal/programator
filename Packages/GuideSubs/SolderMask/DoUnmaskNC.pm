#-------------------------------------------------------------------------------------------#
# Description: Solder mask design editing
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::SolderMask::DoUnmaskNC;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::SolderMask::UnMaskNC';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamDrilling';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# If SMD is found, unmask through hole
sub UnMaskBGAThroughHole {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $step = "o+1";

	my $unMaskedCntRef   = 0;
	my $unMaskAttrValRef = "";

	my @NC = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );
	my @sm = map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "solder_mask" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	if ( scalar(@NC) && scalar(@sm) ) {

		my $resize          = -50;    # copy drill smaller about 50µm to solder mask
		my $minDistHole2Pad = 2000;    # 2000µm minimal distance of through hole to pad
		$result = UnMaskNC->UnMaskThroughHoleNearBGA( $inCAM, $jobId, $step, $resize, $minDistHole2Pad, \$unMaskedCntRef, \$unMaskAttrValRef );

		if ( $result && $unMaskedCntRef > 0 ) {

			my $lTmp = "unmask_hole_near_bga";

			my @sm =
			  map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "solder_mask" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

			CamLayer->AffectLayers( $inCAM, \@sm );

			if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".string", $unMaskAttrValRef ) ) {

				CamLayer->CopySelOtherLayer( $inCAM, [$lTmp], 0, 0 );
				CamLayer->WorkLayer( $inCAM, $lTmp );

				$inCAM->COM( "sel_change_sym", "symbol" => "cross1500x1500x200x200x50x50xr" );
			}

			my @mess = ();
			push( @mess, "Na desce byly nalezeny <b>otvory (" . $unMaskedCntRef . ") blízko BGA</b> plošek. Tyto otvory byly odmaskovány." );
			push( @mess, "" );
			push( @mess, "Zkontroluj tyto otvory jestli je vše ok. " );
			push( @mess, "Pozice otvorů jsou zkopírované v pomocné vrstvě: $lTmp." );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );    #  Script se zastavi
			$inCAM->PAUSE("Zkontroluj odmaskovane otvory blizko BGA plosek. Vrstva: $lTmp ");

			CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );
		}
	}

	return $result;
}

# If SMD is found, unmask through hole
sub UnMaskSMDThroughHole {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $messMngr = MessageMngr->new($jobId);

	my $step = "o+1";

	my $unMaskedCntRef   = 0;
	my $unMaskAttrValRef = "";

	my @NC = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );
	my @sm = map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "solder_mask" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	if ( scalar(@NC) && scalar(@sm) ) {

		my $resize          = -50;    # copy drill smaller about 50µm to solder mask
		my $minDistHole2Pad = 2000;    # 2000µm minimal distance of through hole to pad
		$result = UnMaskNC->UnMaskThroughHoleNearSMD( $inCAM, $jobId, $step, $resize, $minDistHole2Pad, \$unMaskedCntRef, \$unMaskAttrValRef )
		  ;

		if ( $result && $unMaskedCntRef ) {

			my $lTmp = "unmask_hole_near_smd";

			my @sm =
			  map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "solder_mask" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

			CamLayer->AffectLayers( $inCAM, \@sm );

			if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".string", $unMaskAttrValRef ) ) {

				CamLayer->CopySelOtherLayer( $inCAM, [$lTmp], 0, 0 );
				CamLayer->WorkLayer( $inCAM, $lTmp );

				$inCAM->COM( "sel_change_sym", "symbol" => "cross1500x1500x200x200x50x50xr" );
			}

			my @mess = ();
			push( @mess, "Na desce byly nalezeny <b>otvory (" . $unMaskedCntRef . ") blízko SMD </b> plošek. Tyto otvory byly odmaskovány." );
			push( @mess, "" );
			push( @mess, "Zkontroluj tyto otvory jestli je vše ok. " );
			push( @mess, "Pozice otvorů jsou zkopírované v pomocné vrstvě: $lTmp." );

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );    #  Script se zastavi
			$inCAM->PAUSE("Zkontroluj odmaskovane otvory blizko SMD plosek. Vrstva: $lTmp ");

			CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );

		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::SolderMask::DoUnmaskNC';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	my $inCAM = InCAM->new();

	my $jobId = "d272564";

	my $notClose = 0;

	my $res = DoUnmaskNC->UnMaskSMDThroughHole( $inCAM, $jobId );
	my $res2 = DoUnmaskNC->UnMaskBGAThroughHole( $inCAM, $jobId );

}

1;

