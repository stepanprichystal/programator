
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
use aliased 'CamHelpers::CamMatrix';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::CAMJob::Material::MaterialInfo';
use aliased 'Packages::CAMJob::Scheme::SchemeCheck';
use aliased 'Packages::CAMJob::Matrix::LayerNamesCheck';
use aliased 'Packages::CAMJob::PCBConnector::GoldFingersCheck';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardBase';
use aliased 'Packages::ProductionPanel::StandardPanel::Enums' => 'StdPnlEnums';
use aliased 'Packages::ProductionPanel::PanelDimension';
use aliased 'Packages::CAMJob::Stackup::StackupCheck';

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

	my $offer = JobHelper->GetJobIsOffer( $dataMngr->{"jobId"} );

	$self->__CheckGroupDataBasic($dataMngr);
	$self->__CheckGroupDataExtend($dataMngr) if ( !$offer );

}

# Basic control (export offers use this control)
# Based rather on matrix layer presence than on PCB data
sub __CheckGroupDataBasic {
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

	# X) Check proper number of signal layers
	if ( $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER && $defaultInfo->GetLayerCnt() != 1 ) {

		$dataMngr->_AddErrorResult( "Wrong number of signal layers", "Pokud je deska typu Nepl??t, mus?? m??t jednu sign??lovou vrstvu \"c\"" );
	}

	# X) Check proper number of signal layers
	if ( $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_1VFLEX && $defaultInfo->GetLayerCnt() != 2 ) {

		$dataMngr->_AddErrorResult( "Wrong number of signal layers",
					  "Pokud je deska typu: Jednostrann?? flex, mus?? m??t dv?? sign??lov?? vrstvy (v??dy se vyr??b?? z oboustrann??ho materi??lu)" );
	}

	# X) Check proper layer names according layer tape
	{
		my @boardBase = $defaultInfo->GetBoardBaseLayers();

		my @errLayer = ();

		# Coverlay names
		my @cvrl = grep { $_->{"gROWlayer_type"} eq "coverlay" } @boardBase;
		if ( scalar(@cvrl) ) {

			my @wrong = map { $_->{"gROWname"} } grep { $_->{"gROWname"} !~ /^cvrl([cs]|(v\d+))$/ } @cvrl;

			push( @errLayer, [ "coverlay", \@wrong ] ) if ( scalar(@wrong) );
		}

		# Stiffener names
		my @stiff = grep { $_->{"gROWlayer_type"} eq "stiffener" } @boardBase;
		if ( scalar(@stiff) ) {

			my @wrong = map { $_->{"gROWname"} } grep { $_->{"gROWname"} !~ /^stiff[cs]$/ } @stiff;

			push( @errLayer, [ "stiffener", \@wrong ] ) if ( scalar(@wrong) );
		}

		# Tape names
		my @tapes = grep { $_->{"gROWlayer_type"} eq "psa" } @boardBase;
		if ( scalar(@tapes) ) {

			my @wrong = map { $_->{"gROWname"} } grep { $_->{"gROWname"} !~ /^tp(stiff)?[cs]$/ } @tapes;

			push( @errLayer, [ "psa", \@wrong ] ) if ( scalar(@wrong) );
		}

		foreach my $err (@errLayer) {

			$dataMngr->_AddErrorResult( "Wrong layer names",
						 "V matrixu jsou vrstvy typu: \"" . $err->[0] . "\", kter?? maj?? ??patn?? form??t n??zvu: " . join( "; ", @{ $err->[1] } ) );
		}

	}

	# X) Check proper layer types according layer name
	{
		my @boardBase = $defaultInfo->GetBoardBaseLayers();

		my @errLayer = ();

		# Coverlay names
		my @cvrl = grep { $_->{"gROWname"} =~ /^cvrl([cs]|(v\d+))$/ } @boardBase;
		if ( scalar(@cvrl) ) {

			my @wrong = map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} ne "coverlay" } @cvrl;

			push( @errLayer, [ "coverlay", \@wrong ] ) if ( scalar(@wrong) );
		}

		# Stiffener names
		my @stiff = grep { $_->{"gROWname"} =~ /^stiff[cs]$/ } @boardBase;
		if ( scalar(@stiff) ) {

			my @wrong = map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} ne "stiffener" } @stiff;

			push( @errLayer, [ "stiffener", \@wrong ] ) if ( scalar(@wrong) );
		}

		# Tape names
		my @tapes = grep { $_->{"gROWname"} =~ /^tp(stiff)?[cs]$/ } @boardBase;
		if ( scalar(@tapes) ) {

			my @wrong = map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} ne "psa" } @tapes;

			push( @errLayer, [ "psa", \@wrong ] ) if ( scalar(@wrong) );
		}

		foreach my $err (@errLayer) {

			$dataMngr->_AddErrorResult( "Wrong layer types",
									"V matrixu jsou vrstvy s n??zvy: " . join( "; ", @{ $err->[1] } ) . ", kter?? maj?? ??patn?? typ: " . $err->[0] );
		}

	}

	# X) Check if exist plt layers and technology is not galvanic
	if ( $layerCnt >= 2 ) {

		my @pltNC = grep { $_->{"plated"} && !$_->{"technical"} } $defaultInfo->GetNCLayers();
		my $tech = ( grep { $_->{"name"} eq "c" } @{ $groupData->GetSignalLayers() } )[0]->{"technologyType"};

		if ( scalar(@pltNC) && $tech ne EnumsGeneral->Technology_GALVANICS ) {
			$dataMngr->_AddWarningResult(
										  "Wrong technology",
										  "V jobu byly nalezeny prokoven?? NC vrstvy ("
											. join( "; ", map { $_->{"gROWname"} } @pltNC ) . "), "
											. "ale technologie nen?? Galvanika. Je to OK?"
			);

		}

	}

	# 7) Check if dps should be pattern, if tenting is realz unchecked
	if ( $layerCnt >= 2 ) {
		my $defEtch = $defaultInfo->GetDefaultEtchType("c");
		my $formEtch = ( grep { $_->{"name"} eq "c" } @{ $groupData->GetSignalLayers() } )[0]->{"etchingType"};

		if ( $defEtch eq EnumsGeneral->Etching_PATTERN && $defEtch ne $formEtch ) {

			$dataMngr->_AddWarningResult( "Pattern", "Dps by m??la j??t do v??roby jako pattern, ale je vybran?? technologie:$formEtch" );
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
	# Check only difference greater than 10??m, because of exception for high class
	# If in HEG is 18, it could by 9, 12, 18 phzsicaly in stackup. It is possible
	if ( defined $baseCuThickHelios && $defaultInfo->GetLayerCnt() > 2 ) {

		use constant MINDIFFCU => 10;    # 10??m difference

		my $stackupCu = $defaultInfo->GetStackup()->GetCuLayer("c")->GetThick();

		if ( abs( $stackupCu - $baseCuThickHelios ) > MINDIFFCU ) {

			$dataMngr->_AddErrorResult(
										"Tlou????ka Cu",
										"Nesouhlas?? tlou????ka z??kladn?? Cu vn??j????ch vrstev ve slo??en?? ("
										  . $stackupCu
										  . "??m) a v IS ("
										  . $baseCuThickHelios . "??m)"
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

		my @flexMats = ( "PYRALUX", "THINFLEX" );

		unless ( grep { $_ =~ /$materialKindIS/i } @flexMats ) {

			$dataMngr->_AddErrorResult(
										"PCB material",
										"Jednostrann?? a oboustrann?? flexi DPS mus?? m??t v IS zadan?? jeden z n??sleduj??c??ch materi??l??: "
										  . join( ";", @flexMats ) . "."
										  . "Aktu??ln?? zadan?? materi??l v IS: "
										  . $materialKindIS
			);
		}

	}

	# Check if material in helios match with multilayer stackup

	if ( $layerCnt > 2 && $materialKindIS ) {

		# Multilayer PCB
		my $stackup = $defaultInfo->GetStackup();

		# a) If stackup is hybrid, IS kind must be hybrid too
		if ( $stackup->GetStackupIsHybrid() && $materialKindIS !~ /hybrid/i ) {
			$dataMngr->_AddErrorResult( "Hybrid stackup material", "Stackup material is Hybrid but IS material not ($materialKindIS)." );

		}

		# b) test id material in helios, match material in stackup (only non hybrid PCB)
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

		# c) test if created stackup match thickness in helios +-10%
		if ( defined $pcbThickHelios ) {

			my $stackThick = $defaultInfo->GetStackup()->GetFinalThick(0) / 1000;

			unless ( $pcbThickHelios * 0.90 < $stackThick && $pcbThickHelios * 1.10 > $stackThick ) {

				$stackThick     = sprintf( "%.2f", $stackThick );
				$pcbThickHelios = sprintf( "%.2f", $pcbThickHelios );

				$dataMngr->_AddErrorResult(
											"Tlou????ka slo??en?? +-10%",
											"Odhad v??sledn?? tlou????ky slo??en?? v??etn?? nakoven?? (${stackThick}mm)"
											  . " se nerovn?? po??adovan?? tlou????ce z??kazn??ka v HEG (${pcbThickHelios}mm) +-10%."
				);

			}
			else {
				# Stricter check than +-10%, but only warning
				# Test if created stackup match thickness in helios +-7%
				# Only special PCB
				# - RigidFlex; Multilayer > 8; Sequential lamination; Inner plated layers;

				if ( $defaultInfo->GetLayerCnt() > 2 ) {

					my $stckp = $defaultInfo->GetStackup();
					if (    $defaultInfo->GetIsFlex()
						 || $defaultInfo->GetLayerCnt() > 8
						 || $stckp->GetSequentialLam()
						 || scalar( grep { $_->GetIsPlated() } $stckp->GetInputProducts() ) > 0 )
					{

						unless ( $pcbThickHelios * 0.93 < $stackThick && $pcbThickHelios * 1.07 > $stackThick ) {

							$stackThick     = sprintf( "%.2f", $stackThick );
							$pcbThickHelios = sprintf( "%.2f", $pcbThickHelios );

							$dataMngr->_AddWarningResult(
														  "Tlou????ka slo??en?? +-7% (p????sn??j???? varianta kontroly +-10% pro slo??it?? DPS)",
														  "Odhad v??sledn?? tlou????ky slo??en?? v??etn?? nakoven?? (${stackThick}mm)"
															. " se nerovn?? po??adovan?? tlou????ce z??kazn??ka v HEG (${pcbThickHelios}mm) +-7% "
															. "(pozor, podm??nka +-10% je spln??na, jedn?? se v??ak v??dy pouze o p??edpokl??danou tlou????ku po vyroben?? DPS!)."
							);

						}
					}
				}

			}
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

	# 9) Check if board base layers, not contain attribute .rout_chan

	foreach my $l ( $defaultInfo->GetBoardBaseLayers() ) {

		my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, "panel", $l->{"gROWname"}, 1 );

		if ( $attHist{".rout_chain"} || $attHist{".comp"} ) {

			$dataMngr->_AddErrorResult( "Rout attributes",
									 "Layer : " . $l->{"gROWname"} . " contains rout attributes: '.rout_chain' or '.comp'. Delete them from layer." );
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
				$dataMngr->_AddErrorResult( "Base material", "Materi??l, kter?? je obsa??en ve slo??en?? nelze pou????t. Detail chyby: $errMes" );
			}
		}

	}
	else {

		# a) test id material in helios, match material in stackup
		my $stackup = $defaultInfo->GetStackup();

		my $errMes = "";
		my $matOk = MaterialInfo->StackupMatInStock( $inCAM, $jobId, $defaultInfo->GetStackup(), $area, \$errMes );

		unless ($matOk) {

			$dataMngr->_AddErrorResult( "Stackup material", "Materi??l, kter?? je obsa??en ve slo??en?? nelze pou????t. Detail chyby: $errMes" );
		}
	}

	# 17) Check if all our "board" layers are realy board
	my @nonBoard = ();

	unless ( LayerNamesCheck->CheckNonBoardBaseLayers( $inCAM, $jobId, \@nonBoard ) ) {

		my $str = join( "; ", map { $_->{"gROWname"} } @nonBoard );

		$dataMngr->_AddWarningResult( "Matrix", "V matrixu jsou \"misc\" vrstvy, kter?? by m??ly b??t \"board\": $str " );
	}

	# 18) Check if more same jobid is in production, if so add warning
	# Exclude job orders which are in production as slave
	# (slave steps are copied to mother job, thus slave job data can't be infloenced)
	my @orders = HegMethods->GetPcbOrderNumbers($jobId);
	if ( scalar(@orders) > 1 ) {

		@orders = grep { $_->{"stav"} == 4 } @orders;    #Ve v??rob?? (4)

		for ( my $i = scalar(@orders) - 1 ; $i > 0 ; $i-- ) {

			if ( HegMethods->GetInfMasterSlave( $orders[$i]->{"reference_subjektu"} ) eq "S" ) {
				splice @orders, $i, 1;
			}
		}

		if ( scalar(@orders) > 1 ) {

			$dataMngr->_AddWarningResult( "DPS ve v??rob??",
					 "Pozor deska je ji?? ve v??rob?? a export ovlivn?? tyto zak??zky: " . join( "; ", map { $_->{"reference_subjektu"} } @orders ) );
		}

	}

	# X) Check RigidFlex minimal thickness
	# RigidFlex Inner > 1,2mm
	# RigidFlex Outer > 0,8mm
	my $pcbThick = $defaultInfo->GetPcbThick($jobId);
	if ( $pcbThick < 800 && $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_RIGIDFLEXO ) {

		$dataMngr->_AddErrorResult( "Minim??ln?? tlou????ka RigidFlex",
								  "Minim??ln?? vyrobiteln?? tlou????ka RigidFlex Outer je : 800??m. Aktu??ln?? tlou????ka je: " . $pcbThick . "??m" );
	}

	if ( $pcbThick < 1000 && $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_RIGIDFLEXI ) {

		$dataMngr->_AddErrorResult( "Minim??ln?? tlou????ka RigidFlex",
								  "Minim??ln?? vyrobiteln?? tlo????ka RigidFlex Inner je : 1000??m. Aktu??ln?? tlou????ka je: " . $pcbThick . "??m" );
	}

	# X) Check if bend area layer is not missng
	if ( ( $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_RIGIDFLEXO || $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_RIGIDFLEXI )
		 && !$defaultInfo->LayerExist( "bend", 1 ) )
	{

		$dataMngr->_AddErrorResult( "Bend area layer", "DPS je typu RigidFlex, v matrixu chyb?? board vrstva: \"bend\", typu: \"bend_area\" " );

	}

	# X) Check if cvrlpins is not missng
	if ( $defaultInfo->GetPcbType() eq EnumsGeneral->PcbType_RIGIDFLEXI && !$defaultInfo->LayerExist( "cvrlpins", 1 ) ) {

		$dataMngr->_AddErrorResult( "Cvrlpins layer",
									"DPS je typu RigidFlex Inner, v matrixu chyb?? board vrstva: \"cvrlpins\", typu: \"bend_area\" " );

	}

	# Check stiffener layer dont match with value in IS
	my %stiffIS = HegMethods->GetStiffenerType($jobId);
	my %stiffJob = (
					 "top" => $defaultInfo->LayerExist( "stiffc", 1 ),
					 "bot" => $defaultInfo->LayerExist( "stiffs", 1 )
	);

	if ( ( $stiffIS{"top"} != $stiffJob{"top"} ) || ( $stiffIS{"bot"} != $stiffJob{"bot"} ) ) {

		$dataMngr->_AddErrorResult(
									"Stiffener vrstvy",
									"Vrstvy v jobu pro stiffener nesed?? s informac?? v IS. "
									  . "\nStiffener TOP - v matrixu: "
									  . ( $stiffJob{"top"} ? "ano" : "ne" )
									  . ", v IS: "
									  . ( $stiffIS{"top"} ? "ano" : "ne" )
									  . "\nStiffener BOT - v matrixu: "
									  . ( $stiffJob{"bot"} ? "ano" : "ne" )
									  . ", v IS: "
									  . ( $stiffIS{"bot"} ? "ano" : "ne" )
		);

	}

	# Check coverlay layer dont match with value in IS
	my %cvrlIS = HegMethods->GetCoverlayType($jobId);
	my %cvrlJob = (
					"top" => 0,
					"bot" => 0
	);

	foreach my $cvrl ( grep { $_->{"gROWlayer_type"} eq "coverlay" } $defaultInfo->GetBoardBaseLayers() ) {

		$cvrlJob{"top"} = 1 if ( CamMatrix->GetNonSignalLayerSide( $inCAM, $jobId, $cvrl->{"gROWname"} ) eq "top" );
		$cvrlJob{"bot"} = 1 if ( CamMatrix->GetNonSignalLayerSide( $inCAM, $jobId, $cvrl->{"gROWname"} ) eq "bot" );
	}

	if ( ( $cvrlIS{"top"} != $cvrlJob{"top"} ) || ( $cvrlIS{"bot"} != $cvrlJob{"bot"} ) ) {

		$dataMngr->_AddErrorResult(
									"Coverlay vrstvy",
									"Vrstvy v jobu pro coverlay nesed?? s informac?? v IS. "
									  . "\nCoverlay TOP - v matrixu: "
									  . ( $cvrlJob{"top"} ? "ano" : "ne" )
									  . ", v IS: "
									  . ( $cvrlIS{"top"} ? "ano" : "ne" )
									  . "\nCoverlay BOT - v matrixu: "
									  . ( $cvrlJob{"bot"} ? "ano" : "ne" )
									  . ", v IS: "
									  . ( $cvrlIS{"bot"} ? "ano" : "ne" )
		);

	}

	# Check coverlay adhesive thickness which depands on cu thickness
	foreach my $cvrl ( grep { $_->{"gROWlayer_type"} eq "coverlay" } $defaultInfo->GetBoardBaseLayers() ) {

		my $cuLayerName;
		my $side = CamMatrix->GetNonSignalLayerSide( $inCAM, $jobId, $cvrl->{"gROWname"}, $defaultInfo->GetStackup(), \$cuLayerName );
		my $matInfo = HegMethods->GetPcbCoverlayMat( $jobId, $side );
		my $adhThick = $matInfo->{"doplnkovy_rozmer"} * 1000000;    # in ??m

		my $cuLayer = first { $_->{"name"} eq $cuLayerName } @{ $groupData->GetSignalLayers() };
		if ( defined $cuLayer ) {
			my $cuThick = $defaultInfo->GetBaseCuThick($cuLayerName);
			$cuThick += 25 if ( $cuLayer->{"technologyType"} eq EnumsGeneral->Technology_GALVANICS );    # add plating 25??m

			my $minAdh = int( $cuThick / 35 * 25 );
			my $maxAdh = int( $minAdh + 15 );
			if ( $adhThick < $minAdh ) {

				$dataMngr->_AddErrorResult(
					"Coverlay - mal?? tlou????ka lepidla",
					"Coverlay: "
					  . $cvrl->{"gROWname"}
					  . " ze strany: $side, m?? p????li?? malou tlou????ku lepidla ($adhThick ??m lepidla na $cuThick ??m Cu na stran??: $cuLayerName)."
					  . "\nMinim??ln?? pot??ebn?? tlou????ka lepidla je: $minAdh ??m. "
					  . "\nMaxim??ln?? doporu??en?? tlou????ka lepidla je: $maxAdh ??m."
					  . "\nPou??ij materi??l s v??t???? tlou????kou lepidla, jinak dojde k delaminaci."
					  . "\n(Pravidlo: na ka??d??ch 35??m Cu, 25??m lepidla)"
				);
			}
			elsif ( $adhThick > $maxAdh ) {

				$dataMngr->_AddErrorResult(
					"Coverlay - velk?? tlou????ka lepidla",
					"Coverlay: "
					  . $cvrl->{"gROWname"}
					  . " ze strany: $side, m?? p????li?? velkou tlou????ku lepidla ($adhThick ??m lepidla na $cuThick ??m Cu na stran??: $cuLayerName)."
					  . "\nMinim??ln?? pot??ebn?? tlou????ka lepidla je: $minAdh ??m. "
					  . "\nMaxim??ln?? doporu??en?? tlou????ka lepidla je: $maxAdh ??m."
					  . "\nPou??ij materi??l s men???? tlou????kou lepidla, jinak dojde zbyte??n?? k vyte??en?? lepidla - \"Adhezive squeezeout\""
					  . "\n(Pravidlo: na ka??d??ch 35??m Cu, 25??m lepidla)"
				);
			}
		}
	}

	# X) Check if rout stiffener layer has set attribute "thickness"
	# which says total required PCB thickness in area of stiffener
	my @stiffL = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill
	} $defaultInfo->GetNCLayers();

	foreach my $l (@stiffL) {

		my @steps = ();

		if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $stepName ) ) {
			my @SR = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $stepName );

			CamStepRepeat->RemoveCouponSteps( \@SR );
			push( @steps, map { $_->{"stepName"} } @SR );
		}
		else {

			@steps = ($stepName);
		}

		foreach my $step (@steps) {

			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $l->{"gROWname"}, 0 );
			next if ( $hist{"total"} == 0 );

			my %att = CamAttributes->GetLayerAttr( $inCAM, $jobId, $step, $l->{"gROWname"} );

			my $pcbThick = $att{"final_pcb_thickness"};

			if ( !$pcbThick || $pcbThick eq "" || $pcbThick <= 0 ) {
				$dataMngr->_AddErrorResult(
					"Tlou????ka DPS v m??st?? stiffeneru",
					"Nen?? zadan?? tlou????ka DPS v m??st?? stiffeneru pro vrstvu: "
					  . $l->{"gROWname"}
					  . " ve stepu: \"$step\"."
					  . " Zadej celkovou tlou????ku DPS v m??st?? stiffeneru po??adovanou z??kazn??kem. "
					  . "Step: \"$step\", vrstva: \""
					  . $l->{"gROWname"}
					  . "\", atribut: \"Final pcb thickness\", jednotky: ??m"

				);
			}
		}
	}

	# X) Check if X-out required and too big panel
	{
		my $pcbType     = $defaultInfo->GetPcbType();
		my $stackupCode = $defaultInfo->GetStackupCode();
		if (
			 (
			      $pcbType eq EnumsGeneral->PcbType_2VFLEX
			   || $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI
			   || ( $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO && $stackupCode->GetUsedFlexLayerCnt() >= 2 )
			 )
			 && $defaultInfo->GetPcbBaseInfo()->{"xout"} =~ /^A$/i
		  )
		{

			my %dim = JobDim->GetDimension( $inCAM, $jobId );

			if ( defined $dim{"nasobnost_panelu"} && $dim{"nasobnost_panelu"} ne "" ) {

				# max area of panel if xout 2,2dm
				my $maxArea = 2.2;
				my $curArea = sprintf( "%.2f", ( $dim{"panel_x"} * $dim{"panel_y"} ) ) / 10000;
				if ( $dim{"nasobnost_panelu"} > 10 || ( $dim{"nasobnost_panelu"} > 1 && $curArea > $maxArea ) ) {

					$dataMngr->_AddWarningResult(
												  "X-out",
												  "Z??kazn??k po??aduje panel bez X-outu a plocha panelu je v??t???? jak 2,2dm2 ($curArea dm2). "
													. "Ujisti se, jestli panel nen?? mo??n?? zmen??it, jinak bude slo??it?? takov?? panel vyrobit bez vadn??ch kus??"
					);

				}
			}

		}
	}

	# Check Flex / RigidFlex dimensions
	# Only one possible dimension of flex/rigidflex PCB is 305x458mm
	# Another dimension (bigger/smaller) is not possible
	if ( $defaultInfo->GetIsFlex() || scalar( grep { $_->{"gROWlayer_type"} eq "coverlay" } $defaultInfo->GetBoardBaseLayers() ) ) {

		my %dim = PanelDimension->GetDimensionPanel( $inCAM, EnumsProducPanel->SIZE_FLEX );

		my %lim = $defaultInfo->GetProfileLimits();
		my $w   = abs( $lim{"xMax"} - $lim{"xMin"} );
		my $h   = abs( $lim{"yMax"} - $lim{"yMin"} );

		if ( $dim{"PanelSizeX"} != $w || $dim{"PanelSizeY"} != $h ) {

			$dataMngr->_AddErrorResult(
										"??patn?? rozm??r p??????ezu",
										"Pokud je DPS typu Flex/RigidFlex nebo DPS obsahuje coverlay, p??????ez mus?? m??t rozm??ry p??esn??: "
										  . $dim{"PanelSizeX"} . "mm x "
										  . $dim{"PanelSizeY"} . "mm. "
										  . "Nelze vyrobit v??t????/men???? p??????ez z d??vodu p??izp??soben?? v??roby na tento jedinn?? rozm??r."
			);
		}
	}

}

# Extended control
# Based rather on PCB data
sub __CheckGroupDataExtend {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = $dataMngr->GetGroupData();
	my $inCAM     = $dataMngr->{"inCAM"};
	my $jobId     = $dataMngr->{"jobId"};
	my $stepName  = "panel";

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	# Check if stackup inner layer or job inner layer are both empty or both not epmty
	{
		if ( $defaultInfo->GetLayerCnt() > 2 ) {

			my $stckpCode = $defaultInfo->GetStackupCode();
			my $stackup   = $defaultInfo->GetStackup();

			my @inner = grep { $_->{"gROWname"} =~ /^v\d$/ } $defaultInfo->GetSignalLayers();

			foreach my $inL ( map { $_->{"gROWname"} } @inner ) {

				my $emptyInLayer = $stckpCode->GetIsLayerEmpty($inL);
				my $emptyInStckp = $stackup->GetCuLayer($inL)->GetUssage() > 0 ? 0 : 1;

				if ( $emptyInLayer != $emptyInStckp ) {

					$dataMngr->_AddErrorResult(
												"Pr??zdn?? vnit??n?? vrstvy",
												"U vnit??n?? sign??lov?? vrstvy: $inL nesed?? vyu??it?? Cu ve stackupu ("
												  . ( $stackup->GetCuLayer($inL)->GetUssage() * 100 )
												  . "%) s daty ve vrstv?? InCAM jobu (vrstva "
												  . ( $emptyInLayer ? "je" : "nen??" )
												  . " pr??zdn??). "
												  . "Pokud je vrstva v InCAM jobu pr??zdn?? (okol?? v panelu se nepo????t??), "
												  . "tak mus?? b??t vyu??it?? m??di ve stackupu nastaveno na 0% a naopak"
					);
				}

			}
		}
	}

	my @sig      = $defaultInfo->GetSignalLayers();
	my $layerCnt = $defaultInfo->GetLayerCnt();

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
											"Sign??lov?? vrstva: \""
											  . $l->{"gROWname"}
											  . "\" m?? ??patn?? nastaven?? atribut vrstvy: \"Layer side\" ("
											  . $layerAttr{'layer_side'}
											  . "). Ve stackupu je vstva veden?? jako: \"$side\". Uprav atribut a znovu vlo?? sch??ma do panelu!"
				);
			}
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
									  "Job obsahuje zlacen?? konektor, ale SR stepy jsou um??st??ny p????li?? bl??zko nebo a?? za aktivn?? oblast??. "
										. "Zkontroluj, jestli bude propojen?? konektor?? s plo??kou v technick??m okol?? dostate??n?? siln?? (2mm). "
										. "Pokud ne, zm??n pozici SR stepu."
			);

		}

	}

	# 13) Check if goldfinge exist or galvanic surface (G)  if panel equal to standard small dimension
	my $surface = $defaultInfo->GetPcbSurface($jobId);
	if ( $surface =~ /G/i || $goldFinger ) {

		my $cutPnl = $defaultInfo->GetJobAttrByName('technology_cut');

		if ( !defined $cutPnl || $cutPnl =~ /^no$/i ) {

			# height: small standard VV - 407, small standard VV - 355

			my %profLim = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );

			my $h = abs( $profLim{"yMax"} - $profLim{"yMin"} );

			if ( $h > 408 ) {

				$dataMngr->_AddErrorResult(
											"Panel dimension",
											"P????li?? velk?? panel. \nPokud job obsahuje zlacen?? konektor nebo povrch je galvanick?? zlato,"
											  . " panel mus?? m??t maxim??ln?? tak velk?? jako mal?? standardn?? panel."
				);
			}
		}

	}

	# Check if goldfinger doesn't exist, if is used wrong attribute ".gold_fineg" instead of ".gold_plating"

	if ( CamGoldArea->GoldFingersExist( $inCAM, $jobId, $stepName, undef, ".gold_finger" ) ) {

		$dataMngr->_AddErrorResult( "Gold finger",
									"Je pou??it ??patn?? atribut pro konektorov?? zlato: \".gold_finger\". Zmn???? atribut na \".gold_plating\"." );
	}

	# Check if goldfinger doesnt exist in job, but are checked in IS
	if ( $defaultInfo->GetPcbBaseInfo()->{"zlaceni"} =~ /^A$/i
		 && !CamGoldArea->GoldFingersExist( $inCAM, $jobId, $stepName, undef, ".gold_plating" ) )
	{

		$dataMngr->_AddErrorResult( "Gold connector",
									"V IS je po??adavek na zlacen??, ale v desce nebyl nalezen zlacen?? konektor (atribut .gold_plating )" );
	}

	# Check if goldfinger doesnt exist in job, but thera are layers goldc, golds
	if ( ( $defaultInfo->LayerExist("goldc") || $defaultInfo->LayerExist("golds") || $defaultInfo->LayerExist("fk") )
		 && !CamGoldArea->GoldFingersExist( $inCAM, $jobId, $stepName, undef, ".gold_plating" ) )
	{

		$dataMngr->_AddErrorResult( "Gold connector",
									"V matrixu je n??kter?? z vrstev: goldc;golds;fk, ale nebyl nalezen zlacen?? konektor (atribut .gold_plating )" );
	}

	# Check if all gold finger are connected, if gold finger exist
	if ($goldFinger) {

		my $mess = "";

		unless ( GoldFingersCheck->GoldFingersConnected( $inCAM, $jobId, \@goldFingerLayers, \$mess ) ) {

			$dataMngr->_AddErrorResult( "Wrong Gold finger connection", $mess );
		}
	}

	# X) Check if gold finger exist and base cu is => 70??m, peelable mask must be prepared in order cover goldfinger during
	# final surface operation
	if ( $goldFinger && $defaultInfo->GetBaseCuThick("c") >= 70 ) {

		my @peelMaskL = grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_lcMill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_lsMill }
		  $defaultInfo->GetNCLayers();

		unless ( scalar(@peelMaskL) ) {

			$dataMngr->_AddWarningResult(
										  "Chyb??j??c?? vrstvy sn??mac??ho laku",
										  "Pokud je na desce zlacen?? konektor a z??rove?? z??kladn?? Cu >= 70??m, "
											. "tak je t??eba nachystat fr??zovac?? vrstvy pro sn??mac?? lak"
			);

		}

	}

	# 19) Check attribu "custom_year" if contains current year plus 1 (only SICURIT customer, id: 07418)
	if ( $defaultInfo->GetCustomerISInfo()->{"reference_subjektu"} eq "07418" ) {
		my %allAttr = CamAttributes->GetJobAttr( $inCAM, $jobId );

		if ( defined $allAttr{"custom_year"} ) {
			my $d = ( DateTime->now( "time_zone" => 'Europe/Prague' )->year() + 1 ) % 100;

			if ( $d != $allAttr{"custom_year"} ) {

				$dataMngr->_AddErrorResult( "Attribut \"custom_year\"",
										 "Atribut: \"custom_year\" (" . $allAttr{"custom_year"} . ") nen?? aktu??ln??" . "M??l by m??t hodnotu: $d" );
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
										"V IS je po??adavek na zapln??n?? otovry, ale nejsou p??ipraven?? \"plgc\" a \"plgs\" vrstvy." );
		}
	}

	# 23) Check scaling settings if match scale of signal layer and NC layers
	# Reason - Signal layers can be registrated by plated drilling layers by cameras
	my @stretchCpls = ();
	if ( $layerCnt <= 2 ) {

		my @NCLayers =
		  grep { $_->{"plated"} }
		  grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_score } $defaultInfo->GetNCLayers();

		foreach my $NClInfo (@NCLayers) {
			my $topCu = $NClInfo->{"NCSigStart"};
			my $botCu = $NClInfo->{"NCSigEnd"};

			push( @stretchCpls, { "nc" => $NClInfo, "topCu" => $topCu, "botCu" => $botCu } );
		}
	}
	else {

		my @products = $defaultInfo->GetStackup()->GetAllProducts();

		foreach my $p (@products) {

			foreach my $NC ( grep { $_->{"plated"} } $p->GetNCLayers() ) {

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
											"Sign??lov?? vrstvy: "
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
											  . ") nemaj?? stejn?? parametry rozta??en?? motivu."
				);

			}

			# Top  Cu stretch must be equal to NC layer stretch
			if ( $SCuScale->{"stretchX"} != $NCLScale->{"stretchX"} || $SCuScale->{"stretchY"} != $NCLScale->{"stretchY"} ) {

				$dataMngr->_AddErrorResult(
											"Stretch settings signal/NC layers",
											"Sign??lov?? vrstva: "
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
											  . ") nemaj?? stejn?? parametry rozta??en?? motivu."
				);
			}

			# Top  Cu stretch must be equal to NC layer stretch
			if ( $ECuScale->{"stretchX"} != $NCLScale->{"stretchX"} || $ECuScale->{"stretchY"} != $NCLScale->{"stretchY"} ) {

				$dataMngr->_AddErrorResult(
											"Stretch settings signal/NC layers",
											"Sign??lov?? vrstva: "
											  . $ECuScale->{"name"}
											  . " (stretchX="
											  . $ECuScale->{"stretchX"}
											  . "; stretchY="
											  . $ECuScale->{"stretchY"}
											  . ") a NC vrstva: "
											  . $NCLScale->{"name"}
											  . " (stretchX="
											  . $NCLScale->{"stretchX"}
											  . "; stretchY="
											  . $NCLScale->{"stretchY"}
											  . ") nemaj?? stejn?? parametry rozta??en?? motivu."
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
											"Mpanel - v??pl??",
											"Pokud DPS obsauje stiffner, mpanel nesm?? obsahovat ze strany stiffeneru v sign??lov?? vrstv?? ("
											  . $sigL
											  . ") ??rafov??n??."
											  . " Rozpozn??no podle atributu: \".paaatern_fill\" ."
				);
			}
		}
	}

	# X) If one sided stiffener, it must be prepared in bottom
	{
		my @stiff = grep { $_->{"gROWlayer_type"} eq "stiffener" } $defaultInfo->GetBoardBaseLayers();
		if ( scalar(@stiff) == 1 ) {

			unless ( $stiff[0]->{"gROWname"} =~ /stiffs/ ) {
				$dataMngr->_AddErrorResult(
											"Stiffener ze ??patn?? strany",
											"Pokud DPS obsauje stiffener pouze z jedn?? strany, mus?? b??t stiffener p??ipraven na spodn?? stranu."
											  . " D??vodem je kvalita fr??zov??n?? po prokovu. Ozrcadli data + vrstvy v matrixu."
				);
			}
		}
	}

	# 16) If customer has required scheme, check if scheme in mpanel is ok
	# check if exist mpanel and check schema
	if ( $defaultInfo->StepExist("mpanel") ) {

		my $usedScheme = CamAttributes->GetStepAttrByName( $inCAM, $jobId, "mpanel", "cust_panelization_scheme" );
		
		if ( defined $usedScheme && $usedScheme ne "" ) {

			unless ( SchemeCheck->CustPanelSchemeOk( $inCAM, $jobId, $usedScheme, $defaultInfo->GetCustomerNote() ) ) {

				my @custSchemas = $defaultInfo->GetCustomerNote()->RequiredSchemas();
				my $custTxt = join( "; ", @custSchemas );

				$dataMngr->_AddWarningResult( "Customer schema",
							  "Z??kazn??k po??aduje ve stepu: \"mpanel\" vlastn?? sch??ma: \"$custTxt\", ale je vlo??eno sch??ma: \"$usedScheme\"." );
			}
		}
	}

	# X) Check production panel schema
	{
		my $usedPnlScheme = CamAttributes->GetStepAttrByName( $inCAM, $jobId, "panel", ".pnl_scheme" );
		die "Schema name is not defined in step: panel; attribute: pnl_schema" if ( !defined $usedPnlScheme || $usedPnlScheme eq "" );
		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );

		my $pnlHeight = abs( $lim{"yMax"} - $lim{"yMin"} );

		my $errMess = "";
		unless ( SchemeCheck->ProducPanelSchemeOk( $inCAM, $jobId, $usedPnlScheme, $pnlHeight, \$errMess ) ) {

			$dataMngr->_AddErrorResult(
				"??patn?? sch??ma",
				"Ve stepu panel vlo??en?? ??patn?? sch??ma: $usedPnlScheme (attribut: .pnl_scheme v atributech stepu)"
				  . " Vlo?? do panelu spr??vn?? sch??ma."
				  . ( $errMess ne "" ? "Detail chyby:\n$errMess" : "" )

			);

		}
	}

	# 10) Check if dimension of panel are ok, depand on finish surface

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
										"Nelze pou????t velk?? rozm??r panelu ("
										  . $h
										  . "mm) proto??e surface je olovnat?? HAL a z??rove?? tl. desky je men???? 1,5mm. Max v????ka panelu je: $maxThinHALPB mm"
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
										"Nelze pou????t velk?? rozm??r panelu ("
										  . $pnl->HFr()
										  . "mm) proto??e surface je olovnat?? HAL a z??rove?? tl. desky je men???? 1,5mm. Max v????ka panelu (fr r??me??ku) je: $maxThinHALPB mm"
			);
		}
	}



	# If panel will be cut during production, check if there is proper set active area
	if ( $cutPnl !~ /^no$/i ) {

		my $pnl = StandardBase->new( $inCAM, $jobId );
		if ( $pnl->HArea() > 470 ) {
			$dataMngr->_AddErrorResult(
				"V????ka aktivn?? plochy panelu",
				"V????ka aktivn?? plochy neodpov??d?? st??ihu. Zkontroluj, jestli kusy nejsou panelizovan?? za hranic?? st??ihu panelu."

			);
		}
	}

	# Grafit panelise to smaller panel due to screenprinting problems
	{
		my @grafitL = grep { $_->{"gROWname"} =~ /^g[cs]$/i } $defaultInfo->GetBoardBaseLayers();

		if ( scalar(@grafitL) ) {
			my %limActive = CamStep->GetActiveAreaLim( $inCAM, $jobId, "panel" );

			my $h = abs( $limActive{"yMax"} - $limActive{"yMin"} );

			my $maxPnlH = 400;    # 400mm
			if ( $h > $maxPnlH ) {

				$dataMngr->_AddErrorResult(
											"Panel dimension",
											"P????li?? velk?? aktivn?? oblast (${h}mm).  Pokud job obsahuje grafit aktivn?? oblast"
											  . " mus?? m??t vysok?? maxim??ln?? ${maxPnlH}mm."
											  . " D??vodem jsou probl??my se s??totiskov??m stolem a dlouh??mi p??????ezy"
				);
			}
		}
	}

	# If there are impedance coupons, check if there are place in the middle of PCB
	if ( $defaultInfo->StepExist( EnumsGeneral->Coupon_IMPEDANCE ) ) {

		my @repeats = grep { $_->{"stepName"} eq EnumsGeneral->Coupon_IMPEDANCE } CamStepRepeat->GetRepeatStep( $inCAM, $jobId, "panel" );

		my %lim = $defaultInfo->GetProfileLimits();

		# Check center area of panel (area of 50% width/height of panel)

		my $w = $lim{"xMax"} - $lim{"xMin"};
		my $h = $lim{"yMax"} - $lim{"yMin"};

		my %centerArea = ();

		$centerArea{"xMin"} = $lim{"xMin"} + $w / 4;
		$centerArea{"xMax"} = $lim{"xMax"} - $w / 4;
		$centerArea{"yMin"} = $lim{"yMin"} + $h / 4;
		$centerArea{"yMax"} = $lim{"yMax"} - $h / 4;

		my $inMiddle = 0;
		foreach my $step (@repeats) {

			my $xMidCpn = $step->{"gREPEATxmin"} + ( $step->{"gREPEATxmax"} - $step->{"gREPEATxmin"} ) / 2;
			my $yMidCpn = $step->{"gREPEATymin"} + ( $step->{"gREPEATymax"} - $step->{"gREPEATymin"} ) / 2;

			if (    $xMidCpn > $centerArea{"xMin"}
				 && $xMidCpn < $centerArea{"xMax"}
				 && $yMidCpn > $centerArea{"yMin"}
				 && $yMidCpn < $centerArea{"yMax"} )
			{

				$inMiddle = 1;
				last;
			}
		}

		unless ($inMiddle) {

			$dataMngr->_AddWarningResult(
				"Impedan??n?? kupon",
				"Na p??????ezu jsou impedan??n?? kupony, ale ani jeden nen?? uprost??ed p??????ezu "
				  . "(ide??ln?? um??st??j?? kupon?? je m??t alespo?? jeden uprost??ed z d??vodu nerovnom??rn??ho nakoven??)"

			);
		}

	}

	# X) Check if there is always frame pattern fill in Cu when 1-2v flex and customer panel
	{
		if ( $defaultInfo->GetIsFlex() && $defaultInfo->GetLayerCnt() <= 2 ) {

			my %dim = JobDim->GetDimension( $inCAM, $jobId );

			if ( $dim{"nasobnost_panelu"} > 0 ) {

				my @sr = CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

				# Get panel step (not always mpanel, it can be also o+1 as customer panel)
				foreach my $sigL ( $defaultInfo->GetSignalLayers() ) {

					my $sigName = $sigL->{"gROWname"};

					# If esist soldermask and not stiffener, check pattern fill in frame
					my $stiff = first { $_->{"gROWlayer_type"} eq "stiffener" && $_->{"gROWname"} =~ /$sigName/ } $defaultInfo->GetBoardBaseLayers();
					my $mask = first { $_->{"gROWlayer_type"} eq "solder_mask" && $_->{"gROWname"} =~ /$sigName/ } $defaultInfo->GetBoardBaseLayers();

					if ( defined $mask && !defined $stiff ) {

						foreach my $s (@sr) {

							my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $s->{"stepName"}, $sigName, 0 );
							if ( !defined $attHist{".pattern_fill"} ) {

								$dataMngr->_AddErrorResult(
									 "V??pl?? okol?? ze strany $sigName",
									 "Pokud DPS neobsahuje stiffner a z??rove?? obsahuje flex masku, "
									   . "je nutn??, aby okol?? panelu bylo vypln??no Cu (??rafov??n??m atd) a to i v p????pad?? panelu z??kazn??ka, "
									   . "jinak je p??i s??totisku v okol?? nanesen?? tlust?? vrstva masky"
									   . " Chyb??j??c?? v??pl?? je rozpozn??na podle nedohledan??ho atributu: \".patern_fill\" ."
								);
							}
						}
					}

				}

			}
		}
	}

	# X) Check stackup usage if match with real usage
	{
		if ( $defaultInfo->GetLayerCnt() > 2 ) {

			my @innerCuUsage = ();
			unless ( StackupCheck->CuUsageCheck( $inCAM, $jobId, \@innerCuUsage ) ) {

				my @errUsage = grep {
					   $_->{"status"} eq Packages::CAMJob::Stackup::StackupCheck::USAGE_DECREASE
				} @innerCuUsage;

				my $txt = "";

				foreach my $l (@errUsage) {

					$txt .=
					    "\nVrstva: "
					  . $l->{"layer"}
					  . ", Re??ln?? vyu??it??: "
					  . sprintf( "%4s%%", int( $l->{"realUsage"} ) )
					  . " vs Skute??n?? vyu??it??:"
					  . sprintf( "%4s%%", int( $l->{"stackupUsage"} ) );
				}

				$dataMngr->_AddWarningResult(
												  "Vu??it?? Cu ve slo??en??",
												  "Vyu??it?? Cu ve slo??en?? nen?? v toleranci: "
													. Packages::CAMJob::Stackup::StackupCheck::USAGETOL
													. "% (je men????) s re??ln??m vyu??it??m u n??sleduj??c??ch vrstev:\n$txt. Zkontroluj mno??stv?? prysky??ice pop??. oprav slo??en??"
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

