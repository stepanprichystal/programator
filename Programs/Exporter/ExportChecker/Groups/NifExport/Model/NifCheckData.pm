
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;
use List::Util qw[max min];
use List::Util qw(first);

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper';
use aliased 'Helpers::ValueConvertor';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamChecklist';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::Tooling::PressfitOperation';
use aliased 'Packages::CAMJob::Marking::MarkingDataCode';
use aliased 'Packages::CAMJob::Marking::MarkingULLogo';
use aliased 'Packages::CAMJob::Technology::CuLayer';
use aliased 'Packages::CAMJob::PCBConnector::InLayersClearanceCheck';
use aliased 'Packages::CAMJob::PCBConnector::PCBConnectorCheck';
use aliased 'Packages::CAMJob::Checklist::PCBClassCheck';
use aliased 'Packages::TifFile::TifRevision';
use aliased 'Enums::EnumsChecklist';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => "FiltrEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

# Checking group data before final export
# Errors, warnings are passed to <$dataMngr>
sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = $dataMngr->GetGroupData();

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my $inCAM    = $dataMngr->{"inCAM"};
	my $jobId    = $dataMngr->{"jobId"};
	my $stepName = "panel";

	# 1) datacode
	my $datacodeLayer = $self->__CheckDataCodeIS( $jobId, $groupData );

	unless ( defined $datacodeLayer ) {
		$dataMngr->_AddErrorResult( "Data code", "Nesedí zadaný datacode v heliosu s datacodem v exportu." );
	}

	if ( $defaultInfo->GetCustomerNote()->InsertDataCode() && !defined $datacodeLayer ) {
		$dataMngr->_AddWarningResult( "Chybějící Data code", "Zákazník požaduje vždy vložit datakód, volba Datacode však není aktivní." );
	}

	my $errMessDC = "";
	unless ( $self->__CheckDataCodeJob( $inCAM, $jobId, $defaultInfo, $groupData->GetDatacode(), \$errMessDC ) ) {
		$dataMngr->_AddWarningResult( "Data code", $errMessDC );
	}

	# 2) ul logo
	my $ulLogoLayer = $self->__CheckUlLogoIS( $jobId, $groupData );

	unless ( defined $ulLogoLayer ) {
		$dataMngr->_AddErrorResult( "UL logo", "Nesedí zadané Ul logo v heliosu s datacodem v exportu." );
	}

	if ( $defaultInfo->GetCustomerNote()->InsertULLogo() && !defined $ulLogoLayer ) {
		$dataMngr->_AddWarningResult( "Chybějící UL logo", "Zákazník požaduje vždy vložit ULLogo, volba ULlogo však není aktivní." );
	}

	my $errMessUl = "";
	unless ( $self->__CheckULLogoJob( $inCAM, $jobId, $defaultInfo, $groupData->GetUlLogo(), \$errMessUl ) ) {
		$dataMngr->_AddWarningResult( "UL logo", $errMessUl );
	}

	# 3) mask control
	my %masks        = CamLayer->ExistSolderMasks( $inCAM, $jobId );
	my $topMaskExist = $defaultInfo->LayerExist("mc");
	my $botMaskExist = $defaultInfo->LayerExist("ms");

	# Control mask existence
	if ( $masks{"top"} != $topMaskExist ) {

		$dataMngr->_AddErrorResult( "Maska TOP", "Nesedí maska top v metrixu jobu a ve formuláři Heliosu" );
	}
	if ( $masks{"bot"} != $botMaskExist ) {

		$dataMngr->_AddErrorResult( "Maska BOT", "Nesedí maska bot v metrixu jobu a ve formuláři Heliosu" );
	}

	my %masks2        = CamLayer->ExistSolderMasks( $inCAM, $jobId, 1 );
	my $topMask2Exist = $defaultInfo->LayerExist("mc2");
	my $botMask2Exist = $defaultInfo->LayerExist("ms2");

	if ( $masks2{"top"} != $topMask2Exist ) {

		$dataMngr->_AddErrorResult( "Maska 2 TOP", "Nesedí maska 2 top v metrixu jobu a ve formuláři Heliosu" );
	}
	if ( $masks2{"bot"} != $botMask2Exist ) {

		$dataMngr->_AddErrorResult( "Maska 2 BOT", "Nesedí maska 2 bot v metrixu jobu a ve formuláři Heliosu" );
	}

	# 4) Control mask colour
	my %masksColorIS        = HegMethods->GetSolderMaskColor($jobId);
	my $masksColorTopExport = $groupData->GetC_mask_colour();
	my $masksColorBotExport = $groupData->GetS_mask_colour();

	if ( $masksColorIS{"top"} ne $masksColorTopExport ) {

		$dataMngr->_AddErrorResult(
									"Maska TOP",
									"Nesedí barva masky top. Export =>"
									  . ValueConvertor->GetMaskCodeToColor($masksColorTopExport)
									  . ", Helios => "
									  . ValueConvertor->GetMaskCodeToColor( $masksColorIS{"top"} ) . "."
		);
	}
	if ( $masksColorIS{"bot"} ne $masksColorBotExport ) {

		$dataMngr->_AddErrorResult(
									"Maska BOT",
									"Nesedí barva masky bot. Export =>"
									  . ValueConvertor->GetMaskCodeToColor($masksColorBotExport)
									  . ", Helios => "
									  . ValueConvertor->GetMaskCodeToColor( $masksColorIS{"bot"} ) . "."
		);
	}

	my %masksColor2IS        = HegMethods->GetSolderMaskColor2($jobId);
	my $masksColorTop2Export = $groupData->GetC_mask_colour2();
	my $masksColorBot2Export = $groupData->GetS_mask_colour2();

	if ( $masksColor2IS{"top"} ne $masksColorTop2Export ) {

		$dataMngr->_AddErrorResult(
									"Maska 2 TOP",
									"Nesedí barva masky 2 top. Export =>"
									  . ValueConvertor->GetMaskCodeToColor($masksColorTop2Export)
									  . ", Helios => "
									  . ValueConvertor->GetMaskCodeToColor( $masksColor2IS{"top"} ) . "."
		);
	}
	if ( $masksColor2IS{"bot"} ne $masksColorBot2Export ) {

		$dataMngr->_AddErrorResult(
									"Maska 2 BOT",
									"Nesedí barva masky 2 bot. Export =>"
									  . ValueConvertor->GetMaskCodeToColor($masksColorBot2Export)
									  . ", Helios => "
									  . ValueConvertor->GetMaskCodeToColor( $masksColor2IS{"bot"} ) . "."
		);
	}

	# 5) silk
	my %silk         = CamLayer->ExistSilkScreens( $inCAM, $jobId );
	my $topSilkExist = $defaultInfo->LayerExist("pc");
	my $botSilkExist = $defaultInfo->LayerExist("ps");

	# Control silk existence
	if ( $silk{"top"} != $topSilkExist ) {

		$dataMngr->_AddErrorResult( "Potisk TOP", "Nesedí potisk top v metrixu jobu a ve formuláři Heliosu" );
	}
	if ( $silk{"bot"} != $botSilkExist ) {

		$dataMngr->_AddErrorResult( "Potisk BOT", "Nesedí potisk bot v metrixu jobu a ve formuláři Heliosu" );
	}

	my %silk2         = CamLayer->ExistSilkScreens( $inCAM, $jobId, 1 );
	my $topSilk2Exist = $defaultInfo->LayerExist("pc2");
	my $botSilk2Exist = $defaultInfo->LayerExist("ps2");

	# Control silk existence
	if ( $silk2{"top"} != $topSilk2Exist ) {

		$dataMngr->_AddErrorResult( "Potisk TOP 2", "Nesedí druhý potisk top v metrixu jobu a ve formuláři Heliosu" );
	}
	if ( $silk2{"bot"} != $botSilk2Exist ) {

		$dataMngr->_AddErrorResult( "Potisk BOT 2", "Nesedí druhý potisk bot v metrixu jobu a ve formuláři Heliosu" );
	}

	# 6) Control silk colour
	my %silkColorIS        = HegMethods->GetSilkScreenColor($jobId);
	my $silkColorTopExport = $groupData->GetC_silk_screen_colour();
	my $silkColorBotExport = $groupData->GetS_silk_screen_colour();

	$silkColorIS{"top"} = "" if ( !defined $silkColorIS{"top"} );
	$silkColorIS{"bot"} = "" if ( !defined $silkColorIS{"bot"} );

	if ( $silkColorIS{"top"} ne $silkColorTopExport ) {

		$dataMngr->_AddErrorResult(
									"Potisk TOP",
									"Nesedí barva potisku top. Export =>"
									  . ValueConvertor->GetSilkCodeToColor($silkColorTopExport)
									  . ", Helios => "
									  . ValueConvertor->GetSilkCodeToColor( $silkColorIS{"top"} ) . "."
		);
	}
	if ( $silkColorIS{"bot"} ne $silkColorBotExport ) {

		$dataMngr->_AddErrorResult(
									"Potisk BOT",
									"Nesedí barva potisku bot. Export =>"
									  . ValueConvertor->GetSilkCodeToColor($silkColorBotExport)
									  . ", Helios => "
									  . ValueConvertor->GetSilkCodeToColor( $silkColorIS{"bot"} ) . "."
		);
	}

	# 6) Control silk colour 2
	my %silkColor2IS        = HegMethods->GetSilkScreenColor2($jobId);
	my $silkColorTop2Export = $groupData->GetC_silk_screen_colour2();
	my $silkColorBot2Export = $groupData->GetS_silk_screen_colour2();

	$silkColor2IS{"top"} = "" if ( !defined $silkColor2IS{"top"} );
	$silkColor2IS{"bot"} = "" if ( !defined $silkColor2IS{"bot"} );

	if ( $silkColor2IS{"top"} ne $silkColorTop2Export ) {

		$dataMngr->_AddErrorResult(
									"Potisk TOP",
									"Nesedí barva druhého potisku top. Export =>"
									  . ValueConvertor->GetSilkCodeToColor($silkColorTop2Export)
									  . ", Helios => "
									  . ValueConvertor->GetSilkCodeToColor( $silkColor2IS{"top"} ) . "."
		);
	}
	if ( $silkColor2IS{"bot"} ne $silkColorBot2Export ) {

		$dataMngr->_AddErrorResult(
									"Potisk BOT",
									"Nesedí barva druhého potisku bot. Export =>"
									  . ValueConvertor->GetSilkCodeToColor($silkColorBot2Export)
									  . ", Helios => "
									  . ValueConvertor->GetSilkCodeToColor( $silkColor2IS{"bot"} ) . "."
		);
	}

	# X) Warn user if solder mask 2 was automatically generated from solder mask 1

	my @mask2 = grep { $_->{"gROWname"} =~ /^m[cs]2$/ } $defaultInfo->GetBoardBaseLayers();

	foreach my $l (@mask2) {

		my %attr = CamAttributes->GetLayerAttr( $inCAM, $jobId, $stepName, $l->{"gROWname"} );
		if ( defined $attr{"export_fake_layer"} && $attr{"export_fake_layer"} eq "yes" ) {

			$dataMngr->_AddWarningResult(
										  "Generated data for solder mask 2",
										  "V IS byl nalezen požadavek pro druhou nepájivou masku. Data vrstvy: "
											. $l->{"gROWname"}
											. ", budou automaticky vygenerována z vrstvy: "
											. ( $l->{"gROWname"} =~ /^(m[cs])/ )[0]
											. ". Motivy obou masek budou stejné, je to ok?"
			);

		}
	}

	# X) Check technogy
	# If layer cnt is => 2 technology should be galvanics (if there are plated drill layers), in other case resist
	if ( $defaultInfo->GetLayerCnt() >= 2 && $groupData->GetTechnology() eq EnumsGeneral->Technology_RESIST ) {

		my $cu = $defaultInfo->GetBaseCuThick(" c ");
		$dataMngr->_AddWarningResult(
									  " Technology ",
									  "DPS má zvolenou technologii \"Leptací resist\". "
										. "Tedy DPS nebude prokovená a výsledná Cu bude základní ("
										. $cu
										. "µm). "
										. "Je to pro zákazníka akceptovatelné?"
		);

	}

	# 8) Check if goldfinger exist, if area is greater than 10mm^2

	if ( $defaultInfo->LayerExist("c") && $defaultInfo->GetPcbType() ne EnumsGeneral->PcbType_NOCOPPER ) {

		my $goldCExist = CamGoldArea->GoldFingersExist( $inCAM, $jobId, $stepName, "c" );
		my $goldSExist = 0;

		if ( $defaultInfo->LayerExist("s") ) {
			$goldSExist = CamGoldArea->GoldFingersExist( $inCAM, $jobId, $stepName, "s" );
		}

		my $refLayerExist = 1;

		# Check if goldc layer exist
		if ( $goldCExist && !$defaultInfo->LayerExist("goldc") ) {

			$refLayerExist = 0;
		}

		# Check if gold s exist
		if ( $goldSExist && !$defaultInfo->LayerExist("golds") ) {

			$refLayerExist = 0;
		}

		if ( ( $goldCExist || $goldSExist ) && $refLayerExist ) {

			my $cuThickness = $defaultInfo->GetBaseCuThick("c");
			my $pcbThick = CamJob->GetFinalPcbThick( $inCAM, $jobId );

			my %result = CamGoldArea->GetGoldFingerArea( $cuThickness, $pcbThick, $inCAM, $jobId, "panel" );

			if ( $result{"exist"} && $result{"area"} < 10 ) {

				my $area = sprintf( "%.2f", $result{"area"} );
				$dataMngr->_AddErrorResult( "Gold area",
											"Gold finger area must be greater then 10 cm2 (now area = $area cm2).\n Add more gold area." );
			}
		}
	}

	# 9) Control if exist customer panel and customer set in a same time

	my $custPnlExist = $defaultInfo->GetJobAttrByName("customer_panel");
	my $custSetExist = $defaultInfo->GetJobAttrByName("customer_set");
	if ( $custPnlExist eq "yes" && $custSetExist eq "yes" ) {

		$dataMngr->_AddErrorResult( "Panelisation",
								  "V atributech jobu je aktivní 'zákaznický panel' i 'zákaznické sady'. Zvol pouze jednu možnost panelizace." );
	}

	# Check all necessary attributes when customer panel
	if ( $custPnlExist eq "yes" ) {

		my $custPnlX    = $defaultInfo->GetJobAttrByName("cust_pnl_singlex");
		my $custPnlY    = $defaultInfo->GetJobAttrByName("cust_pnl_singley");
		my $custPnlMult = $defaultInfo->GetJobAttrByName("cust_pnl_multipl");

		if ( !defined $custPnlX || !defined $custPnlY || !defined $custPnlMult || $custPnlX == 0 || $custPnlY == 0 || $custPnlMult == 0 ) {
			$dataMngr->_AddErrorResult(
										"Panelisation",
										"V atributech jobu je aktivní 'zákaznický panel', ale informace není kompletní"
										  . " (atributy jobu: \"cust_pnl_singlex\", \"cust_pnl_singley\", \"cust_pnl_multipl\")"
			);
		}
	}

	# Check all necessary attributes when customer set
	if ( $custSetExist eq "yes" ) {

		my $multipl = $defaultInfo->GetJobAttrByName("cust_set_multipl");

		if ( !defined $multipl || $multipl == 0 ) {
			$dataMngr->_AddErrorResult( "Panelisation",
						   "V atributech jobu je aktivní 'zákaznická sada', ale informace není kompletní (atribut jobu: \"cust_set_multipl\")" );
		}
	}

	# 11) Check if when exist customer panel, mpanel doesn't exist
	if ( $custPnlExist eq "yes" && $defaultInfo->StepExist("mpanel") ) {

		$dataMngr->_AddErrorResult(
							  "Customer set",
							  "Pokud je v jobu nastaven zákaznický panel (atribut job:  customer_panel=yes), job nesmí obsahovat step \"mpanel\". "
								. "Flatennuj step \"mpanel\" do \"o+1\""
		);
	}

	# 10) Check if exist pressfit, if is checked in nif
	if ( $defaultInfo->GetPressfitExist() && !$groupData->GetPressfit() ) {

		$dataMngr->_AddErrorResult( "Pressfit", "Některé nástroje v dps jsou typu 'pressfit', možnost 'Pressfit' by měla být použita." );
	}

	# 11) Check if exist pressfit, if is checked in nif
	if ( $defaultInfo->GetMeritPressfitIS() && !$groupData->GetPressfit() ) {

		$dataMngr->_AddErrorResult( "Pressfit", "V IS je u dps požadavek na 'pressfit', volba 'Pressfit' by měla být použita." );
	}

	# 12) if pressfit is checked, but is not in data
	if ( !$defaultInfo->GetPressfitExist() && $groupData->GetPressfit() ) {

		$dataMngr->_AddErrorResult(
									"Pressfit",
									"Volba 'Pressfit' je použita, ale žádné otvory typu pressfit nebyly nalezeny."
									  . " Prosím zruš volbu nebo přidej pressfit otvory (pomocí Drill Tool Manageru)."
		);
	}

	# 14) Check if exist tolerance hole, if is checked in nif
	if ( $defaultInfo->GetToleranceHoleExist() && !$groupData->GetToleranceHole() ) {

		$dataMngr->_AddErrorResult( "Tolerance holes",
									"Některé nástroje v dps mají požadavek na tolerance, volba 'Tolerance (NPlt)' by měla být použita." );
	}

	# 15) Check if exist tolerance hole, if is checked in nif
	if ( $defaultInfo->GetToleranceHoleIS() && !$groupData->GetToleranceHole() ) {

		$dataMngr->_AddErrorResult( "Tolerance holes",
									"V IS je u dps požadavek na 'měření tolerancí nplt', volba 'Tolerance (NPlt)' by měla být použita." );
	}

	# 16) if tolerance hole is checked, but is not in data
	if ( !$defaultInfo->GetToleranceHoleExist() && $groupData->GetToleranceHole() ) {

		$dataMngr->_AddErrorResult(
									"Tolerance holes",
									"Volba 'Tolerance (NPlt)' je použita, ale žádné otvory s tolerancemi nebyly nalezeny."
									  . " Prosím zruš volbu nebo přidej tolerance k nplt otvorům (pomocí Drill Tool Manageru)."
		);
	}

	# 17) Check if chamfer edges is in IS and not checked in export
	if ( $defaultInfo->GetChamferEdgesIS() && !$groupData->GetChamferEdges() ) {

		$dataMngr->_AddErrorResult( "Chamfer edges",
									"V IS je u dps požadavek na sražení konektoru, volba \"Chamfer edges\" by měla být zapnutá." );
	}

	# 18) Chem if chamfer edge is not checked if there is tool for chamfering in job
	if ( !$defaultInfo->GetChamferEdgesIS() && !$groupData->GetChamferEdges() ) {

		foreach my $s ( map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobId ) ) {

			my $a = 0;
			if ( PCBConnectorCheck->ConnectorToolDetection( $inCAM, $jobId, $s, \$a ) ) {

				$dataMngr->_AddWarningResult(
											  "Chamfer tool",
											  "Ve stepu: \"$s\" byl nalezena speciální fréza (z top a bot), "
												. "která jede pojezdem a má speciální úhel: $a°. Nemá být zapnuta volba \"Chamfer edge\"?"
				);
			}

		}
	}

	# 19) Check clearance of inner layer form chamfered connector
	if ( $groupData->GetChamferEdges() && $defaultInfo->GetLayerCnt() > 2 ) {

		foreach my $s ( map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobId ) ) {

			my $a          = 90;                                                                     # if no tool is found in mill, default is 90
			my $toolExist  = PCBConnectorCheck->ConnectorToolDetection( $inCAM, $jobId, $s, \$a );
			my @resultData = ();

			unless ( InLayersClearanceCheck->CheckAllInLayers( $inCAM, $jobId, $s, $a, \@resultData ) ) {

				foreach my $res (@resultData) {

					unless ( $res->{"result"} ) {

						my $mess =
						    "Step: \"$s\", layer: \""
						  . $res->{"layer"}
						  . "\". Motiv vnitřní vrstvy je příliš blízko sražené hraně konektoru.\n";
						$mess .= "Minimální vzdálenost motivu od profilu dps: " . $res->{"minProfDist"} . "µm (úhel sražení: $a°)";

						$dataMngr->_AddErrorResult( "Odstup vnitřní vrstvy od hrany konektoru", $mess );
					}
				}
			}
		}
	}

	#---------------------------------------------

	# 20) Check max cu thickness by pcb class

	if ( $defaultInfo->GetPcbType() ne EnumsGeneral->PcbType_NOCOPPER ) {

		my $maxCuThick = undef;

		if ( $defaultInfo->GetLayerCnt() == 1 ) {
			$maxCuThick = CuLayer->GetMaxCuByClass( $defaultInfo->GetPcbClass(), 1 );    # 1vv - same condition as inner layers
		}
		else {
			$maxCuThick = CuLayer->GetMaxCuByClass( $defaultInfo->GetPcbClass() );
		}

		if ( $defaultInfo->GetLayerCnt() <= 2 ) {

			if ( $defaultInfo->GetBaseCuThick() > $maxCuThick ) {
				$dataMngr->_AddErrorResult(
											"Max Cu thickness outer layer",
											"Maximal Cu thickness of outer layers for pcbclass: "
											  . $defaultInfo->GetPcbClass()
											  . " is: $maxCuThick µm. Current job Cu thickness is: "
											  . $defaultInfo->GetBaseCuThick() . "µm"
				);
			}

		}
		else {

			foreach my $cu ( grep { $_->GetType() eq StackEnums->MaterialType_COPPER && $_->GetCopperName() =~ /v\d+/ }
							 $defaultInfo->GetStackup()->GetAllLayers() )
			{

				my $maxCuThick = CuLayer->GetMaxCuByClass( $defaultInfo->GetPcbClassInner(), 1 );

				if ( $cu->GetThick() > $maxCuThick ) {

					$dataMngr->_AddErrorResult(
												"Max Cu thickness inner layer",
												"Maximal Cu thickness of inner layer: "
												  . $cu->GetCopperName()
												  . " for pcbclass: "
												  . $defaultInfo->GetPcbClassInner()
												  . " is: $maxCuThick µm. Current job Cu thickness is: "
												  . $cu->GetThick() . "µm"
					);
				}
			}

		}

	}

	# 21) Check if HEG or NIF contain 'nakoveni jader', but stackup xml no
	if ( $defaultInfo->GetSignalLayers() > 2 ) {

		my $stackup = $defaultInfo->GetStackup();

		# Check if exist plating on cores, if plating is on both sided
		foreach my $core ( $stackup->GetAllCores() ) {

			if (    ( $core->GetTopCopperLayer()->GetCoreExtraPlating() && !$core->GetBotCopperLayer()->GetCoreExtraPlating() )
				 || ( !$core->GetTopCopperLayer()->GetCoreExtraPlating() && $core->GetBotCopperLayer()->GetCoreExtraPlating() ) )
			{
				$dataMngr->_AddErrorResult(
											"Nakovení jader",
											"Nakovení jádra (číslo: "
											  . $core->GetCoreNumber()
											  . " ) musí být z obou stran TOP i BOT, nyní je jen z jedné. Oprav XML složení"
				);
			}
		}

		# Check when is plating in HEG if plating is in stackup
		foreach my $coreIS ( HegMethods->GetAllCoresInfo($jobId) ) {

			my $coreStackup = $stackup->GetCore( $coreIS->{"core_num"} );

			if ( $coreIS->{"vrtani"} =~ /C/i && !$coreStackup->GetCoreExtraPlating() ) {

				$dataMngr->_AddErrorResult(
											"Nakovení jader",
											"Pozor jádro (číslo: "
											  . $coreStackup->GetCoreNumber()
											  . " ) má v IS vrtání = \"C\" -  \"nakovení\", ale není nastaveno ve složení. "
											  . "Uprav složení, aby obsahovalo nakovení."
				);
			}
		}
	}

	# 22) Check if set construction class match with real pcb data by layers
	if ( !$defaultInfo->IsPool() ) {
		my $checklistName = "control";
		my $isolTol       = 0.1;         # tolerance of isolation from set construction class is 10%

		unless ( CamChecklist->ChecklistLibExists( $inCAM, $checklistName ) ) {

			$dataMngr->_AddErrorResult(
						"Checklist - $checklistName",
						"Checklist (název:$checklistName) pro kontrolu minimálních izolací v signálových vrstvách neexistuje v Global library."
						  . " Kontrola na správné nastavení konstrukčních tříd nebude provedena."
			);
		}
		else {

			foreach my $s ( map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId, 1, [ EnumsGeneral->Coupon_IMPEDANCE ] ) ) {

				# Check outer layers

				my @verifyOutResults = ();
				my $verifyOutErrMess;

				if ( PCBClassCheck->VerifyMinIsolOuterLayers( $inCAM, $jobId, $s, \@verifyOutResults, undef, undef, \$verifyOutErrMess ) ) {

					foreach my $r (@verifyOutResults) {

						print "Layer: " . $r->{"layer"} . "\n";
						print "Problem category: " . $r->{"cat"} . "\n";
						print "Problem value: " . $r->{"value"} . "\n";
						print "\n\n";

						my $class = $defaultInfo->GetPcbClass();

						$dataMngr->_AddWarningResult(
													  "Konstrukční třída vrstvy \"" . $r->{"layer"} . "\"",
													  "V reportu cheklistu: \"$checklistName\", kategorii: \""
														. $r->{"cat"}
														. "\" pro step: \"$s\", vrstvu: \""
														. $r->{"layer"}
														. "\" byly nalezeny izolace: \""
														. $r->{"val"}
														. "\"µm, které jsou menši než povoluje nastavená kontsrukční třída: \"$class\"\n"
						);

					}
				}
				else {

					$dataMngr->_AddErrorResult(
												"Checklist - $checklistName",
												"Chyba při pokusu o spuštění checklistu (název:$checklistName) pro step: \"$s\""
												  . "Detail chyby: \"$verifyOutErrMess\""
					);
				}

				# Check inner layers
				if ( $defaultInfo->GetSignalLayers() > 2 ) {
					my @verifyInnResults = ();
					my $verifyInnErrMess;

					if ( PCBClassCheck->VerifyMinIsolInnerLayers( $inCAM, $jobId, $s, \@verifyInnResults, undef, undef, \$verifyInnErrMess ) ) {

						foreach my $r (@verifyInnResults) {

							print "Layer: " . $r->{"layer"} . "\n";
							print "Problem category: " . $r->{"cat"} . "\n";
							print "Problem value: " . $r->{"val"} . "\n";
							print "\n\n";

							my $class = $defaultInfo->GetPcbClassInner();

							$dataMngr->_AddWarningResult(
														  "Konstrukční třída vrstvy \"" . $r->{"layer"} . "\"",
														  "V reportu cheklistu: \"$checklistName\", kategorii: \""
															. $r->{"cat"}
															. "\" pro step: \"$s\", vrstvu: \""
															. $r->{"layer"}
															. "\" byly nalezeny izolace: \""
															. $r->{"val"}
															. "\"µm, které jsou menši než povoluje nastavená kontsrukční třída: \"$class\"\n"
							);
						}
					}
					else {

						$dataMngr->_AddErrorResult(
													"Checklist - $checklistName",
													"Chyba při pokusu o spuštění checklistu (název:$checklistName) pro step: \"$s\""
													  . "Detail chyby: \"$verifyInnErrMess\""
						);
					}
				}
			}
		}
	}

	# xx) Check if construction class of inner and auter layer is match with last run ERF models od chacklist action for signal layers
	my $chcklstCheckName = "checks";

	# Find ERF with height construction class
	my ( $maxERFOuter, $maxERFOuterNum, $maxERFOuterNumStep ) = undef;
	my ( $maxERFInner, $maxERFInnerNum, $maxERFInnerNumStep ) = undef;

	foreach my $step ( map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId ) ) {

		next unless ( CamChecklist->ChecklistExists( $inCAM, $jobId, $step, $chcklstCheckName ) );

		# action number outer layer = 1 for 1v + 2v;
		# action number outer layer = 3 for multilayer;
		my $aOuterNum = $defaultInfo->GetLayerCnt() <= 2 ? 1 : 3;

		my $ERF = CamChecklist->GetChecklistActionERF( $inCAM, $jobId, $step, $chcklstCheckName, $aOuterNum );
		my $ERFNum = ( $ERF =~ /_(\d+)_/ )[0];

		if ( defined $ERFNum && $ERFNum > 0 ) {

			if ( !defined $maxERFOuterNum || ( defined $maxERFOuterNum && $maxERFOuterNum < $ERFNum ) ) {

				$maxERFOuter        = $ERF;
				$maxERFOuterNum     = $ERFNum;
				$maxERFOuterNumStep = $step;
			}
		}

		if ( $defaultInfo->GetLayerCnt() > 2 ) {

			# action number 3 for inner layers
			my $ERFIn = CamChecklist->GetChecklistActionERF( $inCAM, $jobId, $step, $chcklstCheckName, 2 );
			my $ERFInNum = ( $ERFIn =~ /_(\d+)_/ )[0];

			if ( defined $ERFInNum && $ERFInNum > 0 ) {

				if ( !defined $maxERFInnerNum || ( defined $maxERFInnerNum && $maxERFInnerNum < $ERFInNum ) ) {

					$maxERFInner        = $ERFIn;
					$maxERFInnerNum     = $ERFInNum;
					$maxERFInnerNumStep = $step;
				}
			}
		}
	}

	# outer layers
	if ( defined $maxERFOuterNum && $maxERFOuterNum != $defaultInfo->GetPcbClass() ) {

		$dataMngr->_AddWarningResult(
			"Konstukční třída ",
			"V jobu je nastavená jiná konstrukční třída pro vnější vrstvy (job attribut: Pcbclass = "
			  . $defaultInfo->GetPcbClass()
			  . ") než poslední ERF model ($maxERFOuter, pro step: $maxERFOuterNumStep), který byl spuštěn v checklistu: \"$chcklstCheckName\". "
			  . "Je to správně?"
		);
	}

	if ( defined $maxERFInnerNum && $maxERFInnerNum != $defaultInfo->GetPcbClassInner() ) {

		$dataMngr->_AddWarningResult(
			"Konstukční třída vnitřní vrstvy",
			"V jobu je nastavená jiná konstrukční třída pro vnitřní vrstvy (job attribut: PcbclassInner = "
			  . $defaultInfo->GetPcbClassInner()
			  . ") než poslední ERF model ($maxERFInner, pro step: $maxERFInnerNumStep), který byl spuštěn v checklistu: \"$chcklstCheckName\". "
			  . "Je to správně?"
		);
	}

	# X) Check minimal/maximal customer panel dimension
	if ( $defaultInfo->StepExist("mpanel") ) {

		my ( $minA, $minB ) = $defaultInfo->GetCustomerNote()->MinCustPanelDim();

		if ( defined $minA && defined $minB ) {

			my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "mpanel" );
			my $h   = abs( $lim{"yMax"} - $lim{"yMin"} );
			my $w   = abs( $lim{"xMax"} - $lim{"xMin"} );

			if ( min( $w, $h ) < min( $minA, $minB ) || max( $w, $h ) < max( $minA, $minB ) ) {
				$dataMngr->_AddWarningResult(
											  "Minimální velikost mpanelu",
											  "Zákazník požaduje minimální velikost panelu pro osazování: "
												. $minA . "mm x "
												. $minB
												. "mm. Mpanel má aktuálně: "
												. $w . "mm x "
												. $h
				);
			}
		}

		my ( $maxA, $maxB ) = $defaultInfo->GetCustomerNote()->MaxCustPanelDim();

		if ( defined $maxA && defined $maxB ) {

			my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "mpanel" );
			my $h   = abs( $lim{"yMax"} - $lim{"yMin"} );
			my $w   = abs( $lim{"xMax"} - $lim{"xMin"} );

			if ( min( $w, $h ) > min( $maxA, $maxB ) || max( $w, $h ) > max( $maxA, $maxB ) ) {

				$dataMngr->_AddWarningResult(
											  "Maximální velikost mpanelu",
											  "Zákazník požaduje maximální velikost panelu pro osazování: "
												. $minA . "mm x "
												. $minB
												. "mm. Mpanel má aktuálně: "
												. $w . "mm x "
												. $h
				);
			}
		}
	}

	# X) If IPC3 request in IS, check if exist at least one IPC3 coupons, max 3
	my $ipc3type = $defaultInfo->GetPcbBaseInfo()->{"ipc_class_3"};
	if ( defined $ipc3type ) {
		my @allSteps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $stepName );

		my $IPC3CustStep = first { $_->{"stepName"} eq EnumsGeneral->Coupon_IPC3MAIN } @allSteps;

		if ( !defined $IPC3CustStep ) {

			$dataMngr->_AddErrorResult(
										"IPC-3 zákaznický kupón",
										"V IS je požadavek na IPC-3 (typ: $ipc3type), ale v panelu nebyl dohledán kupón step: "
										  . EnumsGeneral->Coupon_IPC3MAIN
										  . " Vlož do panelu 1-3 kopóny."
			);
		}
		elsif ( $IPC3CustStep->{"totalCnt"} < 1 || $IPC3CustStep->{"totalCnt"} > 3 ) {
			$dataMngr->_AddWarningResult(
										  "IPC3 zákaznický kupón - špatný počet",
										  "Při požadavku na IPC3, musí být v panelu minimálně 1 maximálně 3 kupóny ("
											. EnumsGeneral->Coupon_IPC3MAIN
											. "). Aktuální počet: "
											. $IPC3CustStep->{"totalCnt"}
			);

		}

		my $IPC3DrillStep = first { $_->{"stepName"} eq EnumsGeneral->Coupon_IPC3DRILL } @allSteps;

		if ( !defined $IPC3DrillStep ) {

			$dataMngr->_AddErrorResult(
										"IPC-3 vrtací kupón",
										"V IS je požadavek na IPC-3 (typ: $ipc3type), ale v panelu nebyl dohledán kupón step: "
										  . EnumsGeneral->Coupon_IPC3DRILL
										  . " Vlož do okolí panelu panelu 1-2 kopóny."
			);
		}
		elsif ( $IPC3DrillStep->{"totalCnt"} < 1 || $IPC3DrillStep->{"totalCnt"} > 3 ) {
			$dataMngr->_AddWarningResult(
										  "IPC-3 vrtací kupón - špatný počet",
										  "Při požadavku na IPC3, musí být v okolí panelu 2 vrtací kupóny ("
											. EnumsGeneral->Coupon_IPC3DRILL
											. "). Aktuální počet: "
											. $IPC3DrillStep->{"totalCnt"}
			);

		}

	}

	# X) Check if revision is not active for reorders
	my $difFile = TifRevision->new($jobId);
	if ( $difFile->TifFileExist() && $difFile->GetRevisionIsActive() ) {

		my @affectOrder = ();
		push( @affectOrder, HegMethods->GetOrdersByState( $jobId, 4 ) );    # Orders on Predvzrobni priprava = 2
		@affectOrder = map { $_->{"reference_subjektu"} } grep { $_->{"reference_subjektu"} !~ /-01/ } @affectOrder;

		if ( scalar(@affectOrder) ) {

			$dataMngr->_AddErrorResult(
										"Aktivní revize",
										"Pozor, na předvýrobní přípravě je opakovaná zakázka ("
										  . join( ";", @affectOrder )
										  . ") a v DIF souboru byla nalezena aktivní revize. "
										  . "Ujisti se, že instrukce v revizi byly provedeny a revizi smaž (RevisionScript.pl)"
										  . "\nText revize:\n"
										  . $difFile->GetRevisionText()
			);
		}
	}

	# X) Test is PCB is flex and only one side soldermask exist
	if ( $defaultInfo->GetIsFlex() && $defaultInfo->GetLayerCnt() <= 2 ) {

		# Test on name, there can bz fake layer MSOLEC
		my @sm = grep { $_->{"gROWname"} =~ /^m([cs]\d*$)/ } $defaultInfo->GetBoardBaseLayers();

		if ( scalar(@sm) == 1 ) {

			# test if there is coverly from another side
			my $smSide  = ( $sm[0]->{"gROWname"} =~ /^m([cs]\d*$)/ )[0];
			my $cvrlTop = defined( first { $_->{"gROWname"} eq "cvrlc" } $defaultInfo->GetBoardBaseLayers() ) ? 1 : 0;
			my $cvrlBot = defined( first { $_->{"gROWname"} eq "cvrls" } $defaultInfo->GetBoardBaseLayers() ) ? 1 : 0;

			if ( ( $smSide eq "c" && !$cvrlBot ) || ( $smSide eq "s" && !$cvrlTop ) ) {

				$dataMngr->_AddErrorResult(
											"Jednostranná maska",
											"Nelze vyrobit flexi DPS s jednostrannou maskou. DPS by se po vytvrzení masky neúmerně kroutila "
											  . "a nešlo by ji v vyrobit. "
											  . "Řešením je aplikovat na drouhou stranu masku nebo coverlay"
				);

			}

		}

	}

	# Check if pcbclass is 8 and surface HAL if there is soldermask
	# If soldermask is missing or whole signal layer is unmasked, PCB is not able produce
	# (HAL surface will coin tracks with small isolation)
	if ( $defaultInfo->GetPcbClass() >= 8 && $defaultInfo->GetPcbSurface() =~ /^[AB]$/i ) {

		my @sigLayers = ();

		push( @sigLayers, "c" ) if ( $defaultInfo->LayerExist("c") );
		push( @sigLayers, "s" ) if ( $defaultInfo->LayerExist("s") );
		foreach my $l (@sigLayers) {

			if ( !$defaultInfo->LayerExist("m${l}") ) {

				$dataMngr->_AddErrorResult(
											"HAL + 8KT",
											"DPS je v 8. třídě s povrchovou úpravou HAL, ale neobsahuje vrstvu masky: m${l}. "
											  . "Přidej vrstvu masky nebo zmněň povrchovou úpravu, jinak HAL pravděpodobně zkratuje vodiče blízko u sebe."
				);
			}
			else {

				# Check if whole signal are is not unmasked

				my @steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobId );

				my $tmpL = GeneralHelper->GetGUID();

				foreach my $step (@steps) {

					CamHelper->SetStep( $inCAM, $step );

					my $f = FeatureFilter->new( $inCAM, $jobId, $l );
					$f->SetProfile( FiltrEnums->ProfileMode_INSIDE );    # There may be features behind profile (lines texts)

					if ( $f->Select() ) {
						CamLayer->CopySelOtherLayer( $inCAM, [$tmpL] );
						my $f2 = FeatureFilter->new( $inCAM, $jobId, $tmpL );
						$f2->SetRefLayer("m${l}");
						$f2->SetReferenceMode( FiltrEnums->RefMode_MULTICOVER );

						# Select all complete unmasked features
						$f2->Select();

						# Reverse to see, if there are some masekd feature
						$inCAM->COM("sel_reverse");
						my $coveredFeats = CamLayer->GetSelFeaturesCnt($inCAM);

						my $allUnmasked = 0;
						if ( $coveredFeats == 0 ) {

							# Perhaps all signal layer features are unmasked
							# It is not for sure, so only warning
							$dataMngr->_AddWarningResult(
														  "HAL + 8KT",
														  "DPS je v 8. třídě s povrchovou úpravou HAL. Ve stepu: $step"
															. " je vrstva: ${l} pravděpodobně celá odmaskovaná. "
															. "Uprav vrstvu masky nebo zmněň povrchovou úpravu, "
															. "jinak HAL pravděpodobně zkratuje odmaskované vodiče blízko u sebe."
							);
						}
					}

					CamLayer->ClearLayers($inCAM);

				}

				CamMatrix->DeleteLayer( $inCAM, $jobId, $tmpL );

			}

		}
	}

}

# check if datacode exist
sub __CheckDataCodeIS {
	my $self      = shift;
	my $jobId     = shift;
	my $groupData = shift;

	my $layerIS     = HegMethods->GetDatacodeLayer($jobId);
	my $layerExport = $groupData->GetDatacode();

	return $self->__CheckMarkingLayer( $layerExport, $layerIS );
}

# Check if datacodes are ok (dynamic, right mirror)
sub __CheckDataCodeJob {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;
	my $dataCodes   = shift;
	my $mess        = shift;

	my $result = 1;

	my @steps = ("o+1");    #if pool

	unless ( $defaultInfo->IsPool() ) {

		@steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobId );
	}

	foreach my $layer ( split( ",", $dataCodes ) ) {

		foreach my $step (@steps) {

			$layer = lc($layer);

			die "Layer: $layer, which the datacode should be located in does not exist." if ( !$defaultInfo->LayerExist($layer) );

			my @dtCodes = MarkingDataCode->GetDatacodesInfo( $inCAM, $jobId, $step, $layer );

			# check if mirror datacode is ok in all steps where is datacont present
			if (@dtCodes) {

				my @dtCodesWrong = grep { $_->{"wrongMirror"} } @dtCodes;
				if (@dtCodesWrong) {

					my $str = join( "; ", map { $_->{"text"} } @dtCodesWrong );
					$$mess .= "Ve stepu: \"$step\", vrstvě: \"$layer\" jsou nesprávně zrcadlené datakódy ($str).\n";
					$result = 0;
				}
			}
			else {

				# Check if step contain child steps (datacode has to by present in each child step)
				unless ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $step ) ) {
					$$mess .= "Ve stepu: \"$step\", vrstvě: \"$layer\" nebyl dohledán dynamický datakód.\n";
					$result = 0;
				}

			}
		}
	}

	return $result;
}

# Check if UL logo are ok (exist, right mirror)
sub __CheckULLogoJob {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;
	my $ULLogos     = shift;
	my $mess        = shift;

	my $result = 1;

	my @steps = ("o+1");    #if pool

	unless ( $defaultInfo->IsPool() ) {

		@steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobId );
	}

	foreach my $layer ( split( ",", $ULLogos ) ) {

		foreach my $step (@steps) {

			$layer = lc($layer);

			die "Layer: $layer, which UL logo should be located in does not exist." if ( !$defaultInfo->LayerExist($layer) );

			my @ULLogos = MarkingULLogo->GetULLogoInfo( $inCAM, $jobId, $step, $layer );

			# check if mirror UL logo is ok in all steps where is datacont present
			if (@ULLogos) {

				my @ULLogoWrong = grep { $_->{"wrongMirror"} } @ULLogos;
				if (@ULLogoWrong) {

					my $str = join( "; ", map { $_->{"name"} } @ULLogoWrong );
					$$mess .= "Ve stepu: \"$step\", vrstvě: \"$layer\" jsou nesprávně zrcadlené UL loga ($str).\n";
					$result = 0;
				}
			}
			else {

				# Check if step contain child steps (UL logo has to by present in each child step)
				unless ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $step ) ) {
					$$mess .= "Ve stepu: \"$step\", vrstvě: \"$layer\" nebylo dohledáno UL logo.\n";
					$result = 0;
				}
			}
		}
	}

	return $result;
}

# check if ul logo exist
sub __CheckUlLogoIS {
	my $self      = shift;
	my $jobId     = shift;
	my $groupData = shift;

	my $layerIS = HegMethods->GetUlLogoLayer($jobId);

	my $layerExport = $groupData->GetUlLogo();

	return $self->__CheckMarkingLayer( $layerExport, $layerIS );
}

sub __CheckMarkingLayer {
	my $self        = shift;
	my $layerExport = shift;
	my $layerIS     = shift;

	# convert to lower
	$layerExport = lc($layerExport);
	$layerIS     = lc($layerIS);

	# remove whitespaces
	$layerExport =~ s/\s//g;
	$layerIS =~ s/\s//g;

	my $res = "";

	if ( $layerExport && $layerExport ne "" ) {

		$res = $layerExport;
	}
	elsif ( $layerIS && $layerIS ne "" ) {

		$res = $layerIS;
	}

	# case when marking in helios exist but in export no
	if ( $layerExport eq "" && $layerIS ne "" ) {
		$res = undef;    #error
	}

	# case, when marking is in IS and set in export too
	if ( defined $layerExport && defined $layerIS && ( $layerExport ne "" && $layerIS ne "" ) ) {

		$res = $layerIS;

		#test if marking are both same, as $layerExport as $layerIS

		# mraking is in format.: MC, C or as single value: MC
		my @exportLayers = split( ",", $layerExport );
		@exportLayers = sort { $a cmp $b } @exportLayers;

		my @isLayers = split( ",", $layerIS );
		@isLayers = sort { $a cmp $b } @isLayers;

		# if arrays are different, error
		unless ( @exportLayers ~~ @isLayers ) {
			$res = undef;    #error
		}

	}

	if ($res) {
		$res = uc($res);
	}

	return $res;
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

