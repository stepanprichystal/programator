
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
use aliased 'CamHelpers::CamHistogram';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerCheckError';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerCheckWarn';
use aliased 'Packages::Routing::RoutLayer::RoutChecks::RoutCheckTools';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::CAMJob::Drilling::CheckAspectRatio';
use aliased 'Packages::CAMJob::Drilling::CheckHolePads';
use aliased 'Packages::CAMJob::Routing::CheckRoutPocket';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Routing::CheckRoutDepth';
use aliased 'Packages::CAM::UniDTM::Enums' => 'DTMEnums';
use aliased 'CamHelpers::CamDTM';

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

	unless ( LayerCheckError->CheckNCLayers( $inCAM, $jobId, $stepName, undef, \$mess ) ) {
		$dataMngr->_AddErrorResult( "Checking NC layer", $mess );
	}

	my $mess2 = "";    # warnings

	unless ( LayerCheckWarn->CheckNCLayers( $inCAM, $jobId, $stepName, undef, \$mess2 ) ) {
		$dataMngr->_AddWarningResult( "Checking NC layer", $mess2 );
	}

	# 3) If panel contain more drifrent step, check if fsch exist
	my @uniqueSteps = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "panel" );

	if ( scalar(@uniqueSteps) > 1 && !$defaultInfo->LayerExist("fsch") ) {

		$dataMngr->_AddErrorResult( "Checking NC layer",
									"Layer fsch doesn't exist. When panel contains more different steps, fsch must be created." );
	}

	# 4) Check if contain only one kind of nested step but with various rotation

	if ( scalar(@uniqueSteps) == 1 ) {

		my @repeatsSR = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, "panel" );

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

	if ( $defaultInfo->GetMaterialKind() =~ /al/i ) {

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

	if ( $defaultInfo->GetMaterialKind() =~ /al/i ) {

		my @aluTool = ( 1, 1.5, 2, 3 );    #all alu rout tools

		my @routLayers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill ] );

		foreach my $l (@routLayers) {

			my $unitDTM = UniDTM->new( $inCAM, $jobId, "panel", $l->{"gROWname"}, 1 );
			my @tools = map { $_->GetDrillSize() / 1000 } grep { $_->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN } $unitDTM->GetUniqueTools();

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
		unless ( CheckAspectRatio->CheckWrongARAllLayers( $inCAM, $jobId, $s, \%res ) ) {

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

	my @childs = map { $_->{"stepName"} } CamStepRepeat->GetUniqueDeepestSR( $inCAM, $jobId, "panel" );

	my %allLayers = ();

	foreach my $step (@childs) {

		my $mess = "";

		my %pads = ();
		unless ( CheckHolePads->CheckMissingPadsAllLayers( $inCAM, $jobId, $step, \%pads ) ) {

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

		unless ( CheckRoutPocket->CheckRoutPocketDirAllLayers( $inCAM, $jobId, $stepName, 1, \@layerInf ) ) {

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
	unless ( CheckRoutDepth->CheckDepthChainMerge( $inCAM, $jobId, \$messRD ) ) {
		$dataMngr->_AddErrorResult( "Merge chains", $messRD );
	}

	# 15) Check vysledne/vtane otvory
	if ( $defaultInfo->GetLayerCnt() > 1 && $defaultInfo->LayerExist("m") ) {

		my $usrHolesType = $defaultInfo->GetCustomerNote()->PlatedHolesType();
		if ( defined $usrHolesType ) {

			foreach my $s ( CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $stepName ) ) {

				my $childDTMType = CamDTM->GetDTMType( $inCAM, $jobId, $s->{"stepName"}, "m" );

				if ( $childDTMType ne $usrHolesType ) {

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

	#print $test; pressfit

}

1;

