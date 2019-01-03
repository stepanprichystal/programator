
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

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper';
use aliased 'Helpers::ValueConvertor';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::Tooling::PressfitOperation';
use aliased 'Packages::CAMJob::Marking::Marking';
use aliased 'Packages::CAMJob::Technology::CuLayer';
use aliased 'Packages::CAMJob::PCBConnector::InLayersClearanceCheck';
use aliased 'Packages::CAMJob::PCBConnector::PCBConnectorCheck';

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

	my $errMess = "";
	unless ( $self->__CheckDataCodeJob( $inCAM, $jobId, $defaultInfo, $groupData->GetDatacode(), \$errMess ) ) {
		$dataMngr->_AddErrorResult( "Data code", $errMess );
	}

	# 2) ul logo
	my $ulLogoLayer = $self->__CheckUlLogoIS( $jobId, $groupData );

	unless ( defined $ulLogoLayer ) {
		$dataMngr->_AddErrorResult( "Ul logo", "Nesedí zadané Ul logo v heliosu s datacodem v exportu." );
	}

	# 3) mask control
	my %masks = CamLayer->ExistSolderMasks( $inCAM, $jobId );
	my $topMaskExist = CamHelper->LayerExists( $inCAM, $jobId, "mc" );
	my $botMaskExist = CamHelper->LayerExists( $inCAM, $jobId, "ms" );

	# Control mask existence
	if ( $masks{"top"} != $topMaskExist ) {

		$dataMngr->_AddErrorResult( "Maska TOP", "Nesedí maska top v metrixu jobu a ve formuláři Heliosu" );
	}
	if ( $masks{"bot"} != $botMaskExist ) {

		$dataMngr->_AddErrorResult( "Maska BOT", "Nesedí maska bot v metrixu jobu a ve formuláři Heliosu" );
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

	# 5) silk
	my %silk = CamLayer->ExistSilkScreens( $inCAM, $jobId );
	my $topSilkExist = CamHelper->LayerExists( $inCAM, $jobId, "pc" );
	my $botSilkExist = CamHelper->LayerExists( $inCAM, $jobId, "ps" );

	# Control silk existence
	if ( $silk{"top"} != $topSilkExist ) {

		$dataMngr->_AddErrorResult( "Potisk TOP", "Nesedí potisk top v metrixu jobu a ve formuláři Heliosu" );
	}
	if ( $silk{"bot"} != $botSilkExist ) {

		$dataMngr->_AddErrorResult( "Potisk BOT", "Nesedí potisk bot v metrixu jobu a ve formuláři Heliosu" );
	}

	# 6) Control silk colour
	my %silkColorIS        = HegMethods->GetSilkScreenColor($jobId);
	my $silkColorTopExport = $groupData->GetC_silk_screen_colour();
	my $silkColorBotExport = $groupData->GetS_silk_screen_colour();

	if ( !defined $silkColorIS{"top"} ) {
		$silkColorIS{"top"} = "";
	}

	if ( !defined $silkColorIS{"bot"} ) {
		$silkColorIS{"bot"} = "";
	}

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

	# 7) Check if dps should be pattern, if tenting is realz unchecked

	my $tenting = $self->__IsTentingCS( $inCAM, $jobId, $defaultInfo );
	my $tentingForm = $groupData->GetTenting();

	if ( !$tenting && $tentingForm ) {

		$dataMngr->_AddWarningResult( "Pattern", "Dps by měla jít do výroby jako pattern, ale ve formuláši máš zaškrknutý tenting." );
	}

	# 8) Check if goldfinger exist, if area is greater than 10mm^2

	if ( $defaultInfo->LayerExist("c") && $defaultInfo->GetTypeOfPcb() ne "Neplatovany" ) {

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
			my $pcbThick    = JobHelper->GetFinalPcbThick($jobId);

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

	# 18) Check clearance of inner layer form chamfered connector
	if ( $groupData->GetChamferEdges() && $defaultInfo->GetLayerCnt() > 2 ) {

		foreach my $s ( map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobId ) ) {

			my $a = PCBConnectorCheck->GetConnectorAngle( $inCAM, $jobId, $s );
			my @resultData = ();

			unless ( InLayersClearanceCheck->CheckAllInLayers( $inCAM, $jobId, $s, $a, \@resultData ) ) {

				foreach my $res (@resultData) {

					unless ($res->{"result"}) {

						my $mess =
						  "Step: \"$s\", layer: " . $res->{"layer"} . ". Motiv vnitřní vrstvy je příliš blízko sražené hraně konektoru.\n";
						$mess .= "Minimální vzdálenost motivu od profilu dps: " . $res->{"minProfDist"} . "mm (úhel sražení: $a°)";

						$dataMngr->_AddErrorResult( "Odstup vnitřní vrstvy", $mess );
					}
				}
			}
		}
	}

	#---------------------------------------------

	# 14) Check max cu thickness by pcb class

	if ( $defaultInfo->GetTypeOfPcb() ne "Neplatovany" ) {

		my $maxCuThick = undef;

		if ( $defaultInfo->GetLayerCnt() == 1 ) {
			$maxCuThick = CuLayer->GetMaxCuByClass( $defaultInfo->GetPcbClass(), 1 );    # 1vv - same condition as inner layers
		}
		else {
			$maxCuThick = CuLayer->GetMaxCuByClass( $defaultInfo->GetPcbClass() );
		}

		if ( $defaultInfo->GetBaseCuThick() > $maxCuThick ) {
			$dataMngr->_AddErrorResult(
										"Max Cu thickness outer layer",
										"Maximal Cu thickness of outer layers for pcbclass: "
										  . $defaultInfo->GetPcbClass()
										  . " is: $maxCuThick µm. Current job Cu thickness is: "
										  . $defaultInfo->GetBaseCuThick() . "µm"
			);
		}

		if ( $defaultInfo->GetLayerCnt() > 2 ) {

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

	# Check if HEG or NIF contain 'nakoveni jader', but stackup xml no
	if ( $defaultInfo->GetSignalLayers() > 2 ) {

		my $stackup = $defaultInfo->GetStackup();

		# Check if exist plating on cores, if plating is on both sided
		foreach my $core ( $stackup->GetAllCores() ) {

			if (    ( $core->GetTopCopperLayer()->GetPlatingExists() && !$core->GetBotCopperLayer()->GetPlatingExists() )
				 || ( !$core->GetTopCopperLayer()->GetPlatingExists() && $core->GetBotCopperLayer()->GetPlatingExists() ) )
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

			if ( $coreIS->{"vrtani"} =~ /C/i && !$coreStackup->GetPlatingExists() ) {

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

		@steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );
	}

	foreach my $step (@steps) {

		foreach my $layer ( split( ",", $dataCodes ) ) {

			$layer = lc($layer);
			my @dtCodes = Marking->GetDatacodesInfo( $inCAM, $jobId, $step, $layer );

			# check if mirror datacode is ok
			if (@dtCodes) {

				my @dtCodesWrong = grep { $_->{"wrongMirror"} } @dtCodes;
				if (@dtCodesWrong) {

					my $str = join( "; ", map { $_->{"text"} } @dtCodesWrong );
					$$mess .= "Ve stepu: \"$step\", vrstvě: \"$layer\" jsou nesprávně zrcadlené datakódy ($str).\n";
					$result = 0;
				}
			}
			else {
				$$mess .= "Ve stepu: \"$step\", vrstvě: \"$layer\" nebyl dohledán dynamický datakód.\n";
				$result = 0;
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

	my $layerIS     = HegMethods->GetUlLogoLayer($jobId);
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

sub __IsTentingCS {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;

	unless ($defaultInfo) {
		return 1;
	}

	my $tenting = 0;

	if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) ) {

		my $etch = $defaultInfo->GetEtchType("c");

		if ( $etch eq EnumsGeneral->Etching_TENTING ) {

			$tenting = 1;
		}

	}

	return $tenting;
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

