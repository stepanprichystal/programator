
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::StnclExport::Model::StnclCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;
use List::MoreUtils qw(uniq);

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper';
use aliased 'Programs::Stencil::StencilCreator::Enums' => 'StnclEnums';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerErrorInfo';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerWarnInfo';
use aliased 'Programs::Stencil::StencilLayer::StencilLayer';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Programs::Stencil::StencilSerializer::StencilSerializer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;

	my $inCAM     = $dataMngr->{"inCAM"};
	my $jobId     = $dataMngr->{"jobId"};
	my $step      = "panel";
	my $groupData = $dataMngr->GetGroupData();

	my $defaultInfo  = $dataMngr->GetDefaultInfo();
	my $customerNote = $defaultInfo->GetCustomerNote();

	my %stencilInfo = Helper->GetStencilInfo($jobId);

	my $workLayer = "ds";

	if ( $stencilInfo{"tech"} eq StnclEnums->Technology_DRILL ) {
		$workLayer = "flc";
	}

	# 1) test if thickness is not null
	my $thickness = $groupData->GetThickness();

	if ( !defined $thickness || $thickness eq "" || $thickness == 0 ) {

		$dataMngr->_AddErrorResult( "Tlou????ka ??ablony", "Tlou????ka ??ablony nen?? definov??na." );
	}

	# 2) Kontrola na chyb??j??c?? materi??l
	my $materialKindIS = $defaultInfo->GetMaterialKind();
	$materialKindIS =~ s/[\s\t]//g;
	if ( $stencilInfo{"tech"} eq StnclEnums->Technology_DRILL && !defined $materialKindIS ) {

		$dataMngr->_AddErrorResult(
									"Materi??l ??ablony",
									"Druh materi??lu ??ablony (AL_CORE; ... ) nen??  definov??n v IS."
									  . " Materi??l je nutn?? definovat, aby bylo mo??n?? nastavit parametry vrt??n??."
		);
	}

	# 2) test if stencil layer exist
	unless ( $defaultInfo->LayerExist($workLayer) ) {
		$dataMngr->_AddErrorResult( "Zdrojov?? data",
									"Vrstva \"$workLayer\" chyb??. Vrstva mus?? b??t vytvo??ena, aby bylo mo??n?? DPS vyexportovat." );
	}

	# 3) test on drill  stencils
	if ( $stencilInfo{"tech"} eq StnclEnums->Technology_DRILL ) {

		my @layers = ( CamJob->GetLayerByType( $inCAM, $jobId, "drill" ), CamJob->GetLayerByType( $inCAM, $jobId, "rout" ) );

		if ( scalar(@layers) > 1 ) {

			my $str = join( ",", map { $_->{"gROWname"} } grep { $_->{"gROWname"} ne "flc" } @layers );

			$dataMngr->_AddErrorResult( "rout/drill vrsvty", "Jedinn?? vrstva, kter?? m????e b??t typu rout je \"flc\". Sma?? $str." );
		}
	}

	# Kontrola vrstvy flc
	if ( $stencilInfo{"tech"} eq StnclEnums->Technology_DRILL ) {

		# 2) Checking NC layers
		my $messErr = "";    # errors

		unless ( LayerErrorInfo->CheckNCLayers( $inCAM, $jobId, $step, undef, \$messErr ) ) {
			$dataMngr->_AddErrorResult( "Checking NC layer", $messErr );

			# Do not continue in other check if this  "basic" check fail
			return 0;
		}

		my $messWarn = "";    # warnings

		unless ( LayerWarnInfo->CheckNCLayers( $inCAM, $jobId, $step, undef, \$messWarn ) ) {
			$dataMngr->_AddWarningResult( "Checking NC layer", $messWarn );
		}
	}

	# 4) If half fiducial checked, find in layer bz atribute fiducial_layer
	my $inf = $groupData->GetFiducialInfo();
	if ( $inf->{"halfFiducials"} ) {

		my %attHist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, "o+1", $workLayer );
		my $attVal = $attHist{".fiducial_name"};

		unless ( $attVal->{"_totalCnt"} ) {
			$dataMngr->_AddErrorResult(
								  "Fiducials",
								  "Je zvolen?? volba vyp??len?? fiduci??ln??ch zna??ek do poloviny, ale zna??ky nebyly nalezeny (vrstva: $workLayer)."
									. " P??idej po??adovan??m zna??k??m atribut \".fiducial_name\"."
			);
		}

		if ( $attVal->{"_totalCnt"} > 0 && $attVal->{"_totalCnt"} != 2 && $attVal->{"_totalCnt"} != 3 ) {

			$dataMngr->_AddWarningResult( "Fiducials",
							 "Byl nalezen netypick?? po??et fiduci??ln??ch zna??ek: " . $attVal->{"_totalCnt"} . " (vrstva: $workLayer). Je to ok?" );
		}

		if ( $inf->{"fiducSide"} ne "readable" && $inf->{"fiducSide"} ne "nonreadable" ) {

			$dataMngr->_AddErrorResult( "Fiducials", "Nen?? uvedeno z jak?? strany vyp??lit fiduci??ln?? zna??ky" );
		}
	}

	# Check if data layer was not changed by user. If so do not draw dimensions to PDF
	if ( $groupData->GetExportPdf() && $groupData->GetDim2ControlPdf() ) {
		my $stnclSer = StencilSerializer->new($jobId);

		if ( $stnclSer->StencilParamsExists() ) {

			my $lTMP = GeneralHelper->GetGUID();
			my $stncl = StencilLayer->new( $inCAM, $jobId, $stnclSer->LoadStenciLParams(), $lTMP );
			$stncl->PrepareLayer();
			CamHelper->SetStep( $inCAM, "o+1" );

			# Compare this layer with original, if there are some differences
			# Merge inverted tmp layer and compute surface area

			my $lCmpUsr = undef;
			my $lCmpOri = undef;

			if ( $stencilInfo{"tech"} eq StnclEnums->Technology_DRILL ) {

				$lCmpOri = CamLayer->RoutCompensation( $inCAM, $lTMP,      'document' );
				$lCmpUsr = CamLayer->RoutCompensation( $inCAM, $workLayer, 'document' );
			}
			else {

				$lCmpOri = GeneralHelper->GetGUID();
				$lCmpUsr = GeneralHelper->GetGUID();
				$inCAM->COM( "merge_layers", "source_layer" => $lTMP,      "dest_layer" => $lCmpOri, "invert" => "no" );
				$inCAM->COM( "merge_layers", "source_layer" => $workLayer, "dest_layer" => $lCmpUsr, "invert" => "no" );

			}
			
			CamLayer->WorkLayer( $inCAM, $lCmpOri );
			CamLayer->Contourize( $inCAM, $lCmpOri );
			CamLayer->WorkLayer( $inCAM, $lCmpUsr );
			CamLayer->Contourize( $inCAM, $lCmpUsr );

			CamMatrix->DeleteLayer( $inCAM, $jobId, $lTMP );

			$inCAM->COM( "merge_layers", "source_layer" => $lCmpOri, "dest_layer" => $lCmpUsr, "invert" => "yes" );
			CamLayer->WorkLayer( $inCAM, $lCmpUsr );
			CamLayer->Contourize( $inCAM, $lCmpUsr );

			# check if layer is not empty
			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $lCmpUsr );

			if ( $hist{"total"} > 0 ) {
				my $newName = "stencil_data_ori";

				CamMatrix->DeleteLayer( $inCAM, $jobId, $newName );
				CamMatrix->RenameLayer( $inCAM, $jobId, $lCmpOri, $newName );

				$dataMngr->_AddWarningResult(
											  "??prava dat vrstvy $workLayer ",
											  "Ve vrstv??: \"$workLayer\", byl pravd??podobn?? proveden ru??n?? z??sah u??ivatelem. "
												. "K??ty a obrysy v kontroln??m PDF nebudou sed??t motivem ??ablony. "
												. "Zkontroluj originalni vrstvu: \"$newName\" s vrstvou ??ablony: \"$workLayer\", "
												. "pop????pad?? vypni kreslen?? k??t do kontroln??ho PDF (checkbox: Draw dimension)"
				);

			}
			else {
				CamMatrix->DeleteLayer( $inCAM, $jobId, $lCmpOri );

			}

			CamMatrix->DeleteLayer( $inCAM, $jobId, $lCmpUsr );
		}

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

