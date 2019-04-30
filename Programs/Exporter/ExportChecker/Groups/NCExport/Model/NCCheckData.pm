
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerErrorInfo';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerWarnInfo';
use aliased 'Packages::Routing::RoutLayer::RoutChecks::RoutCheckTools';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::CAMJob::Drilling::AspectRatioCheck';
use aliased 'Packages::CAMJob::Drilling::HolePadsCheck';
use aliased 'Packages::CAMJob::Routing::RoutPocketCheck';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::CAMJob::Routing::RoutDepthCheck';
use aliased 'Packages::CAM::UniDTM::Enums' => 'DTMEnums';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrillInfo';
use aliased 'Packages::CAMJob::Drilling::CountersinkCheck';
use aliased 'Packages::Tooling::PressfitOperation';
use aliased 'Enums::EnumsRout';
use aliased 'Packages::Polygon::Polygon::PolygonPoints';

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

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my $groupData = $dataMngr->GetGroupData();
	my $inCAM     = $dataMngr->{"inCAM"};
	my $jobId     = $dataMngr->{"jobId"};
	my $stepName  = "panel";

	my $exportSingle = $groupData->GetExportSingle();
	my $pltLayers    = $groupData->GetPltLayers();
	my $npltLayers   = $groupData->GetNPltLayers();

	# 1) Check inf export single and no layers selected
	if ($exportSingle) {

		if ( scalar( @{$pltLayers} ) + scalar( @{$npltLayers} ) == 0 ) {

			$dataMngr->_AddErrorResult( "Export single layers", "No single layers was selected." );
		}
	}

	# 2) Checking NC layers
	my $mess = "";    # errors

	unless ( LayerErrorInfo->CheckNCLayers( $inCAM, $jobId, $stepName, undef, \$mess ) ) {
		$dataMngr->_AddErrorResult( "Checking NC layer", $mess );

		# Do not continue in other check if this  "basic" check fail
		return 0;
	}

	my $mess2 = "";    # warnings

	unless ( LayerWarnInfo->CheckNCLayers( $inCAM, $jobId, $stepName, undef, \$mess2 ) ) {
		$dataMngr->_AddWarningResult( "Checking NC layer", $mess2 );
	}

	# Check if special layers are created (v; v1; fr)
	unless ($exportSingle) {

		unless ( CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_fDrill ) ) {
			$dataMngr->_AddErrorResult( "Special NC layer", "Special NC layer: \"v\" doesn't exist." );
		}

		my $v1 = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_fcDrill );
		my $fr = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_frMill );

		if ( $defaultInfo->GetLayerCnt() <= 2 ) {

			$dataMngr->_AddErrorResult( "Special NC layer", "Special NC layer: \"v1\" is not allowed for NON multilayer pcb" ) if ($v1);
			$dataMngr->_AddErrorResult( "Special NC layer", "Special NC layer: \"fr\" is not allowed for NON multilayer pcb" ) if ($fr);
		}
		else {
			$dataMngr->_AddErrorResult( "Special NC layer", "Special NC layer: \"v1\" doesn't exist." ) unless ($v1);
			$dataMngr->_AddErrorResult( "Special NC layer", "Special NC layer: \"fr\" doesn't exist." ) unless ($fr);
		}
	}

	# 3) If panel contain more drifrent step, check if fsch exist
	my @uniqueSteps = CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId, 1, [ EnumsGeneral->Coupon_IMPEDANCE ] );

	if ( scalar(@uniqueSteps) > 1 && !$defaultInfo->LayerExist("fsch") ) {

		$dataMngr->_AddErrorResult( "Checking NC layer",
									"Layer fsch doesn't exist. When panel contains more different steps, fsch must be created." );
	}

	# 4) Check if contain only one kind of nested step but with various rotation

	if ( scalar(@uniqueSteps) == 1 ) {

		my @repeatsSR = CamStepRepeatPnl->GetRepeatStep( $inCAM, $jobId, 1, [ EnumsGeneral->Coupon_IMPEDANCE ] );

		my $angle = $repeatsSR[0]->{"angle"};
		my @diffAngle = grep { $_->{"angle"} != $angle } @repeatsSR;

		if ( scalar(@diffAngle) && !$defaultInfo->LayerExist("fsch") ) {
			$dataMngr->_AddErrorResult( "Checking NC layer",
								 "Layer fsch doesn't exist. When panel contains one type of step but with various rotations, fsch must be created." );
		}
	}

	# 5) Check if outline chain are last in chain list
	my $checkLayer = "f";

	if ( $defaultInfo->LayerExist($checkLayer) ) {

		my @checkSteps = ();

		if ( $defaultInfo->LayerExist("fsch") ) {

			$checkLayer = "fsch";
			push( @checkSteps, "panel" );
		}
		else {

			my @uniqNestSteps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" );
			@checkSteps = map { $_->{"stepName"} } @uniqNestSteps;
		}

		foreach my $s (@checkSteps) {

			my $messOutline = "";
			unless ( RoutCheckTools->OutlineToolIsLast( $inCAM, $jobId, $s, $checkLayer, \$messOutline ) ) {
				$dataMngr->_AddErrorResult( "Checking NC layer - outlines", $messOutline );
			}

		}
	}

	# 6) Check foot down attributes

	my $routLayer = "f";
	if ( $defaultInfo->LayerExist($checkLayer) ) {

		my $tmpLayer = undef;
		my $checkL   = undef;

		if ( $defaultInfo->LayerExist("fsch") ) {
			$routLayer = "fsch";
			$checkL    = $routLayer;
		}
		else {

			# need faltten before check outline chains
			$tmpLayer = GeneralHelper->GetGUID();
			$inCAM->COM( 'flatten_layer', "source_layer" => $routLayer, "target_layer" => $tmpLayer );
			$checkL = $tmpLayer;
		}

		my $rtm = UniRTM->new( $inCAM, $jobId, "panel", $checkL, 1 );

		my @outline = $rtm->GetOutlineChains();

		my %hist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, "panel", $checkL, 1 );

		my $footCnt = 0;
		if ( defined $hist{".foot_down"}{""} ) {
			$footCnt = $hist{".foot_down"}{""};
		}

		if ( $footCnt != scalar(@outline) ) {
			$dataMngr->_AddWarningResult( "Checking foots",
					  "Number of 'foot_down' ($footCnt) doesn't match with number of outline routs (" . scalar(@outline) . ") in layer: $routLayer" );
		}

		if ($tmpLayer) {
			$inCAM->COM( 'delete_layer', layer => $tmpLayer );
		}

	}

	# 7) Check, when ALU material, if all plated holes aer in "f" layer

	if ( $defaultInfo->GetMaterialKind() =~ /^AL/i && $defaultInfo->LayerExist("m") ) {

		my @uniqueSteps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "panel" );

		foreach my $step (@uniqueSteps) {

			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step->{"stepName"}, "m" );

			if ( $hist{"total"} != 0 ) {

				$dataMngr->_AddErrorResult(
											"Drilling",
											"Step: "
											  . $step->{"stepName"}
											  . " contains drilling in layer 'm'. When material is ALU, all drilling should be moved to layer 'f'."
				);

			}

		}

	}

	# 7) Check, when ALU material, if all rout diameters are ok
	# Check only LAYERTYPE_nplt_nMill
	# Available tools for Al: 1; 1,5; 2; 3; mm

	if ( $defaultInfo->GetMaterialKind() =~ /^AL/i ) {

		my @aluTool = ( 1, 1.5, 2, 3 );    #all alu rout tools

		my @routLayers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill ] );

		foreach my $l (@routLayers) {

			my $unitDTM = UniDTM->new( $inCAM, $jobId, "panel", $l->{"gROWname"}, 1 );
			my @tools = map { $_->GetDrillSize() / 1000 } grep { $_->GetTypeProcess() eq EnumsDrill->TypeProc_CHAIN } $unitDTM->GetUniqueTools();

			foreach my $t (@tools) {

				unless ( scalar( grep { $_ == $t } @aluTool ) ) {
					$dataMngr->_AddErrorResult(
												"Routing",
												"Vrstva: \""
												  . $l->{"gROWname"}
												  . "\"  obsahuje sloty ("
												  . $t
												  . "mm) pro které nemáme frézovací nástroje pro ALU materiál."
												  . " Dostupné frézovací nástroje: "
												  . join( ";", @aluTool ) . "mm"
					);
				}
			}
		}
	}

	# 8) Check if fsch exist, and if "f" was changed if "fsch" was changed too
	if ( $defaultInfo->LayerExist("fsch") ) {

		my @uniqueSteps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" );

		my $fschCreated = 0;

		# check if fsch was created

		foreach my $step (@uniqueSteps) {
			my @f = ( $step->{"stepName"}, "fsch" );
			if ( CamHelper->EntityChanged( $inCAM, $jobId, "created", \@f ) ) {
				$fschCreated = 1;
				last;
			}
		}

		# if fsch was created after open job, do not control
		unless ($fschCreated) {

			my $fModified = 0;
			foreach my $step (@uniqueSteps) {

				my @f = ( $step->{"stepName"}, "f" );
				if ( CamHelper->EntityChanged( $inCAM, $jobId, "modified", \@f ) ) {
					$fModified = 1;
					last;
				}
			}

			# if f modified, check if
			if ($fModified) {
				my @fsch = ( "panel", "fsch" );
				unless ( CamHelper->EntityChanged( $inCAM, $jobId, "modified", \@fsch ) ) {
					$dataMngr->_AddWarningResult( "Old 'fsch' layer",
												 "Layer 'f' was changed, but layer 'fsch' not. If necessary, change 'fsch' layer in 'panel' too.\n" );

				}
			}

		}
	}

	# 9) Check if aspect ratio of plated layers is ok
	my @steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "panel" );

	foreach my $s (@steps) {

		my %res = ();
		unless ( AspectRatioCheck->CheckWrongARAllLayers( $inCAM, $jobId, $s, \%res ) ) {

			my $mess = "";
			if ( @{ $res{"max10.0"} } ) {

				$mess .= "\nMax aspect ratio has to be \"10.0\" for through holes:";
				foreach my $inf ( @{ $res{"max10.0"} } ) {

					my @t = map {
						    "\n- Size: "
						  . $_->GetDrillSize()
						  . "µm, aspect ratio: "
						  . sprintf( "%.2f", $_->{"aspectRatio"} )
						  . ", Layer: "
						  . $inf->{"layer"}
					} @{ $inf->{"tools"} };
					$mess .= join( "", @t );
				}
			}

			if ( @{ $res{"max1.0"} } ) {

				$mess .= "\nMax aspect ratio has to be \"1.0\" for blind holes:";
				foreach my $inf ( @{ $res{"max1.0"} } ) {

					my @t = map {
						    "\n- Size: "
						  . $_->GetDrillSize()
						  . "µm, aspect ratio: "
						  . sprintf( "%.2f", $_->{"aspectRatio"} )
						  . ", Layer: "
						  . $inf->{"layer"}
					} @{ $inf->{"tools"} };
					$mess .= join( "", @t );
				}
			}

			$dataMngr->_AddErrorResult( "Aspect ratio - step $s", $mess );
		}
	}

	# 10) Check if all blind and core drilling pads has pads in signal layers

	my @childs = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );

	my %allLayers = ();

	foreach my $step (@childs) {

		my $mess = "";

		my %pads = ();
		unless ( HolePadsCheck->CheckMissingPadsAllLayers( $inCAM, $jobId, $step, \%pads ) ) {

			foreach my $l ( keys %pads ) {

				if ( @{ $pads{$l} } ) {

					$mess .= "\nMissing pads for drilling in signal layer: \"$l\", holes:";

					my @pads =
					  map {
						    "\n- Drill hole (pad id: \""
						  . $_->{"featId"}
						  . "\"), missing pads in signal layers: \""
						  . join( ", ", @{ $_->{"missing"} } ) . "\""
					  } @{ $pads{$l} };

					$mess .= join( "", @pads );
				}
			}

			$dataMngr->_AddErrorResult( "Missing pads - step $step", $mess );
		}
	}

	# 12) Check if rout pocket has right direction

	foreach my $stepName (@steps) {

		my @layerInf = ();

		unless ( RoutPocketCheck->RoutPocketCheckDirAllLayers( $inCAM, $jobId, $stepName, 1, \@layerInf ) ) {

			my $str = join(
				"\n",
				map {
					    "- Layer: "
					  . $_->{"layer"}
					  . " has right dir: "
					  . $_->{"rightDir"}
					  . ",  wrong dir: "
					  . $_->{"wrongDir"}
					  . ". Wrong surface ids: "
					  . join( "; ", map { $_->{"id"} } @{ $_->{"surfaces"} } )
				} @layerInf
			);

			$dataMngr->_AddErrorResult(
										"Pocket direction",
										"There is a wrong pocket direction in rout layers (step $stepName) :\n"
										  . $str
										  . "\n Repair attribute .rout_pocket_direction in surfaces."
			);
		}

	}

	# 13) Check if exist layer D. This layer is permited so far (but will be probablz alowed in feature) 27.2.2018
	if ( $defaultInfo->LayerExist("d") ) {
		$dataMngr->_AddErrorResult(
									"NC vrstva D",
									"Něco se rozbilo. V matrixu je NC vrstva D. "
									  . "Tato vrstva pravděpodobně obsahuje neprokovené otvory z vrstvy f. "
									  . "Zkontroluj a vrať otovory v každého stepu do vrstvy f a smaž vrstvu d. Volej k tomu SPR."
		);
	}

	# 14) Check there aro not merged chains with same tool diameter (only depth milling)
	# (it is better when chains are merged, because of smaller amnount G82 command in NC programs)
	my $messRD = "";
	unless ( RoutDepthCheck->CheckDepthChainMerge( $inCAM, $jobId, \$messRD ) ) {
		$dataMngr->_AddErrorResult( "Merge chains", $messRD );
	}

	# 15) Check vysledne/vtane otvory
	if ( $defaultInfo->GetLayerCnt() > 1 && $defaultInfo->LayerExist("m") ) {

		my $usrHolesType = $defaultInfo->GetCustomerNote()->PlatedHolesType();
		if ( defined $usrHolesType ) {

			foreach my $s ( CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $stepName ) ) {

				my $childDTMType = CamDTM->GetDTMType( $inCAM, $jobId, $s->{"stepName"}, "m" );

				if ( defined $childDTMType && $childDTMType ne "" && $childDTMType ne $usrHolesType ) {

					$dataMngr->_AddErrorResult(
											   "DTM type",
											   "Zákazník vyžaduje otvory typu: \"$usrHolesType\" ale jsou nastaveny otvory typu: \"$childDTMType\""
												 . " Step: "
												 . $s->{"stepName"}
												 . ", vrstva \"m\""
					);
				}
			}
		}
	}

	# 16)Check blind holes, depths, aspet ratio, isolation
	my @blindL = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_plt_bDrillTop, EnumsGeneral->LAYERTYPE_plt_bDrillBot ] );

	if ( scalar(@blindL) ) {

		foreach my $s ( CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" ) ) {

			foreach my $l (@blindL) {
				my $errStrStep = "";
				unless ( BlindDrillInfo->BlindDrillChecks( $inCAM, $jobId, $s->{"stepName"}, $l, \$errStrStep ) ) {

					$dataMngr->_AddErrorResult( "Blind layers",
							   "Chybné slepé otvory (step: \"" . $s->{"stepName"} . "\", layer: \"" . $l->{"gROWname"} . "\"):\n $errStrStep\n\n" );
				}
			}
		}

	}

	# 17) Check if tool with angle and depth, has set depth biggar than tool peak len
	# Muye to zpusobit "zoubek" v otvoru

	my @wrongDepths = ();
	unless ( CountersinkCheck->WrongDepthForCSinkTool( $inCAM, $jobId, \@wrongDepths ) ) {

		my $str = join(
			"; ",
			map {
				    $_->GetDrillSize()
				  . "µm: úhel: "
				  . $_->GetAngle()
				  . ", hloubka: "
				  . ( $_->GetDepth() * 1000 )
				  . "µm, délka špičky: "
				  . $_->{"peakLen"} . "µm"
			} @wrongDepths
		);

		$dataMngr->_AddWarningResult(
			"Countersink tool",
"V jobu jsou použité nástroje s úhlem, které mají větší hloubku než je délka \"špičky frézy\". V otovoru může být nežádoucí \"zobáček\"\n"
			  . "Otvory: $str"
		);

	}

	# 18) Check if pressfit toles has set tolerances
	my @layers = PressfitOperation->GetPressfitLayers( $inCAM, $jobId, "panel", 1 );

	foreach my $l (@layers) {

		# check pressfit tools
		my @tools = CamDTM->GetDTMToolsByType( $inCAM, $jobId, "panel", $l, "press_fit", 1 );

		foreach my $t (@tools) {

			# test on finish size
			if (    !defined $t->{"gTOOLfinish_size"}
				 || $t->{"gTOOLfinish_size"} == 0
				 || $t->{"gTOOLfinish_size"} eq ""
				 || $t->{"gTOOLfinish_size"} eq "?" )
			{
				$dataMngr->_AddErrorResult( "Pressfit",
											"Tool: " . $t->{"gTOOLdrill_size"} . "µm has no finish size (layer: '" . $l . "'). Complete it.\n" );
			}

			if ( $t->{"gTOOLmin_tol"} == 0 && $t->{"gTOOLmax_tol"} == 0 ) {

				$dataMngr->_AddErrorResult( "Pressfit",
										  "Tool: " . $t->{"gTOOLdrill_size"} . "µm hasn't defined tolerance (layer: '" . $l . "'). Complete it.\n" );
			}
		}
	}

	# 19) Check if there are set tolerances in non pressfit plt holes
	foreach my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_plt_nMill ] ) ) {

		# check non pressfit tools, if tolerances are not set
		my @toolsNoPressfit =
		  grep { $_->{"gTOOLtype2"} ne "press_fit" && ( $_->{"gTOOLmin_tol"} != 0 || $_->{"gTOOLmax_tol"} != 0 ) }
		  CamDTM->GetDTMTools( $inCAM, $jobId, "panel", $l->{"gROWname"}, 1 );

		foreach my $t (@toolsNoPressfit) {

			$dataMngr->_AddErrorResult(
										"Pressfit",
										"Tool: "
										  . $t->{"gTOOLdrill_size"}
										  . "µm has set tolerances ("
										  . $t->{"gTOOLmin_tol"} . ", "
										  . $t->{"gTOOLmax_tol"}
										  . " ), but tool type is not set to \"pressfit\". Set proper tool type in DTM"
			);
		}
	}

	# 20) Check if there are set tolerances and type other than non_plated in nplt holes
	foreach my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_nplt_nDrill ] ) ) {

		# check non pressfit tools, if tolerances are not set
		my @toolsNoToler =
		  grep { $_->{"gTOOLtype"} ne "non_plated" && ( $_->{"gTOOLmin_tol"} != 0 || $_->{"gTOOLmax_tol"} != 0 ) }
		  CamDTM->GetDTMTools( $inCAM, $jobId, "panel", $l->{"gROWname"}, 1 );

		foreach my $t (@toolsNoToler) {

			$dataMngr->_AddErrorResult(
										"Tolerance holes",
										"Tool: "
										  . $t->{"gTOOLdrill_size"}
										  . "µm has set tolerances ("
										  . $t->{"gTOOLmin_tol"} . ", "
										  . $t->{"gTOOLmax_tol"}
										  . " ), but tool type is not set to \"not plated\". Set proper tool type in DTM"
			);
		}
	}

	# 21) Check if pcb pcb class less than 8 and plated drill exist
	# If so, warn user to small diameter
	if ( $defaultInfo->GetPcbClass() < 8 ) {

		my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_plt_nDrill ] );

		foreach my $step ( map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId ) ) {

			foreach my $l (@layers) {
				my $min = CamDrilling->GetMinHoleToolByLayers( $inCAM, $jobId, $step, [$l] );

				if ( defined $min && $min <= 200 ) {

					$dataMngr->_AddWarningResult(
												  "Via otvory",
												  "Ve stepu: $step, vrstvě: "
													. $l->{"gROWname"}
													. " jsou pokovené otvory s průměrem <= 200µm. "
													. "To prodlužuje dobu výroby dps. Není možné průměry zvětšit za cenu zvýšení konstrukční třídy?"
					);
				}
			}
		}
	}

	# TMP
	# Kontrola zaplenzch otovru
	if ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) ) {

		$dataMngr->_AddWarningResult( "Zaplnene via", "V jobu mas zaplnene via, nech vrtacky a postup zkontrolovat u SPR" );
	}

	# 22) Check if job viafill layer  are prepared if viafill in IS
	my $viaFillType = $defaultInfo->GetPcbBaseInfo("zaplneni_otvoru");

	# A - viafill in gatema
	# B - viafill in cooperation - all holes
	# C - viafill in cooperation - specified holes
	if ( defined $viaFillType && $viaFillType =~ /[abc]/i ) {

		unless ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) ) {

			$dataMngr->_AddErrorResult( "Via filling",
									   "V IS je požadavek na zaplnění otvorů, v jobu ale nejsou připravené NC vrstvy (mfill; scfill; ssfill)" );

		}
	}

	# 22) If mpanel exist, check if nested setps do not have circle chain (bridges are necessary)
	if ( $defaultInfo->LayerExist("f") ) {

		my $custPnlExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_panel" );

		foreach my $step ( map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId ) ) {

			if ( $step eq "mpanel" || $custPnlExist ) {

				my $rtm = UniRTM->new( $inCAM, $jobId, $step, "f", 1, 0, 1 );

				# Cyclic chains which ae inside another cyclic chain - potentional nested step without bridges
				my @cycleChains = grep { $_->GetCyclic() && $_->GetIsInside() } $rtm->GetMultiChainSeqList();

				# if at least subchain has left comp => do warning
				foreach my $multiChain (@cycleChains) {

					my @chainTools = map { $_->GetChain()->GetChainTool() } $multiChain->GetChains();
					if ( grep { $_->GetComp() eq EnumsRout->Comp_LEFT } @chainTools ) {

						my @points = map { [ $_->{"x2"}, $_->{"y2"} ] } $multiChain->GetFeatures();

						print STDERR PolygonPoints->GetPolygonArea( \@points ) . "\n";

						# Outline assume minial area of pcb > 400mm2
						next if ( PolygonPoints->GetPolygonArea( \@points ) < 500 );

						# limits of rout has to be biger than 10 mm
						my %d = PolygonPoints->GetPolygonDim( \@points );
						next if ( $d{"w"} < 10 || $d{"h"} < 10 );

						my $routStr =
						  join( "\n", map { "- Chain order: " . $_->GetChainOrder() . ", Chain source step: " . $_->GetSourceStep() } @chainTools );

						$dataMngr->_AddWarningResult(
							"Chybějící můstky",
							"Ve stepu: $step ve vrstvě: \"f\" byla detekována obrysová fréza tvořená chainy:\n$routStr\n\n"
							  . "Ujisti se, že uvnitř panelu nechybí můstky."

						);
					}
				}
			}

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
	#	my $jobId    = " F13608 ";
	#	my $stepName = " panel ";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test; pressfit

}

1;

