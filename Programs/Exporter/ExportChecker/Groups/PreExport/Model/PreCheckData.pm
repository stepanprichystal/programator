
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::Model::PreCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;
use DateTime;
use List::MoreUtils qw(uniq);
use List::Util qw(first);

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Enums::EnumsProducPanel';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::CAMJob::Material::MaterialInfo';
use aliased 'Packages::CAM::Netlist::NetlistCompare';
use aliased 'Packages::CAMJob::Scheme::SchemeCheck';
use aliased 'Packages::CAMJob::Matrix::LayerNamesCheck';
use aliased 'Packages::CAMJob::PCBConnector::GoldFingersCheck';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardBase';
use aliased 'Packages::ProductionPanel::StandardPanel::Enums' => 'StdPnlEnums';

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
	my $inCAM     = $dataMngr->{"inCAM"};
	my $jobId     = $dataMngr->{"jobId"};
	my $stepName  = "panel";

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my @sig      = $defaultInfo->GetSignalLayers();
	my $layerCnt = $defaultInfo->GetLayerCnt();
 
	# 1) Check if pcb class is at lest 3
	my $pcbClass = $defaultInfo->GetPcbClass();
	if ( !defined $pcbClass || $pcbClass < 3 ) {

		$dataMngr->_AddErrorResult( "Pcb class",
									"Pcb class is equal to \"$pcbClass\". Check job attribute: \"PcbClass\" and set at least value \"3\".\n" );
	}

	# 1) Check if layers has set polarity
	my @layers = @{ $groupData->GetSignalLayers() };

	foreach my $lInfo (@layers) {

		unless ( defined $lInfo->{"etchingType"} ) {
			$dataMngr->_AddErrorResult( "Layer etching", "Layer " . $lInfo->{"name"} . " doesn't have set etchingType." );
		}
	}

	# 2) check if layer doesn't contain spaces
	my @allL = CamJob->GetAllLayers( $inCAM, $jobId );

	foreach my $lInfo (@allL) {

		if ( $lInfo->{"gROWname"} =~ /\s/ ) {

			$dataMngr->_AddErrorResult( "Layer check", "Layer: " . $lInfo->{"gROWname"} . " contain whitespaces. Layer can't contain whitespaces." );
		}

	}

	# 3) check if layers are in right order

	my $err = 0;

	for ( my $i = 1 ; $i <= $layerCnt ; $i++ ) {

		my $l = $sig[ $i - 1 ];

		if ( $i == 1 ) {

			if ( $l->{"gROWname"} ne "c" ) {
				$err = 1;
			}

		}
		elsif ( $i == $layerCnt ) {

			if ( $l->{"gROWname"} ne "s" ) {
				$err = 1;
			}

		}
		else {

			#inner layers
			if ( $l->{"gROWname"} !~ /^v$i$/ ) {
				$err = 1;
			}
		}
	}

	if ($err) {
		$dataMngr->_AddErrorResult( "Layer check", "Order of signal layers in matrix is wrong. Fix it." );
	}

	# 4) Check if inner layers has properly set layer attribute "layer_side" (schema depands on this attribute)
	if ( $layerCnt > 2 ) {

		my $stackup = $defaultInfo->GetStackup();

		foreach my $l ( grep { $_->{"gROWname"} =~ /^v\d+$/ } @sig ) {

			# Get real side from stackup
			my $side = StackupOperation->GetSideByLayer( $inCAM, $jobId, $l->{"gROWname"}, $stackup );

			my %layerAttr = CamAttributes->GetLayerAttr( $inCAM, $jobId, $stepName, $l->{"gROWname"} );
			if ( $layerAttr{'layer_side'} !~ /^$side$/i ) {

				$dataMngr->_AddErrorResult(
											"Wrong inserted schema ",
											"Signálová vrstva: \""
											  . $l->{"gROWname"}
											  . "\" má špatně nastavený atribut vrstvy: \"Layer side\" ("
											  . $layerAttr{'layer_side'}
											  . "). Ve stackupu je vstva vedená jako: \"$side\". Uprav atribut a znovu vlož schéma do panelu!"
				);
			}
		}
	}

	# X) Check proper number of signal layers
	if ( $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER && $defaultInfo->GetLayerCnt() != 1 ) {

		$dataMngr->_AddErrorResult( "Wrong number of signal layers", "Pokud je deska typu Neplát, musí mít jednu signálovou vrstvu \"c\"" );
	}

	# X) Check proper number of signal layers
	if ( $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_1VFLEX && $defaultInfo->GetLayerCnt() != 2 ) {

		$dataMngr->_AddErrorResult( "Wrong number of signal layers",
					  "Pokud je deska typu: Jednostranný flex, musí mít dvě signálové vrstvy (vždy se vyrábí z oboustranného materiálu)" );
	}

	# X) Check if exist plt layers and technology is not galvanic
	if ( $layerCnt >= 2 ) {

		my @pltNC = grep { $_->{"plated"} && !$_->{"technical"} } $defaultInfo->GetNCLayers();
		my $tech = ( grep { $_->{"name"} eq "c" } @{ $groupData->GetSignalLayers() } )[0]->{"technologyType"};

		if ( scalar(@pltNC) && $tech ne EnumsGeneral->Technology_GALVANICS ) {
			$dataMngr->_AddWarningResult(
										  "Wrong technology",
										  "V jobu byly nalezeny prokovené NC vrstvy ("
											. join( "; ", map { $_->{"gROWname"} } @pltNC ) . "), "
											. "ale technologie není Galvanika. Je to OK?"
			);

		}

	}

	# 7) Check if dps should be pattern, if tenting is realz unchecked
	if ( $layerCnt >= 2 ) {
		my $defEtch = $defaultInfo->GetDefaultEtchType("c");
		my $formEtch = ( grep { $_->{"name"} eq "c" } @{ $groupData->GetSignalLayers() } )[0]->{"etchingType"};

		if ( $defEtch eq EnumsGeneral->Etching_PATTERN && $defEtch ne $formEtch ) {

			$dataMngr->_AddWarningResult( "Pattern", "Dps by měla jít do výroby jako pattern, ale je vybraná technologie:$formEtch" );
		}

	}

	# 4) Check if material and pcb thickness and base cuthickness is set
	my $materialKindIS = $defaultInfo->GetMaterialKind();
	$materialKindIS =~ s/[\s\t]//g;

	my $pcbType = $defaultInfo->GetPcbType();

	my $baseCuThickHelios = HegMethods->GetOuterCuThick($jobId);
	my $pcbThickHelios    = HegMethods->GetPcbMaterialThick($jobId);

	# 5) Check if helios contain base cutthick, pcb thick
	if ( $layerCnt >= 1 && $pcbType ne EnumsGeneral->PcbType_NOCOPPER ) {

		unless ( defined $baseCuThickHelios ) {

			$dataMngr->_AddErrorResult( "Base Cu", "Base Cu thickness is not defined in Helios." );
		}

		unless ( defined $pcbThickHelios ) {

			$dataMngr->_AddErrorResult( "Pcb thickness", "Pcb thickness is not defined in Helios." );
		}
	}

	# 5) Check if stackup outer base Cu thickness and IS base Cu thickness match
	if ( defined $baseCuThickHelios && $defaultInfo->GetLayerCnt() > 2 ) {

		my $stackupCu = $defaultInfo->GetStackup()->GetCuLayer("c")->GetThick();
		$stackupCu = 18
		  if ( $defaultInfo->GetPcbClass() >= 8 && $stackupCu == 9 && $baseCuThickHelios != 9 )
		  ;    # we use 9µm Cu if 8class in order easier pcb production

		if ( $stackupCu != $baseCuThickHelios ) {

			$dataMngr->_AddErrorResult(
										"Tloušťka Cu",
										"Nesouhlasí tloušťka základní Cu vnějších vrstev ve složení ("
										  . $stackupCu
										  . "µm) a v IS ("
										  . $baseCuThickHelios . "µm)"
			);
		}
	}

	# 6) Check if helios contain material kind
	unless ( defined $materialKindIS ) {

		$dataMngr->_AddErrorResult( "Material", "Material kind (Fr4, IS400, etc..) is not defined in Helios." );
	}

	if ( defined $materialKindIS && $layerCnt <= 2 && $defaultInfo->GetIsFlex() ) {

		# single layer + double layer flex PCB
		# Only PYRALUX material is possible

		my @flexMats = ("PYRALUX");

		unless ( grep { $_ =~ /$materialKindIS/i } @flexMats ) {

			$dataMngr->_AddErrorResult(
										"PCB material",
										"Jednostranné a oboustranné flexi DPS musí mít v IS zadaný jeden z následujících materiálů: "
										  . join( ";", @flexMats ) . "."
										  . "Aktuálně zadaný materiál v IS: "
										  . $materialKindIS
			);
		}

	}

	if ( $layerCnt > 2 && $materialKindIS && $pcbThickHelios ) {

		# Multilayer PCB
		my $stackup = $defaultInfo->GetStackup();

		# a) test id material in helios, match material in stackup (only non hybrid PCB)
		if ( !$stackup->GetStackupIsHybrid() ) {

			my $stackKindStr = $defaultInfo->GetStackup()->GetStackupType();
			$stackKindStr =~ s/[\s\t]//g;

			$stackKindStr =~ s/.*DE104.*/FR4/ig;    #exception DE 104 and IS400 eq FR4

			if ( $stackKindStr =~ /.*IS400.*/i && $stackKindStr =~ /PYRALUX/i ) {
				$stackKindStr = "FR4";
			}

			unless ( $stackKindStr =~ /$materialKindIS/ ) {
				$dataMngr->_AddErrorResult(
											"Stackup material",
											"Stackup material doesn't match with material in Helios. Stackup material: $stackKindStr"
											  . ", Helios material: $materialKindIS"
				);
			}

		}

		# b) test if created stackup match thickness in helios +-5%
		my $stackThick = $defaultInfo->GetStackup()->GetFinalThick(0) / 1000;

		unless ( $pcbThickHelios * 0.90 < $stackThick && $pcbThickHelios * 1.10 > $stackThick ) {

			$stackThick     = sprintf( "%.2f", $stackThick );
			$pcbThickHelios = sprintf( "%.2f", $pcbThickHelios );

			$dataMngr->_AddErrorResult( "Stackup thickness",
										"Stackup thickness ($stackThick) isn't match witch thickness in Helios ($pcbThickHelios) +-10%." );

		}
	}

	# 7) Check if contain negative layers, if powerground type is set and vice versa

	my @sigLayers = $defaultInfo->GetSignalLayers();

	foreach my $l (@sigLayers) {

		if (    ( $l->{"gROWpolarity"} eq "negative" && $l->{"gROWlayer_type"} ne "power_ground" )
			 || ( $l->{"gROWpolarity"} ne "negative" && $l->{"gROWlayer_type"} eq "power_ground" ) )
		{

			$dataMngr->_AddErrorResult(
										"Negative layer",
										"Layer: "
										  . $l->{"gROWname"}
										  . " has type: '"
										  . $l->{"gROWlayer_type"}
										  . "' and polarity: '"
										  . $l->{"gROWpolarity"}
										  . "'. It is wrong. Set polarity 'negative' and type 'power_ground'."
			);
		}
	}

	# 8) check if  if positive inner layer contains theraml pads
	# (only standard orders, because nagative layers are converted to positive when pool )
	if ( $defaultInfo->GetLayerCnt() > 2 && !$defaultInfo->IsPool() ) {

		my @layers = $defaultInfo->GetSignalLayers();

		foreach my $l (@layers) {

			if ( $l->{"gROWname"} =~ /^v\d$/ ) {

				foreach my $s ( CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId ) ) {

					my %symHist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $s->{"stepName"}, $l->{"gROWname"} );

					if ( $l->{"gROWpolarity"} eq "negative" ) {
						next;
					}

					my @thermalPads = grep { $_->{"sym"} =~ /th/ } @{ $symHist{"pads"} };

					if ( scalar(@thermalPads) ) {
						$dataMngr->_AddErrorResult(
													"Inner layers",
													"Step: \""
													  . $s->{"stepName"}
													  . "\", layer : \""
													  . $l->{"gROWname"}
													  . "\" contains thermal pads and is type: \"positive\". Are you sure, layer shouldn't be negative?"
						);
					}
				}
			}
		}
	}

	# 9) Check if board base layers, not contain attribute .rout_chan

	foreach my $l ( $defaultInfo->GetBoardBaseLayers() ) {

		my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, "panel", $l->{"gROWname"}, 1 );

		if ( $attHist{".rout_chain"} || $attHist{".comp"} ) {

			$dataMngr->_AddErrorResult( "Rout attributes",
									 "Layer : " . $l->{"gROWname"} . " contains rout attributes: '.rout_chain' or '.comp'. Delete them from layer." );
		}
	}

	# 10) Check if dimension of panel are ok, depand on finish surface
	my $surface  = $defaultInfo->GetPcbSurface($jobId);
	my $pcbThick = $defaultInfo->GetPcbThick($jobId);
	my %profLim  = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );
	my $cutPnl   = $defaultInfo->GetJobAttrByName('technology_cut');

	# if HAL PB , and thisck < 1.5mm, dim must be max 355mm height
	my $maxThinHALPB = 355;
	if (    $surface =~ /A/i
		 && $pcbThick < 1500
		 && $layerCnt <= 2 )
	{
		my $h = abs( $profLim{"yMax"} - $profLim{"yMin"} );
		if ( $h > $maxThinHALPB ) {
			$dataMngr->_AddErrorResult(
										"Panel dimension - thin PBC",
										"Nelze použít velký rozměr panelu ("
										  . $h
										  . "mm) protože surface je olovnatý HAL a zároveň tl. desky je menší 1,5mm. Max výška panelu je: $maxThinHALPB mm"
			);
		}
	}
	elsif (    $surface =~ /A/i
			&& $pcbThick < 1500
			&& $layerCnt > 2 )
	{

		my $pnl = StandardBase->new( $inCAM, $jobId );
		if (    $pnl->GetStandardType() ne StdPnlEnums->Type_NONSTANDARD
			 && $pnl->HFr() > $maxThinHALPB )
		{
			$dataMngr->_AddErrorResult(
										"Panel dimension - thin PBC",
										"Nelze použít velký rozměr panelu ("
										  . $pnl->HFr()
										  . "mm) protože surface je olovnatý HAL a zároveň tl. desky je menší 1,5mm. Max výška panelu (fr rámečku) je: $maxThinHALPB mm"
			);
		}
	}

	# X) If HAL PB and physical size of panel is larger than 460
	my $maxHALPB = 460;    # max panel height for PB HAL

	if ( $surface =~ /A/i && $layerCnt <= 2 ) {

		if ( abs( $profLim{"yMax"} - $profLim{"yMin"} ) > $maxHALPB
			 && ( !defined $cutPnl || $cutPnl =~ /^no$/i ) )
		{

			$dataMngr->_AddErrorResult(
										"Panel dimension",
										"Nelze použít panel s výškou: "
										  . abs( $profLim{"yMax"} - $profLim{"yMin"} )
										  . "mm protože surface je olovnatý HAL. Panelizuj na panel s výškou max: $maxHALPB mm"
			);
		}
	}
	elsif ( $surface =~ /A/i && $layerCnt > 2 ) {

		my $pnl = StandardBase->new( $inCAM, $jobId );
		if (    $pnl->GetStandardType() ne StdPnlEnums->Type_NONSTANDARD
			 && $pnl->HFr() > $maxHALPB
			 && ( !defined $cutPnl || $cutPnl =~ /^no$/i ) )
		{
			$dataMngr->_AddErrorResult(
										"Panel dimension",
										"Nelze použít panel s výškou (po ofrézování rámečku): "
										  . $pnl->HFr()
										  . " mm protože surface je olovnatý HAL. Panelizuj na panel s výškou max: $maxHALPB mm"
			);
		}
	}

	# If panel will be cut during production, check if there is proper set active area
	if ( $cutPnl !~ /^no$/i ) {

		my $pnl = StandardBase->new( $inCAM, $jobId );
		if ( $pnl->HArea() > 470 ) {
			$dataMngr->_AddErrorResult(
				"Výška aktivní plochy panelu",
				"Výška aktivní plochy neodpovídá střihu. Zkontroluj, jestli kusy nejsou panelizované za hranicí střihu panelu."

			);
		}

	}

	# 11) Check gold finger layers (goldc, golds)
	my $goldFinger       = 0;
	my @goldFingerLayers = ();

	foreach my $l ( ( "c", "s" ) ) {
		if (    CamHelper->LayerExists( $inCAM, $jobId, $l )
			 && CamGoldArea->GoldFingersExist( $inCAM, $jobId, $stepName, $l ) )
		{
			$goldFinger = 1;

			push( @goldFingerLayers, $l );

			# Check if exist gold finger layers
			unless ( $defaultInfo->LayerExist( "gold" . $l ) ) {
				$dataMngr->_AddErrorResult( "Gold layers", "Layer: \"$l\" contains gold fingers, but layer: \"gold$l\" doesn't exist. Create it." );
			}
		}
	}

	# 12) Check if there is minimal connection of goldfinger with gold holder
	# (check if pcb is whole in active area, shinked by 1mm from eached side) note - Gold frame extends 1mm behing active area
	if ($goldFinger) {

		my $isInside = 1;

		my %limActive = CamStep->GetActiveAreaLim( $inCAM, $jobId, $stepName );
		my %limSR = CamStepRepeatPnl->GetStepAndRepeatLim( $inCAM, $jobId );

		if (    $limActive{"xMin"} + 1 > $limSR{"xMin"}
			 || $limActive{"yMax"} - 1 < $limSR{"yMax"}
			 || $limActive{"xMax"} - 1 < $limSR{"xMax"}
			 || $limActive{"yMin"} + 1 > $limSR{"yMin"} )
		{

			$dataMngr->_AddWarningResult(
									  "Gold layers",
									  "Job obsahuje zlacený konektor, ale SR stepy jsou umístěny příliš blízko nebo až za aktivní oblastí. "
										. "Zkontroluj, jestli bude propojení konektorů s ploškou v technickém okolí dostatečně silné (2mm). "
										. "Pokud ne, změn pozici SR stepu."
			);

		}

	}

	# 13) Check if goldfinge exist or galvanic surface (G)  if panel equal to standard small dimension

	if ( ( $surface =~ /G/i || $goldFinger ) ) {

		my $cutPnl = $defaultInfo->GetJobAttrByName('technology_cut');

		if ( !defined $cutPnl || $cutPnl =~ /^no$/i ) {

			# height: small standard VV - 407, small standard VV - 355

			my %profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );

			my $h = abs( $profLim{"yMax"} - $profLim{"yMin"} );

			if ( $h > 408 ) {

				$dataMngr->_AddErrorResult(
											"Panel dimension",
											"Příliš velký panel. \nPokud job obsahuje zlacený konektor nebo povrch je galvanické zlato,"
											  . " panel musí mýt maximálně tak velký jako malý standardní panel."
				);
			}
		}

	}

	# Check if goldfinger doesn't exist, if is used wrong attribute ".gold_fineg" instead of ".gold_plating"

	if ( CamGoldArea->GoldFingersExist( $inCAM, $jobId, $stepName, undef, ".gold_finger" ) ) {

		$dataMngr->_AddErrorResult( "Gold finger",
									"Je použit špatný atribut pro konektorové zlato: \".gold_finger\". Zmněň atribut na \".gold_plating\"." );
	}

	# Check if goldfinger doesnt exist in job, but are checked in IS
	if ( $defaultInfo->GetPcbBaseInfo()->{"zlaceni"} =~ /^A$/i
		 && !CamGoldArea->GoldFingersExist( $inCAM, $jobId, $stepName, undef, ".gold_plating" ) )
	{

		$dataMngr->_AddErrorResult( "Gold connector",
									"V IS je požadavek na zlacení, ale v desce nebyl nalezen zlacený konektor (atribut .gold_plating )" );
	}

	# Check if goldfinger doesnt exist in job, but thera are layers goldc, golds
	if ( ( $defaultInfo->LayerExist("goldc") || $defaultInfo->LayerExist("golds") || $defaultInfo->LayerExist("fk") )
		 && !CamGoldArea->GoldFingersExist( $inCAM, $jobId, $stepName, undef, ".gold_plating" ) )
	{

		$dataMngr->_AddErrorResult( "Gold connector",
									"V matrixu je některá z vrstev: goldc;golds;fk, ale nebyl nalezen zlacený konektor (atribut .gold_plating )" );
	}

	# Check if all gold finger are connected, if gold finger exist
	if ($goldFinger) {

		my $mess = "";

		unless ( GoldFingersCheck->GoldFingersConnected( $inCAM, $jobId, \@goldFingerLayers, \$mess ) ) {

			$dataMngr->_AddErrorResult( "Wrong Gold finger connection", $mess );
		}
	}

	# 14) Test if stackup material is on stock
	my @affectOrder = HegMethods->GetOrdersByState( $jobId, 2 );    # Orders on Predvzrobni priprava
	my $area = undef;
	if ( scalar(@affectOrder) ) {
		my $inf           = HegMethods->GetInfoAfterStartProduce( $affectOrder[0]->{"reference_subjektu"} );
		my %dimsPanelHash = JobDim->GetDimension( $inCAM, $jobId );
		my %lim           = $defaultInfo->GetProfileLimits();
		my $pArea         = ( $lim{"xMax"} - $lim{"xMin"} ) * ( $lim{"yMax"} - $lim{"yMin"} ) / 1000000;
		$area = $inf->{"kusy_pozadavek"} / $dimsPanelHash{"nasobnost"} * $pArea;
	}

	if ( $layerCnt <= 2 ) {

		# check material only if it is standard material
		my $matSpec = $defaultInfo->GetPcbBaseInfo("material_vlastni");

		if ( $matSpec =~ /^n$/i ) {
			my $errMes = "";
			my $matOk = MaterialInfo->BaseMatInStock( $jobId, $area, \$errMes );

			unless ($matOk) {
				$dataMngr->_AddErrorResult( "Base material", "Materiál, který je obsažen ve složení nelze použít. Detail chyby: $errMes" );
			}
		}

	}
	else {

		# a) test id material in helios, match material in stackup
		my $stackup = $defaultInfo->GetStackup();

		my $errMes = "";
		my $matOk = MaterialInfo->StackupMatInStock( $inCAM, $jobId, $defaultInfo->GetStackup(), $area, \$errMes );

		unless ($matOk) {

			$dataMngr->_AddErrorResult( "Stackup material", "Materiál, který je obsažen ve složení nelze použít. Detail chyby: $errMes" );
		}
	}

	# 15) Check if all netlist control was succes in past
	my @reports = NetlistCompare->new( $inCAM, $jobId )->GetStoredReports();

	@reports = grep { !$_->Result() } @reports;

	if ( scalar(@reports) ) {

		my $m = "Byly nalezeny Netlist reporty, které skončily neúspěšně. Zjisti proč, popř. proveď novou kontrolu netlistů. Reporty:";

		foreach my $r (@reports) {

			$m .=
			    "\n- report: "
			  . $r->GetShorts()
			  . " shorts, "
			  . $r->GetBrokens()
			  . " brokens, "
			  . "Stepy: \""
			  . $r->GetStep()
			  . "\", \""
			  . $r->GetStepRef()
			  . "\", Adresa: "
			  . $r->GetReportPath();
		}

		$dataMngr->_AddErrorResult( "Netlist kontrola", $m );
	}

	# 16) If customer has required scheme, check if scheme in mpanel is ok
	my $usedScheme = undef;
	unless ( SchemeCheck->CustPanelSchemeOk( $inCAM, $jobId, \$usedScheme, $defaultInfo->GetCustomerNote() ) ) {

		my $custSchema = $defaultInfo->GetCustomerNote()->RequiredSchema();

		$dataMngr->_AddWarningResult( "Customer schema",
						   "Zákazník požaduje ve stepu: \"mpanel\" vlastní schéma: \"$custSchema\", ale je vloženo schéma: \"$usedScheme\"." );
	}

	# X) Check production panel schema
	my $usedPnlScheme = undef;
	unless ( SchemeCheck->ProducPanelSchemeOk( $inCAM, $jobId, \$usedPnlScheme ) ) {

		$dataMngr->_AddErrorResult(
									"Špatné schéma",
									"Ve stepu panel vložené špatné schéma: $usedPnlScheme (attribut: .pnl_scheme v atributech stepu)"
									  . " Vlož do panelu správné schéma"
		);

	}

	# 17) Check if all our "board" layers are realy board
	my @nonBoard = ();

	unless ( LayerNamesCheck->CheckNonBoardBaseLayers( $inCAM, $jobId, \@nonBoard ) ) {

		my $str = join( "; ", map { $_->{"gROWname"} } @nonBoard );

		$dataMngr->_AddWarningResult( "Matrix", "V matrixu jsou \"misc\" vrstvy, které by měly být \"board\": $str " );
	}

	# 18) Check if more same jobid is in production, if so add warning
	# Exclude job orders which are in production as slave
	# (slave steps are copied to mother job, thus slave job data can't be infloenced)
	my @orders = HegMethods->GetPcbOrderNumbers($jobId);
	if ( scalar(@orders) > 1 ) {

		@orders = grep { $_->{"stav"} == 4 } @orders;    #Ve výrobě (4)

		for ( my $i = scalar(@orders) - 1 ; $i > 0 ; $i-- ) {

			if ( HegMethods->GetInfMasterSlave( $orders[$i]->{"reference_subjektu"} ) eq "S" ) {
				splice @orders, $i, 1;
			}
		}

		if ( scalar(@orders) > 1 ) {

			$dataMngr->_AddWarningResult( "DPS ve výrobě",
					 "Pozor deska je již ve výrobě a export ovlivní tyto zakázky: " . join( "; ", map { $_->{"reference_subjektu"} } @orders ) );
		}

	}

	# 19) Check attribu "custom_year" if contains current year plus 1 (only SICURIT customer, id: 07418)
	if ( $defaultInfo->GetCustomerISInfo()->{"reference_subjektu"} eq "07418" ) {
		my %allAttr = CamAttributes->GetJobAttr( $inCAM, $jobId );

		if ( defined $allAttr{"custom_year"} ) {
			my $d = ( DateTime->now( "time_zone" => 'Europe/Prague' )->year() + 1 ) % 100;

			if ( $d != $allAttr{"custom_year"} ) {

				$dataMngr->_AddErrorResult( "Attribut \"custom_year\"",
										 "Atribut: \"custom_year\" (" . $allAttr{"custom_year"} . ") není aktuální" . "Měl by mít hodnotu: $d" );
			}
		}
	}

	# 22) Check if job viafill layer  are prepared if viafill in IS
	my $viaFillType = $defaultInfo->GetPcbBaseInfo("zaplneni_otvoru");

	# A - viafill in gatema
	# B - viafill in cooperation - all holes
	# C - viafill in cooperation - specified holes
	if ( defined $viaFillType && $viaFillType =~ /[abc]/i ) {

		if ( !$defaultInfo->LayerExist("plgc") || !$defaultInfo->LayerExist("plgs") ) {

			$dataMngr->_AddErrorResult( "Plg(c;s) vrstvy",
										"V IS je požadavek na zaplněné otovry, ale nejsou připravené \"plgc\" a \"plgs\" vrstvy." );
		}
	}

	# 23) Check scaling settings if match scale of signal layer and NC layers
	my @stretchCpls = ();
	if ( $layerCnt <= 2 ) {

		my @NCLayers = grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_score } $defaultInfo->GetNCLayers();

		foreach my $NClInfo (@NCLayers) {
			my $topCu = $NClInfo->{"NCSigStart"};
			my $botCu = $NClInfo->{"NCSigEnd"};

			push( @stretchCpls, { "nc" => $NClInfo, "topCu" => $topCu, "botCu" => $botCu } );
		}
	}
	else {

		my @products = $defaultInfo->GetStackup()->GetAllProducts();

		foreach my $p (@products) {

			foreach my $NC ( $p->GetNCLayers() ) {

				my $topCu = JobHelper->BuildSignalLayerName( $p->GetTopCopperLayer(), $p->GetOuterCoreTop(), $p->GetPlugging() );
				my $botCu = JobHelper->BuildSignalLayerName( $p->GetBotCopperLayer(), $p->GetOuterCoreBot(), $p->GetPlugging() );

				push( @stretchCpls, { "nc" => $NC, "topCu" => $topCu, "botCu" => $botCu } );
			}
		}
	}

	my @sigLayerSett = @{ $groupData->GetSignalLayers() };
	my @NCLayerSett  = @{ $groupData->GetNCLayersSett() };
	foreach my $strechCpl (@stretchCpls) {

		my $NCLScale = first { $_->{"name"} eq $strechCpl->{"nc"}->{"gROWname"} } @NCLayerSett;

		if ( $NCLScale->{"stretchX"} != 0 || $NCLScale->{"stretchY"} != 0 ) {

			my $SCuScale = first { $_->{"name"} eq $strechCpl->{"topCu"} } @sigLayerSett;
			my $ECuScale = first { $_->{"name"} eq $strechCpl->{"botCu"} } @sigLayerSett;

			# Top and Bot Cu stretch must be equal
			if ( $SCuScale->{"stretchX"} != $ECuScale->{"stretchX"} || $SCuScale->{"stretchY"} != $ECuScale->{"stretchY"} ) {

				$dataMngr->_AddErrorResult(
											"Stretch settings signal layers",
											"Signálové vrstvy:"
											  . $SCuScale->{"name"}
											  . " (stretchX="
											  . $SCuScale->{"stretchX"}
											  . "; stretchY="
											  . $SCuScale->{"stretchY"} . ") a "
											  . $ECuScale->{"name"}
											  . " (stretchX="
											  . $ECuScale->{"stretchX"}
											  . "; stretchY="
											  . $ECuScale->{"stretchY"}
											  . ") nemají stejné parametry roztažení motivu."
				);

			}

			# Top  Cu stretch must be equal to NC layer stretch
			if ( $SCuScale->{"stretchX"} != $NCLScale->{"stretchX"} || $SCuScale->{"stretchY"} != $NCLScale->{"stretchY"} ) {

				$dataMngr->_AddErrorResult(
											"Stretch settings signal/NC layers",
											"Signálová vrstva:"
											  . $SCuScale->{"name"}
											  . " (stretchX="
											  . $SCuScale->{"stretchX"}
											  . "; stretchY="
											  . $SCuScale->{"stretchY"}
											  . ") a NC vrstva:"
											  . $NCLScale->{"name"}
											  . " (stretchX="
											  . $NCLScale->{"stretchX"}
											  . "; stretchY="
											  . $NCLScale->{"stretchY"}
											  . ") nemají stejné parametry roztažení motivu."
				);
			}

			# Top  Cu stretch must be equal to NC layer stretch
			if ( $ECuScale->{"stretchX"} != $NCLScale->{"stretchX"} || $ECuScale->{"stretchY"} != $NCLScale->{"stretchY"} ) {

				$dataMngr->_AddErrorResult(
											"Stretch settings signal/NC layers",
											"Signálová vrstva:"
											  . $ECuScale->{"name"}
											  . " (stretchX="
											  . $ECuScale->{"stretchX"}
											  . "; stretchY="
											  . $ECuScale->{"stretchY"}
											  . ") a NC vrstva:"
											  . $NCLScale->{"name"}
											  . " (stretchX="
											  . $NCLScale->{"stretchX"}
											  . "; stretchY="
											  . $NCLScale->{"stretchY"}
											  . ") nemají stejné parametry roztažení motivu."
				);
			}

		}

	}

	# 24) If mpanel and stiffener exist, pattern fill is not alowed from stiffener side
	my @stiff = grep { $_->{"gROWlayer_type"} eq "stiffener" } $defaultInfo->GetBoardBaseLayers();
	if ( scalar(@stiff)
		 && $defaultInfo->StepExist("mpanel") )
	{

		foreach my $stiffL (@stiff) {
			my $sigL = ( $stiffL->{"gROWname"} =~ /^\w+([csv]\d*)$/ )[0];

			my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, "mpanel", $sigL, 0 );
			if ( defined $attHist{".pattern_fill"} ) {

				$dataMngr->_AddErrorResult(
											"Mpanel - výplň",
											"Pokud DPS obsauje stiffner, mpanel nesmí obsahovat ze strany stiffeneru v signálové vrstvě ("
											  . $sigL
											  . ") šrafování."
											  . " Rozpoznáno podle atributu: \".paaatern_fill\" ."
				);
			}
		}
	}

	# X) Check RigidFlex minimal thickness
	# RigidFlex Inner > 1,2mm
	# RigidFlex Outer > 0,8mm
	if ( $pcbThick < 800 && $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_RIGIDFLEXO ) {

		$dataMngr->_AddErrorResult( "Minimální tloušťka RigidFlex",
								 "Minimální vyrobitelná tloušťka RigidFlex Outer je : 800µm. Aktuální tloušťka je: " . $pcbThick . "µm" );
	}

	if ( $pcbThick < 1200 && $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_RIGIDFLEXI ) {

		$dataMngr->_AddErrorResult( "Minimální tloušťka RigidFlex",
								  "Minimální vyrobitelná tlošťka RigidFlex Inner je : 1200µm. Aktuální tloušťka je: " . $pcbThick . "µm" );
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

