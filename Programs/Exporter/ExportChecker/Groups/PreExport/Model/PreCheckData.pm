
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

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Enums::EnumsProducPanel';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';

use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::CAM::Netlist::NetlistCompare';
use aliased 'Packages::CAMJob::Scheme::CustSchemeCheck';
use aliased 'Packages::CAMJob::Matrix::LayerNamesCheck';

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

	# 4) Check if material and pcb thickness and base cuthickness is set
	my $materialKind = $defaultInfo->GetMaterialKind();
	$materialKind =~ s/[\s\t]//g;

	my $pcbType = $defaultInfo->GetTypeOfPcb();

	my $baseCuThickHelios = HegMethods->GetOuterCuThick($jobId);
	my $pcbThickHelios    = HegMethods->GetPcbMaterialThick($jobId);

	# 5) Check if helios contain base cutthick, pcb thick
	if ( $layerCnt >= 1 && $pcbType ne "Neplatovany" ) {

		unless ( defined $baseCuThickHelios ) {

			$dataMngr->_AddErrorResult( "Base Cu", "Base Cu thickness is not defined in Helios." );
		}

		unless ( defined $pcbThickHelios ) {

			$dataMngr->_AddErrorResult( "Pcb thickness", "Pcb thickness is not defined in Helios." );
		}
	}

	# 6) Check if helios contain material kind
	unless ( defined $materialKind ) {

		$dataMngr->_AddErrorResult( "Material", "Material kind (Fr4, IS400, etc..) is not defined in Helios." );
	}

	# If multilayer
	if ( $layerCnt > 2 && $materialKind && $pcbThickHelios ) {

		# a) test id material in helios, match material in stackup
		my $stackKind = $defaultInfo->GetStackup()->GetStackupType();

		#exception DE 104 eq FR4
		if ( $stackKind =~ /DE 104/i ) {
			$stackKind = "FR4";
		}

		$stackKind =~ s/[\s\t]//g;

		unless ( $materialKind =~ /$stackKind/i || $stackKind =~ /$materialKind/i ) {

			$dataMngr->_AddErrorResult( "Stackup material",
							"Stackup material doesn't match with material in Helios. Stackup material: $stackKind, Helios material: $materialKind." );
		}

		# b) test if created stackup match thickness in helios +-5%
		my $stackThick = $defaultInfo->GetStackup()->GetFinalThick() / 1000;

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
	my $surface   = $defaultInfo->GetPcbSurface($jobId);
	my $pcbThick  = $defaultInfo->GetPcbThick($jobId);
	my $panelType = $defaultInfo->GetPanelType();

	# if HAL PB , and thisck < 1.5mm => onlz small panel
	if (    $surface =~ /A/i
		 && $pcbThick < 1500
		 && ( $panelType eq EnumsProducPanel->SIZE_MULTILAYER_BIG || $panelType eq EnumsProducPanel->SIZE_STANDARD_BIG ) )
	{
		$dataMngr->_AddErrorResult( "Panel dimension",
									"Nelze použít velký rozměr panelu protože surface je olovnatý HAL a zároveň tl. desky je menší 1,5mm" );
	}

	# 11) Check gold finger layers (goldc, golds)
	my $goldFinger = 0;

	foreach my $l ( ( "c", "s" ) ) {
		if (    CamHelper->LayerExists( $inCAM, $jobId, $l )
			 && CamGoldArea->GoldFingersExist( $inCAM, $jobId, $stepName, $l ) )
		{
			$goldFinger = 1;

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

	# 13) Check if goldfinge exist or galvanic surface if panel equal to standard small dimension
	if ( $surface =~ /G/i || $goldFinger ) {

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

	# 14) Test if stackup material is on stock
	if ( $layerCnt > 2 ) {

		# a) test id material in helios, match material in stackup
		my $stackup = $defaultInfo->GetStackup();

		my $errMes = "";
		my $matOk = StackupOperation->StackupMatInStock( $inCAM, $jobId, $defaultInfo->GetStackup(), \$errMes );

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
	unless ( CustSchemeCheck->CustSchemeOk( $inCAM, $jobId, \$usedScheme, $defaultInfo->GetCustomerNote() ) ) {

		my $custSchema = $defaultInfo->GetCustomerNote()->RequiredSchema();

		$dataMngr->_AddWarningResult( "Customer schema",
						   "Zákazník požaduje ve stepu: \"mpanel\" vlastní schéma: \"$custSchema\", ale je vloženo schéma: \"$usedScheme\"." );
	}

	# 17) Check if all our "board" layers are realy board
	my @nonBoard = ();

	unless ( LayerNamesCheck->CheckNonBoardBaseLayers( $inCAM, $jobId, \@nonBoard ) ) {

		my $str = join( "; ", map { $_->{"gROWname"} } @nonBoard );

		$dataMngr->_AddWarningResult( "Matrix", "V matrixu jsou \"misc\" vrstvy, které by měly být \"board\": $str " );
	}

	# 18) Check if more same jobid is in production, if so add warning
	my @orders = HegMethods->GetPcbOrderNumbers($jobId);
	if ( scalar(@orders) > 1 ) {
 
		@orders    = grep { $_->{"stav"} == 4 } @orders;    #Ve výrobě (4)
		
		if(scalar(@orders) > 1 ){
			
			$dataMngr->_AddWarningResult( "DPS ve výrobě", "Pozor deska je již ve výrobě a export ovlivní tyto zakázky: ".join("; ", map{ $_->{"reference_subjektu"}} @orders));
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

