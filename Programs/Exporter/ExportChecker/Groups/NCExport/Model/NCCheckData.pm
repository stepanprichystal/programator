
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
use List::MoreUtils qw(uniq);
use List::Util qw(first);

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
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamStep';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerErrorInfo';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerWarnInfo';
use aliased 'Packages::CAMJob::Routing::RoutToolsCheck';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Drilling::AspectRatioCheck';
use aliased 'Packages::CAMJob::Drilling::HolePadsCheck';
use aliased 'Packages::CAMJob::Routing::RoutPocketCheck';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsDrill';
use aliased 'Enums::EnumsRout';
use aliased 'Packages::CAMJob::Routing::RoutDepthCheck';
use aliased 'Packages::CAM::UniDTM::Enums' => 'DTMEnums';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::CAMJob::Drilling::BlindDrill::BlindDrillInfo';
use aliased 'Packages::CAMJob::Drilling::CountersinkCheck';
use aliased 'Packages::Tooling::PressfitOperation';
use aliased 'Packages::Polygon::Polygon::PolygonPoints';
use aliased 'Packages::CAMJob::ViaFilling::ViaFillingCheck';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::CAM::FeatureFilter::Enums' => 'FiltrEnums';
use aliased 'Packages::CAMJob::Drilling::NPltDrillCheck';
use aliased 'Packages::CAMJob::Routing::RoutStiffener';
use aliased 'Packages::Export::NCExport::Enums' => 'EnumsNC';

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

	my $exportMode = $groupData->GetExportMode();
	my $pltLayers  = $groupData->GetSingleModePltLayers();
	my $npltLayers = $groupData->GetSingleModeNPltLayers();

	# 1) Check inf export single and no layers selected
	if ( $exportMode eq EnumsNC->ExportMode_SINGLE ) {

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
	unless ( $exportMode eq EnumsNC->ExportMode_ALL ) {

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
	my @uniqueSteps =
	  CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId, 1, [ EnumsGeneral->Coupon_IMPEDANCE, EnumsGeneral->Coupon_IPC3MAIN ] );

	if ( scalar(@uniqueSteps) > 1 && !$defaultInfo->LayerExist("fsch") ) {

		$dataMngr->_AddErrorResult( "Checking NC layer",
									"Layer fsch doesn't exist. When panel contains more different steps, fsch must be created." );
	}

	# 4) Check if contain only one kind of nested step but with various rotation

	if ( scalar(@uniqueSteps) == 1 ) {

		my @repeatsSR = CamStepRepeatPnl->GetRepeatStep( $inCAM, $jobId, 1, [ EnumsGeneral->Coupon_IMPEDANCE, EnumsGeneral->Coupon_IPC3MAIN ] );

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

		# Do not check if layer is fsch and contain impedance coupon
		# Impedance soupon are routed in sequence with standard outline, so they can by
		# routed after outline rout
		my @coupons =
		  grep { $_ eq EnumsGeneral->Coupon_IMPEDANCE || $_ eq EnumsGeneral->Coupon_IPC3MAIN } CamStep->GetAllStepNames( $inCAM, $jobId );

		if ( !( $checkLayer eq "fsch" && scalar(@coupons) ) ) {

			foreach my $s (@checkSteps) {

				my $messOutline = "";
				unless ( RoutToolsCheck->OutlineToolIsLast( $inCAM, $jobId, $s, $checkLayer, \$messOutline ) ) {
					$dataMngr->_AddErrorResult( "Checking NC layer - outlines", $messOutline );
				}

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

		my @outline = $rtm->GetOutlineChainSeqs();

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
					  . " contains wrong pocket dir: "
					  . $_->{"wrongDir"}
					  . ",  instead of proper pocket dir: "
					  . $_->{"rightDir"}
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
	if ( $defaultInfo->LayerExist("d") || $defaultInfo->LayerExist("ds")) {
		$dataMngr->_AddErrorResult(
									"NC vrstva D/DS",
									"Něco se rozbilo. V matrixu je NC vrstva D/DS. "
									  . "Tato vrstva pravděpodobně obsahuje neprokovené otvory z vrstvy f. "
									  . "Zkontroluj a vrať otovory v každého stepu do vrstvy f a smaž vrstvu d/ds."
		);
	}

	# 14) Check there aro not merged chains with same tool diameter (only depth milling)
	# (it is better when chains are merged, because of smaller amnount G82 command in NC programs)
	my $messRD = "";
	unless ( RoutDepthCheck->CheckDepthChainMerge( $inCAM, $jobId, \$messRD ) ) {
		$dataMngr->_AddErrorResult( "Merge chains", $messRD );
	}

	# 15) Check vysledne/vtane otvory (only if it is not pool - more customers on one panel)
	if ( !$defaultInfo->IsPool() && $defaultInfo->GetLayerCnt() > 1 && $defaultInfo->LayerExist("m") ) {

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

	# 20) Check if there are some wrongly put plated tools in non plated layers
	foreach my $l ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_nplt_nDrill ] ) ) {

		# check non pressfit tools, if tolerances are not set
		my @plated =
		  grep { $_->{"gTOOLtype"} eq "plated" } CamDTM->GetDTMTools( $inCAM, $jobId, "panel", $l->{"gROWname"}, 1 );

		foreach my $t (@plated) {

			$dataMngr->_AddErrorResult(
										"Prokovené otvory",
										"Ve vrstvě NEprokoveného vrtání/frézování ("
										  . $l->{"gROWname"}
										  . ") byl nalezen prokovený nástroj: "
										  . $t->{"gTOOLdrill_size"}
										  . "µm. Přesuň tento nástroj do vrstvy prokoveného vrtání/frézování nebo nastav jako \"non plated\""
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

	# 23) Check via fill distance to panel edge
	if ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) ) {

		my $errMess = "";

		unless ( ViaFillingCheck->CheckViaFillPnlEdgeDist( $inCAM, $jobId, \$errMess ) ) {
			$dataMngr->_AddErrorResult( "Via fill close to panel edge", $errMess );
		}
	}

	# 24) PLateed hole collision
	foreach my $sName ( map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" ) ) {

		my $errMess = "";

		unless ( ViaFillingCheck->CheckDrillHoleCollision( $inCAM, $jobId, $sName, \$errMess ) ) {

			$dataMngr->_AddErrorResult( "Plated holes collision", "Erorr in step: $sName; $errMess" );
		}

	}

	# 24) Check if fiducial holes in panel are not covered by stiffener or coverlay
	my @specL = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlycMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlysMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill
	} $defaultInfo->GetNCLayers();

	if ( $defaultInfo->StepExist("mpanel") && scalar(@specL) ) {

		my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, "mpanel", "c" );

		if ( defined $attHist{".fiducial_name"} ) {

			foreach my $l (@specL) {

				next if ( $l->{"gROWdrl_start"} !~ /[cs]$/ );

				my %lAttHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, "mpanel", $l->{"gROWname"} );

				if ( !defined $lAttHist{".fiducial_name"} ) {

					$dataMngr->_AddWarningResult(
						"Zakryté fiduciální značky",
						"Ve stepu: \"mpanel\" byly nalezeny fiduciální značky ve vrstvě: \"c\". Vypadá to, že nejsou odkryté ve vrstvě: "
						  . $l->{"gROWname"}
						  . " (nebyl nalezen pad s atributem .fiducial_name)"

					);

				}

			}

		}
	}

	# 25)
	# Check if rout doesn't contain tool size smaller than 1000
	# (do not consider rout pilot holes)
	{
		my $maxTool  = 1000;
		my $pltLayer = "m";

		my $note = $defaultInfo->GetCustomerNote();

		if ( !( defined $note->SmallNpth2Pth() && $note->SmallNpth2Pth() == 0 ) ) {

			if ( $defaultInfo->LayerExist($pltLayer) ) {

				my @childs = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );
				my @nplt =
				  map { $_->{"gROWname"} }
				  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill, EnumsGeneral->LAYERTYPE_nplt_nDrill ] );

				foreach my $s (@childs) {

					foreach my $npltLayer (@nplt) {

						my $checkRes = {};
						unless ( NPltDrillCheck->SmallNPltHoleCheck( $inCAM, $jobId, $s, $npltLayer, $pltLayer, $maxTool, $checkRes ) ) {

							$dataMngr->_AddWarningResult(
														  "Malé otvory v neprokovené NC vrstvě",
														  "Step: $s, NC vrstva: $npltLayer obsahuje nástroje menší jak "
															. $maxTool
															. "µm, které by měly být přesunuty do prokovené vrtačky. "
															. "\n- Seznam použitých nástrojů indikovaných otvorů: "
															. join( "; ", map { $_ . "µm" } uniq( @{ $checkRes->{"padTools"} } ) )
															. "\n- Seznam \"features Id\" padů, které mají být přesunuty: "
															. join( "; ", @{ $checkRes->{"padFeatures"} } )
															. "\nPozor, otvory obsahující atribut \".pilot_hole\" a otvory s nastavenou tolerancí v DTM se nepřesouvají!"
							);
						}
					}
				}
			}
		}
	}

	# 26) Check if one sided coverlay didn't coverl through holes.
	# If so HAL (Pb and Pb free) surface is not possible
	# If coverlay cover trhoug layer from both side, it is ok
	if (
		 $defaultInfo->GetPcbThick() > 100
		 && (    $defaultInfo->LayerExist( "cvrlc", 1 )
			  || $defaultInfo->LayerExist( "cvrls", 1 ) )
		 && $defaultInfo->GetPcbSurface() =~ /^[AB]$/i
	  )
	{

		# If exist coverlay pins, it means, only flex part without holes is covered by coverlay, thus no check
		unless ( $defaultInfo->LayerExist( "cvrpin", 1 ) ) {

			my @childs = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );
			my @lThrough = grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill }
			  $defaultInfo->GetNCLayers();

			my @lCvrlsF = grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlycMill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlysMill }
			  $defaultInfo->GetNCLayers();

			foreach my $step (@childs) {

				# Prepare helper coverlay from TOP and from BOT and do union
				# to ensure through hole are fully covered or fully opened from both coverlay sides
				my $cvrlUnion = GeneralHelper->GetGUID();

				my @lCvrlsAll =
				  map { $_->{"gROWname"} }
				  grep { $_->{"gROWname"} =~ /[cs]/ && $_->{"gROWlayer_type"} eq "coverlay" } $defaultInfo->GetBoardBaseLayers();

				my @preparedCvrl = ();
				foreach my $lCvrl (@lCvrlsAll) {

					my $lCvrlSide = CamLayer->FilledProfileLim( $inCAM, $jobId, $step );    # simulate coverlay layer form specific side
					my $routCvrl = GeneralHelper->GetGUID();                                # all coverlay rout from specifis side

					my @lCvrlsFTmp =
					  ( grep { $_->{"gROWdrl_start"} eq $lCvrl && $_->{"gROWdrl_end"} eq $lCvrl } @lCvrlsF )[0];
					foreach my $lCvrlF (@lCvrlsFTmp) {

						my $lTmp = CamLayer->RoutCompensation( $inCAM, $lCvrlF->{"gROWname"}, "document" );
						$inCAM->COM( "merge_layers", "source_layer" => $lTmp, "dest_layer" => $routCvrl );
						CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );
					}

					$inCAM->COM( "merge_layers", "source_layer" => $routCvrl, "dest_layer" => $lCvrlSide, "invert" => "yes" );
					CamMatrix->DeleteLayer( $inCAM, $jobId, $routCvrl );
					CamLayer->Contourize( $inCAM, $lCvrlSide );

					$inCAM->COM( "merge_layers", "source_layer" => $lCvrlSide, "dest_layer" => $cvrlUnion, "invert" => "no" );

					CamMatrix->DeleteLayer( $inCAM, $jobId, $lCvrlSide );
				}

				foreach my $lNC (@lThrough) {
					my $routL = GeneralHelper->GetGUID();

					if ( $lNC->{"gROWlayer_type"} eq "rout" ) {

						my $lTmp = CamLayer->RoutCompensation( $inCAM, $lNC->{"gROWname"}, "document" );
						$inCAM->COM( "merge_layers", "source_layer" => $lTmp, "dest_layer" => $routL );
						CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );
					}
					else {
						$inCAM->COM( "merge_layers", "source_layer" => $lNC->{"gROWname"}, "dest_layer" => $routL );
					}

					# Do check if all through hole are uncovered
					my $f = FeatureFilter->new( $inCAM, $jobId, $routL );

					$f->SetRefLayer($cvrlUnion);
					$f->SetReferenceMode( FiltrEnums->RefMode_TOUCH );

					if ( $f->Select() ) {
						$dataMngr->_AddErrorResult(
								   "Odkryté otvory v coverlay",
								   "Pokud je povrchová úprava HAL, "
									 . "DPS nesmí obsahovat otvory/frézu skrz, která je z jedná strany zakrytá coverlay a z druhé odkrytá. "
									 . "Ve stepu: \"$step\", ve vrstvě: \""
									 . $lNC->{"gROWname"}
									 . "\" jsou otvory/pojezdy zakryty coverlay jen z jedné strany. "
									 . "Plně zakryj nebo plně odkryj otvory/pojezdy coverlaym z obou stran, jinak dojde k delaminaci coverlay po úpravě HALem"
						);
					}

					# Remove rout layer
					CamMatrix->DeleteLayer( $inCAM, $jobId, $routL );
				}

				# Remove coverlay union
				CamMatrix->DeleteLayer( $inCAM, $jobId, $cvrlUnion );
			}
		}
	}

	# X) Check if npth rout contain PilotHoles, important for flex (one flut tour tools must be pre-drilled)
	if ( $defaultInfo->GetIsFlex() ) {

		my @pilotL = map { $_->{"gROWname"} }
		  CamDrilling->GetNCLayersByTypes(
										   $inCAM, $jobId,
										   [
											  EnumsGeneral->LAYERTYPE_plt_nMill,        EnumsGeneral->LAYERTYPE_nplt_nMill,
											  EnumsGeneral->LAYERTYPE_nplt_cvrlycMill,  EnumsGeneral->LAYERTYPE_nplt_cvrlysMill,
											  EnumsGeneral->LAYERTYPE_nplt_prepregMill, EnumsGeneral->LAYERTYPE_nplt_tapecMill,
											  EnumsGeneral->LAYERTYPE_nplt_tapesMill
										   ]
		  );

		my @childs = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );

		foreach my $s (@childs) {

			foreach my $l (@pilotL) {
				my $rtm = UniRTM->new( $inCAM, $jobId, $s, $l, 0 );
				my $chanSeqCnt = scalar( $rtm->GetChainSequences() );

				if ($chanSeqCnt) {

					my %attHist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, $s, $l, 0 );

					if ( $attHist{".pilot_hole"}->{"_totalCnt"} < $chanSeqCnt ) {

						my $pTxt = defined $attHist{".pilot_hole"}->{"_totalCnt"} ? $attHist{".pilot_hole"}->{"_totalCnt"} : 0;
						$pTxt .= "\n";

						if ( defined $attHist{".pilot_hole"} ) {
							my @p = ();
							foreach my $chainNum ( keys %{ $attHist{".pilot_hole"} } ) {

								next if ( $chainNum eq "_totalCnt" );
								push( @p, "Chain number ${chainNum} => " . $attHist{".pilot_hole"}->{$chainNum} . " pilot holes" );
							}

							$pTxt .= " (" . join( "\n ", @p ) . ")";
						}

						$dataMngr->_AddWarningResult(
													  "Předvrtání fréz - $l",
													  "Ve stepu: $s, NC vrstvě: $l byly nalezeny pojezdy frézou "
														. "(pojez = sekvence lajn/akrů od začátku do rozpojení frézy) bez předvrtání.\n"
														. " Celkem pojezdů: $chanSeqCnt vs celkem pilot holes: $pTxt\n "
														. "Zkontroluj, jestli všechny začátky pojezdů, mají pilot hole otvor, raději pilot holes vlož znovu."
						);
					}
				}
			}

		}

	}

	# X)Check if flex or Semi-hybrid PCB has proper comp (one flut tour tools must have com right/cw)
	my $isSemiHybrid = 0;
	my $isHybrid = JobHelper->GetIsHybridMat( $jobId, $defaultInfo->GetMaterialKind(), [], \$isSemiHybrid );

	if (    $defaultInfo->GetIsFlex()
		 || $isSemiHybrid )
	{

		my @NC =
		  map { $_->{"gROWname"} }
		  grep {
			     $_->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_tapebrMill
			  && $_->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_cbMillTop
			  && $_->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_cbMillBot
			  && $_->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_soldcMill
			  && $_->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_soldsMill
		  }
		  grep { $_->{"gROWlayer_type"} eq "rout" } $defaultInfo->GetNCLayers();

		my @childs = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );

		foreach my $s (@childs) {

			foreach my $l (@NC) {
				my $rtm = UniRTM->new( $inCAM, $jobId, $s, $l, 0 );
				my @wrongTools =
				  grep { $_->GetComp() ne EnumsRout->Comp_RIGHT && $_->GetComp() ne EnumsRout->Comp_CW } $rtm->GetChainList();

				if ( scalar(@wrongTools) ) {

					my $listTxt = join(
						";\n",
						map {
							    "Chain number: "
							  . $_->GetChainOrder()
							  . "; Chain tool: "
							  . $_->GetChainSize()
							  . "; Chain comp: "
							  . $_->GetComp()
						} @wrongTools
					);

					if ( scalar(@wrongTools) ) {
						$dataMngr->_AddErrorResult(
							"Kompenzace fréz - $l",
							"Ve stepu: $s, NC vrstvě: $l byly nalezeny špatné kompenzace fréz. "
							  . "Pokud se jedná o DPS typu Flex nebo o Semi-hybrid složení (standardní DPS + coverlay), "
							  . "musí mít všechny pojezdy kompenzaci RIGHT nebo CW (jde-li o surface). Důvodem je použití jednobřitých nástrojů.\n"
							  . "Seznam špatných fréz:\n$listTxt"
						);
					}
				}
			}

		}

	}

	#	Check on top/bot depth stiffener adhesive NC layer
	{
		my @stiffeners = ();
		push( @stiffeners, "top" ) if ( $defaultInfo->LayerExist( "stiffc", 1 ) );
		push( @stiffeners, "bot" ) if ( $defaultInfo->LayerExist( "stiffs", 1 ) );

		foreach my $stiffSide (@stiffeners) {

			my $tapeLName     = "tp" .    ( $stiffSide eq "top" ? "c" : "s" );
			my $stiffLName    = "stiff" . ( $stiffSide eq "top" ? "c" : "s" );
			my $stiffAdhLName = "stiff" . ( $stiffSide eq "top" ? "c" : "s" ) . "adh";
			my $stiffAdhLType = $stiffSide eq "top" ? EnumsGeneral->LAYERTYPE_nplt_stiffcAdhMill : EnumsGeneral->LAYERTYPE_nplt_stiffsAdhMill;

			my $mInf = HegMethods->GetPcbStiffenerMat( $jobId, $stiffSide );
			my $stiffThick = $mInf->{"vyska"};

			die "Stiffener $stiffSide thickness is not defined in IS" unless ( defined $stiffThick );
			$stiffThick =~ s/,/\./;
			$stiffThick *= 1000000;    # µm
			my $maxStiffH = 250;       # 250µm is max stiffener height withou depth milling of adehesive stiffener

			# Do checks if LAYERTYPE_nplt_stiffcAdhMill exists
			if ( scalar( grep { $_->{"type"} eq $stiffAdhLType } $defaultInfo->GetNCLayers() ) ) {

				if ( $stiffThick < $maxStiffH ) {
					$dataMngr->_AddErrorResult(
												"Hloubková fréza lepidla stiffeneru ${stiffSide}",
												"Deska by NEMĚLA obsahovat hloubkovou frézu lepidla stiffeneru: ${stiffAdhLName}, "
												  . "pokud tloušťka stiffeneru bez lepidla (aktuální tl.: ${stiffThick}µm) je menší jak ${maxStiffH}µm"
					);

				}
			}
			else {
				# Do checks if LAYERTYPE_nplt_stiffcAdhMill not  exists

				# Not allowed state is
				# a) if tp[cs] layer exist not exist and stiffener thickness is greater than $maxStiffH
				# b) if tp[cs] layer exist not exist and stiffener is from top side

				if (    ( !$defaultInfo->LayerExist( $tapeLName, 1 ) && $stiffThick >= $maxStiffH )
					 || ( !$defaultInfo->LayerExist( $tapeLName, 1 ) && $stiffSide eq "top" ) )
				{
					$dataMngr->_AddErrorResult(
						"Hloubková fréza lepidla stiffeneru ${stiffSide}",
						"Deska obsahuje stiffener ${stiffSide}, ale neexistuje hloubková fréza lepidla stiffeneru: ${stiffAdhLName}. "
						  . "Jedinné tři výjimky, kdy tato vrstva nemusí existovat jsou:\n\n"
						  . "a) Pokud tloušťka stiffeneru (bez lepidla) je menší jak ${maxStiffH}µm a jedná se o BOT stiffener.\n"
						  . "b) Pokud pružná oblast bez stiffeneru má tak malou plochu, do které se pojezd hloubkové frézy lepidla již nevleze. "
						  . "Respektive veškeré frézování stiffeneru i jeho lepidla je ve frézovací vrstvě: $stiffLName.\n"
						  . "c) Pokud je na straně stiffenru zároveň umístěná oboustranná páska pro zákazníka "
						  . "a ta je použita zároveň k nalepení stiffeneru (vrstva: ${tapeLName}).\n"
					);
				}
			}

		}
	}

	#	Check on top/bot stiffener adhesive depth value
	# Depth value should be always 250µm (this is enough for rout through adehsive)
	{
		my @adhMill =
		  grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcAdhMill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsAdhMill }
		  $defaultInfo->GetNCLayers();

		my $depth = RoutStiffener->GetStiffAdhRotuDepth( $inCAM, $jobId );    # depth value [mm], which is enopugh for mill through adhesive

		my @uniqueSteps = CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

		foreach my $step (@uniqueSteps) {

			foreach my $adhLayer (@adhMill) {

				my $unitDTM = UniDTM->new( $inCAM, $jobId, $step->{"stepName"}, $adhLayer->{"gROWname"}, 1 );

				my @tools =
				  grep { $_->GetTypeProcess() eq EnumsDrill->TypeProc_CHAIN && $_->GetDepth() * 1000 != $depth } $unitDTM->GetUniqueTools();

				if ( scalar(@tools) ) {

					my $depthTxt = join( "; ", map { ( $_->GetDepth() * 1000 ) . "um" } @tools );

					$dataMngr->_AddErrorResult(
												"Hloubková fréza lepidla stiffeneru ",
												"Ve vrstvě: "
												  . $adhLayer->{"gROWname"}
												  . " je špatná hodnota hloubky frézování ($depthTxt). "
												  . "Hloubka frézování lepidla stiffeneru má být přesně ${depth}µm, což je dostatečná hloubka k profrézování lepidla stiffeneru"
					);
				}

			}
		}

	}

	# Check if exist layer ftpbr - when exist layer tp[cs] and stiff[cs] (both fro msame side)
	{

		if (
			( $defaultInfo->LayerExist( "tpc", 1 ) && $defaultInfo->LayerExist( "stiffc", 1 ) )
			|| (    $defaultInfo->LayerExist( "tps", 1 )
				 && $defaultInfo->LayerExist( "stiffs", 1 ) )

		  )
		{

			my $ftpbr =
			  first { $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapebrMill } $defaultInfo->GetNCLayers();

			unless ( defined $ftpbr ) {
				$dataMngr->_AddErrorResult(
											"Fréza můstků oboustrané pásky",
											"Pokud existuje zákaznická oboustranná páska (vrstva: tp[cs]) a "
											  . "zároveň stiffener (vrstva: stiff[cs]) ze stejné strany DPS, "
											  . "tak musí existovat vrstva pro fréza můstků oboustranné pásky: ftpbr (příklad D300696)"
				);
			}

		}

	}

	# Check ftpbr layer - all rout tool shoud have d=1mm
	my $ftpbr = first { $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapebrMill } $defaultInfo->GetNCLayers();

	if ($ftpbr) {

		# bt tool 1mm (tool routs in the middle of 2mm adhesive bridges)
		my $brTool = 1000;
		my $unitDTM = UniDTM->new( $inCAM, $jobId, $stepName, $ftpbr->{"gROWname"}, 1 );
		my @tools =
		  grep { $_->GetTypeProcess() eq EnumsDrill->TypeProc_CHAIN && $_->GetDrillSize() != $brTool } $unitDTM->GetUniqueTools();

		if ( scalar(@tools) ) {

			my $toolsTxt = join( "; ", map { ( $_->GetDrillSize() ) . "um" } @tools );

			$dataMngr->_AddErrorResult(
										"Fréza můstků oboustranné pásky",
										"Fréza můstků oboustranné pásky ve vrstvě: "
										  . $ftpbr->{"gROWname"}
										  . " by měla obsahovat vždy pozejdy pouze nástrojem: 1000µm. "
										  . "Ve vrstvě byly nalezeny pojezdy o průměrech: $toolsTxt."
			);
		}
	}

	# Check if all routs in ftpbr are outside of profile
	if ($ftpbr) {

		my @uniqueSteps = CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

		foreach my $step (@uniqueSteps) {

			CamHelper->SetStep( $inCAM, $step->{"stepName"} );

			# Compensate rout
			# Copy negatife profile to layer
			# contourize
			# This sequence is responsible for split features which are both inside and outside
			# Than we can use filter and filter all in inside
			my $lTMP = CamLayer->RoutCompensation( $inCAM, $ftpbr->{"gROWname"}, "document" );

			my $lTMPProf = GeneralHelper->GetGUID();
			$inCAM->COM( "profile_to_rout", "layer" => $lTMPProf, "width" => 200 );
			CamLayer->WorkLayer( $inCAM, $lTMPProf );
			CamLayer->CopySelOtherLayer( $inCAM, [$lTMP], 1 );
			CamMatrix->DeleteLayer( $inCAM, $jobId, $lTMPProf );
			CamLayer->WorkLayer( $inCAM, $lTMP );
			CamLayer->Contourize( $inCAM, $lTMP );

			my $f = FeatureFilter->new( $inCAM, $jobId, $lTMP );

			$f->SetProfile( FiltrEnums->ProfileMode_INSIDE );

			if ( $f->Select() ) {
				$dataMngr->_AddErrorResult(
											"Fréza můstků oboustranné pásky",
											"Fréza můstků oboustranné pásky ve stepu: "
											  . $step->{"stepName"}
											  . " zasahuje do profilu desky. "
											  . "Tato fréza musí být vždy vně profilu desky, jinak v desce bude profrézovaný otvor skrz."
				);
			}

			CamMatrix->DeleteLayer( $inCAM, $jobId, $lTMP );

		}
	}

	# Check if there are surface rout in mpanel, if fsch exists
	# If not, surface rout are processed after mpanel nested step rout
	# It can cause blockage of material exhaustion, because potential material residues
	# (surfaces) should me routed first
	if ( $defaultInfo->LayerExist("f") ) {

		if ( $defaultInfo->StepExist("mpanel") && !$defaultInfo->LayerExist("fsch") ) {

			my $unitDTM = UniDTM->new( $inCAM, $jobId, "mpanel", "f" );
			my @surf = grep { $_->GetSource() eq DTMEnums->Source_DTMSURF } $unitDTM->GetTools();

			if ( scalar(@surf) ) {

				$dataMngr->_AddWarningResult(
											  "Rozfrézování v mpanelu",
											  "Ve stepu mpanel byly nalezeny pojezdy frézou pomocí typu surface. "
												. "Pokud nebude vytvořená vrstva: fsch, tyto pojezdy budou vyfrézovány "
												. "až po vyfrézování všech vnořených stepů (o+1; ...) v mpanelu. "
												. "Je to správně? Pokud ne, vytvoř fsch, která zajistí správné pořadí."
				);

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

