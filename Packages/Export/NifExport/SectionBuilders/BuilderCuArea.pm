
#-------------------------------------------------------------------------------------------#
# Description: Build section with computation of gold, cu srurface etc
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderCuArea;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;
use List::Util qw[max min];

#local library
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Enums::EnumsIS';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';
use aliased 'Packages::TifFile::TifLayers';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {

	my $self    = shift;
	my $section = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my %nifData  = %{ $self->{"nifData"} };
	my $stepName = "panel";

	my $cuThickness = JobHelper->GetBaseCuThick( $jobId, "c" );
	my $pcbThick      = CamJob->GetFinalPcbThick( $inCAM, $jobId );
	my $surface       = HegMethods->GetPcbSurface($jobId);
	my $pcbClass      = CamJob->GetJobPcbClass( $inCAM, $jobId );
	my $pcbClassInner = CamJob->GetJobPcbClassInner( $inCAM, $jobId );
	my $tif           = TifLayers->new($jobId);

	my $stackup;
	my $stackupNC;
	my $coreCnt;
	my $pressCnt;

	if ( $self->{"layerCnt"} > 2 ) {
		$stackup = Stackup->new( $inCAM, $jobId );
		$stackupNC = StackupNC->new( $inCAM, $jobId );
		$coreCnt   = $stackupNC->GetCoreCnt();
		$pressCnt  = $stackupNC->GetPressCount();
	}

	my $pltMillExist;
	my $rsMillExist;
	my $blindDrillExist;

	my %frLim;
	if ( CamHelper->LayerExists( $inCAM, $jobId, "fr" ) ) {

		%frLim = CamJob->GetLayerLimits( $inCAM, $jobId, "panel", "fr" );    #limits of fr rout
	}

	my $imerseSurf = 0;

	if ( $self->_IsRequire("g_plocha_c") && $self->_IsRequire("g_plocha_s") ) {

		# comment
		$section->AddComment("Plocha Cu pattern, pouze s vrtanim");
	}

	#g_plocha_c
	if ( $self->_IsRequire("g_plocha_c") ) {

		my %result = ();

		if ( $self->{"layerCnt"} > 2 ) {

			%result = CamCopperArea->GetCuAreaByBox( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", "c", undef, \%frLim, undef, 1 );
		}
		else {
			%result = CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", "c", undef, undef, 1 );
		}

		$section->AddRow( "g_plocha_c", $result{"area"} );
	}

	#g_plocha_s
	if ( $self->_IsRequire("g_plocha_s") ) {

		my %result = ();

		if ( $self->{"layerCnt"} > 2 ) {

			%result = CamCopperArea->GetCuAreaByBox( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", undef, "s", \%frLim, undef, 1 );
		}
		else {
			%result = CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", undef, "s", undef, 1 );
		}

		$section->AddRow( "g_plocha_s", $result{"area"} );

	}

	if ( $self->_IsRequire("gold_c") && $self->_IsRequire("gold_s") ) {

		# comment
		$section->AddComment("Plocha Cu odmaskovane dps [cm2]");
	}

	#gold_c
	if ( $self->_IsRequire("gold_c") ) {

		my %result = ();
		my $val    = 0;

		if ( $surface =~ /^i$/i ) {

			my $mcExist = CamHelper->LayerExists( $inCAM, $jobId, "mc" );

			# if mask exist return area not covered by mask
			if ($mcExist) {
				if ( $self->{"layerCnt"} > 2 ) {

					%result =
					  CamCopperArea->GetCuAreaMaskByBox( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", "c", undef, ["mc"], undef, \%frLim );

				}
				else {

					%result = CamCopperArea->GetCuAreaMask( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", "c", undef, ["mc"] );
				}
			}

			# if mask not exist return are of whole surface
			else {

				if ( $self->{"layerCnt"} > 2 ) {

					%result = CamCopperArea->GetCuAreaByBox( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", "c", undef, \%frLim, undef, 1 );
				}
				else {
					%result = CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", "c", undef, undef, 1 );
				}
			}

			$val = $result{"area"};
		}

		$imerseSurf += $val;
		$section->AddRow( "gold_c", $val );
	}

	#gold_s
	if ( $self->_IsRequire("gold_s") ) {
		my %result = ();
		my $val    = 0;

		if ( $surface =~ /^i$/i ) {

			my $msExist = CamHelper->LayerExists( $inCAM, $jobId, "ms" );

			# if mask exist return area not covered by mask
			if ($msExist) {
				if ( $self->{"layerCnt"} > 2 ) {

					%result =
					  CamCopperArea->GetCuAreaMaskByBox( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", undef, "s", undef, ["ms"], \%frLim );

				}
				else {

					%result = CamCopperArea->GetCuAreaMask( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", undef, "s", undef, ["ms"] );
				}
			}

			# if mask not exist return are of whole surface
			else {

				if ( $self->{"layerCnt"} > 2 ) {

					%result = CamCopperArea->GetCuAreaByBox( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", undef, "s", \%frLim, undef, 1 );
				}
				else {
					%result = CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", undef, "s", undef, 1 );
				}
			}

			$val = $result{"area"};
		}

		$imerseSurf += $val;
		$section->AddRow( "gold_s", $val );
	}

	#imersni_plocha
	if ( $self->_IsRequire("imersni_plocha") ) {

		# comment
		$section->AddComment("Plocha Cu odmaskovane dps (top+bot)");

		$section->AddRow( "imersni_plocha", $imerseSurf );
	}

	#zlacena_plocha
	if ( $self->_IsRequire("zlacena_plocha") ) {

		my %result = CamGoldArea->GetGoldFingerArea( $cuThickness, $pcbThick, $inCAM, $jobId, "panel" );

		my $area = 0;

		if ( $result{"exist"} ) {
			$area = $result{"area"};
		}

		# comment
		$section->AddComment("Plocha Cu (top+bot) pro zlaceny konektor");

		$section->AddRow( "zlacena_plocha", $area );
	}

	# comment
	if ( $self->_IsRequire("plg_plocha") || $self->_IsRequire("plg_plocha") ) {

		$section->AddComment("Plocha Cu plosek zaplnovanych otvoru");
	}

	#plg_plocha_c
	if ( $self->_IsRequire("plg_plocha") ) {

		foreach my $layer ( map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "via_plug" } CamJob->GetBoardBaseLayers( $inCAM, $jobId ) ) {

			my %result = ();

			if ( $self->{"layerCnt"} > 2 && $layer !~ /v\d+/ ) {

				%result = CamCopperArea->GetCuAreaByBox( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", $layer, undef, \%frLim, 1, 1 );
			}
			else {
				%result = CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", $layer, undef, 1, 1 );
			}

			my $sigL = ( $layer =~ m/plg(.*)/ )[0];

			$section->AddRow( "plg_plocha_$sigL", $result{"area"} );
		}
	}
	#
	#		if ( CamHelper->LayerExists( $inCAM, $jobId, "plgc" ) ) {
	#
	#			my %result = ();
	#
	#			if ( $self->{"layerCnt"} > 2 ) {
	#
	#				%result = CamCopperArea->GetCuAreaByBox( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", "plgc", undef, \%frLim, 1, 1 );
	#			}
	#			else {
	#				%result = CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", "plgc", undef, 1, 1 );
	#			}
	#
	#			$section->AddRow( "plg_plocha_c", $result{"area"} );
	#		}

	#	#plg_plocha_s
	#	if ( $self->_IsRequire("plg_plocha") ) {
	#
	#		if ( CamHelper->LayerExists( $inCAM, $jobId, "plgs" ) ) {
	#
	#			my %result = ();
	#
	#			if ( $self->{"layerCnt"} > 2 ) {
	#
	#				%result = CamCopperArea->GetCuAreaByBox( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", undef, "plgs", \%frLim, 1, 1 );
	#			}
	#			else {
	#				%result = CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", undef, "plgs", 1, 1 );
	#			}
	#
	#			$section->AddRow( "plg_plocha_s", $result{"area"} );
	#		}
	#	}

	# Cu area (if blind holes) during pressing
	if ( $self->{"layerCnt"} > 2 && $pressCnt > 0 ) {

		# comment
		$section->AddComment(" Plocha Cu pouze s vrtanim, slepe otvory ");

		for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

			my $pressOrder = $i + 1;
			my $press      = $stackupNC->GetNCPressProduct($pressOrder);

			my $existTopPlt_nDrill     = $press->ExistNCLayers( Enums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_nDrill );
			my $existTopPlt_nFillDrill = $press->ExistNCLayers( Enums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_nFillDrill );
			my $existPlt_bDrillTop     = $press->ExistNCLayers( Enums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_bDrillTop );

			my $existBotPlt_nDrill     = $press->ExistNCLayers( Enums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_nDrill );
			my $existBotPlt_nFillDrill = $press->ExistNCLayers( Enums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_nFillDrill );
			my $existPlt_bDrillBot     = $press->ExistNCLayers( Enums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_bDrillBot );

			if (    $existTopPlt_nDrill
				 || $existTopPlt_nFillDrill
				 || $existPlt_bDrillTop
				 || $existBotPlt_nDrill
				 || $existBotPlt_nFillDrill
				 || $existPlt_bDrillBot )
			{

				my $actualThick = $stackup->GetThickByCuLayer( $press->GetTopCopperLayer() );        #in µm
				my $baseCuThick = $stackup->GetCuLayer( $press->GetTopCopperLayer() )->GetThick();

				my %resultTop;
				my %resultBot;

				if ( $pressOrder == $stackupNC->GetPressCount() ) {
					%resultTop = CamCopperArea->GetCuAreaByBox( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", $press->GetTopCopperLayer(),
																, undef, \%frLim, undef, 1 );
					%resultBot =
					  CamCopperArea->GetCuAreaByBox( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", undef, $press->GetBotCopperLayer(),
													 , \%frLim, undef, 1 );
				}
				else {
					%resultTop =
					  CamCopperArea->GetCuArea( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", $press->GetTopCopperLayer(), undef, undef, 1 );
					%resultBot =
					  CamCopperArea->GetCuArea( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", undef, $press->GetBotCopperLayer(), undef, 1 );
				}

				$section->AddRow( "g_plocha_c_vv_" . $pressOrder, $resultTop{"area"} );
				$section->AddRow( "g_plocha_s_vv_" . $pressOrder, $resultBot{"area"} );
			}

		}
	}

	if ( $self->{"layerCnt"} > 2 && $coreCnt > 0 ) {

		#TODO nakoveni jadra  - hodnota C doimplementovat

		# comment
		$section->AddComment(" Plocha Cu jader, pouze s vrtanim ");

		for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {

			my $coreNum = $i + 1;
			my $core    = $stackupNC->GetNCCoreProduct($coreNum);

			my $existDrillTop = $core->ExistNCLayers( Enums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_cDrill );
			my $existDrillBot = $core->ExistNCLayers( Enums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_cDrill );

			if ( $existDrillTop || $existDrillBot ) {

				my $actualThick = $stackup->GetThickByCuLayer( $core->GetTopCopperLayer() );        #in µm
				my $baseCuThick = $stackup->GetCuLayer( $core->GetTopCopperLayer() )->GetThick();

				my %resultTop =
				  CamCopperArea->GetCuArea( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", $core->GetTopCopperLayer(), undef, undef, 1 );
				my %resultBot =
				  CamCopperArea->GetCuArea( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", undef, $core->GetTopCopperLayer(), undef, 1 );

				$section->AddRow( "g_plocha_c_" . $coreNum, $resultTop{"area"} );
				$section->AddRow( "g_plocha_s_" . $coreNum, $resultBot{"area"} );

			}

		}
	}

	# comment
	$section->AddComment("Nastaveni programu ve vyrobe");

	#pocet_ponoru
	if ( $self->_IsRequire("pocet_ponoru") ) {
		$section->AddRow( "pocet_ponoru", 1 );
	}

	#load data

	if ( $self->_IsRequire("pattern") || $self->_IsRequire("flash") ) {

		$pltMillExist = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill );
		$rsMillExist  = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_rsMill );
		my $blindTopExist = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_bDrillTop );
		my $blindBotExist = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_bDrillBot );
		$blindDrillExist = ( $blindTopExist || $blindBotExist ) ? 1 : 0;

	}

	#flash
	if ( $self->_IsRequire("flash") ) {
		my $progFlash = $self->__GetFlashProgram( $rsMillExist, $blindDrillExist, $pcbClass );

		$section->AddRow( "flash", $progFlash );

		if ( $progFlash == 1 ) {

			# comment
			$section->AddComment(" Additional TP operation data");

			if ( $self->{"layerCnt"} > 2 && $pressCnt > 0 ) {

				for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

					my $pressOrder = $i + 1;
					my $pressNC    = $stackupNC->GetNCPressProduct($pressOrder);

					my $plating = $pressNC->GetIProduct()->GetIsPlated();

					if ($plating) {

						# Get information from tiffile

						my $opId = EnumsIS->OpId_chemicka_med . "_${pressOrder}";

						$section->AddRow( "operation.0.${opId}.program", "Chemicka med + Flash " );

					}
				}
			}
			elsif ( $self->{"layerCnt"} <= 2 ) {

				my $opId = EnumsIS->OpId_chemicka_med;
				$section->AddRow( "operation.0.${opId}.program", "Chemicka med + Flash " );
			}

			$section->AddRow( "operation.0." . EnumsIS->OpId_chemicka_med_pred_zaplnenim . ".program", "Chemicka med + Flash " );
			$section->AddRow( "operation.0." . EnumsIS->OpId_chemicka_med_dovrt_otvory . ".program",   "Chemicka med + Flash " );
		}
	}

	#pattern
	if ( $self->_IsRequire("pattern") ) {

		my $prog = $self->__GetPatternProgram( $rsMillExist, $blindDrillExist, $pcbClass );

		$section->AddRow( "pattern", $prog );
	}

	#prog_tenting - Valeu placed on info box
	if ( $self->_IsRequire("prog_tenting") ) {

		my ( $minHole, $minAr ) = $self->__GetInfoDrill( $stepName, [ EnumsGeneral->LAYERTYPE_plt_nDrill ] );

		my $prog = $self->__GetTentingProgram( $minHole, $minAr );

		$section->AddRow( "prog_tenting", $prog );

	}

	# Additional operation info for cores - galvanicke_medeni_tenting ||  galvanike_medeni_a_cinovani
	if ( $self->_IsRequire("prog_tenting") || $self->_IsRequire("pattern") ) {
		if ( $self->{"layerCnt"} > 2 && $pressCnt > 0 ) {

			my %sigLayers = $tif->GetSignalLayers();

			# comment
			$section->AddComment(" Additional TP operation data for core TP");

			for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {

				my $coreNum = $i + 1;

				my $coreNC = $stackupNC->GetNCCoreProduct($coreNum);

				my $corePlating = $coreNC->GetIProduct()->GetIsPlated();

				if ($corePlating) {

					# Decide between patter/flash

					my $lSett = $sigLayers{ $coreNC->GetTopCopperLayer() };

					die "Etching type is not defined in TIF for layer:" if ( !defined $lSett || !defined $lSett->{"etchingType"} );

					# Get information from tiffile

					if ( $lSett->{"etchingType"} eq EnumsGeneral->Etching_TENTING ) {

						my $platingType = EnumsIS->OpId_galvanicke_medeni_tenting;

						# Return minimal hole for given side and type of NC layers
						my $minHole = $coreNC->GetMinHoleTool( undef, undef, undef, 1 );
						my $minAr = $coreNC->GetMaxAspectRatio( undef, undef, undef, 1 );
						$section->AddRow( "operation.${coreNum}.${platingType}.program",
										  "Tenting " . $self->__GetTentingProgram( $minHole, $minAr ) );

					}
					elsif ( $lSett->{"etchingType"} eq EnumsGeneral->Etching_PATTERN ) {

						my $platingType = EnumsIS->OpId_galvanike_medeni_a_cinovani;
						$section->AddRow( "operation.${coreNum}.${platingType}.program",
										  "Pattern " . $self->__GetPatternProgram( 0, 0, $pcbClassInner ) );
					}

				}
			}
		}
	}

	# Additional operation info for main TP - galvanicke_medeni_tenting_<\d> ||  galvanike_medeni_a_cinovani_<\d>
	if ( $self->_IsRequire("prog_tenting") || $self->_IsRequire("pattern") ) {
		if ( $self->{"layerCnt"} > 2 && $pressCnt > 0 ) {

			my %sigLayers = $tif->GetSignalLayers();

			# comment
			$section->AddComment(" Additional TP operation data for main TP");
			for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

				my $pressOrder = $i + 1;
				my $pressNC    = $stackupNC->GetNCPressProduct($pressOrder);

				my $plating = $pressNC->GetIProduct()->GetIsPlated();

				if ($plating) {

					# Decide between patter/flash

					my $lSett = $sigLayers{ $pressNC->GetTopCopperLayer() };

					die "Etching type is not defined in TIF for layer:" if ( !defined $lSett || !defined $lSett->{"etchingType"} );

					# Get information from tiffile

					if ( $lSett->{"etchingType"} eq EnumsGeneral->Etching_TENTING ) {

						my $platingType = EnumsIS->OpId_galvanicke_medeni_tenting . "_${pressOrder}";

						# Return minimal hole for given side and type of NC layers
						my $minHole = $pressNC->GetMinHoleTool( undef, undef, undef, 1 );
						my $minAr = $pressNC->GetMaxAspectRatio( undef, undef, undef, 1 );
						$section->AddRow( "operation.0.${platingType}.program", "Tenting " . $self->__GetTentingProgram( $minHole, $minAr ) );

					}
					elsif ( $lSett->{"etchingType"} eq EnumsGeneral->Etching_PATTERN ) {

						my $platingType = EnumsIS->OpId_galvanike_medeni_a_cinovani . "_${pressOrder}";

						my $rsMillExist = $pressNC->ExistNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_nplt_rsMill, 1 );

						my @bDrillTop     = $pressNC->GetNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_bDrillTop,     1 );
						my @bDrillBot     = $pressNC->GetNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_bDrillBot,     1 );
						my @bFillDrillTop = $pressNC->GetNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop, 1 );
						my @bFillDrillBot = $pressNC->GetNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot, 1 );
						my $blindDrillExist =
						  scalar(@bDrillTop) + scalar(@bDrillBot) + scalar(@bFillDrillTop) + scalar(@bFillDrillBot) ? 1 : 0;
						my $pcbClass = $pressOrder < $pressCnt ? $pcbClassInner : $pcbClass;

						$section->AddRow( "operation.0.${platingType}.program",
										  "Pattern " . $self->__GetPatternProgram( $rsMillExist, $blindDrillExist, $pcbClass ) );
					}
				}
			}
		}
	}

	# Additional operation info for main TP - galvanicke_medeni_tenting ||  galvanike_medeni_a_cinovani
	if ( $self->_IsRequire("prog_tenting") || $self->_IsRequire("pattern") ) {
		if ( $self->{"layerCnt"} <= 2 ) {

			my %sigLayers = $tif->GetSignalLayers();

			# comment
			$section->AddComment(" Additional TP operation data for main TP 2v");

			# Decide between patter/flash

			my $lSett = $sigLayers{"c"};

			die "Etching type is not defined in TIF for layer: c" if ( !defined $lSett || !defined $lSett->{"etchingType"} );

			# Get information from tiffile

			if ( $lSett->{"etchingType"} eq EnumsGeneral->Etching_TENTING ) {

				my $platingType = EnumsIS->OpId_galvanicke_medeni_tenting;

				# Return minimal hole for given side and type of NC layers
				my ( $minHole, $minAr ) = $self->__GetInfoDrill( $stepName, [ EnumsGeneral->LAYERTYPE_plt_nDrill ] );
				$section->AddRow( "operation.0.${platingType}.program", "Tenting " . $self->__GetTentingProgram( $minHole, $minAr ) );

			}
			elsif ( $lSett->{"etchingType"} eq EnumsGeneral->Etching_PATTERN ) {

				my $platingType = EnumsIS->OpId_galvanike_medeni_a_cinovani;
				my $rsMillExist = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_rsMill );

				$section->AddRow( "operation.0.${platingType}.program", "Pattern " . $self->__GetPatternProgram( $rsMillExist, 0, $pcbClass ) );
			}
		}
	}

	#}

}

sub __GetInfoDrill {
	my $self     = shift;
	my $stepName = shift;
	my $lTypes   = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $pcbThick = CamJob->GetFinalPcbThick( $inCAM, $jobId );

	my @holeTypes = ();    # all holes type of layers

	my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, $lTypes );

	for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

		my $lName = $layers[$i]->{"gROWname"};

		#nuber of hole types
		$inCAM->INFO(
					  units       => 'mm',
					  entity_type => 'layer',
					  entity_path => "$jobId/$stepName/$lName",
					  data_type   => 'TOOL',
					  options     => "break_sr"
		);
		my @drillSizes = @{ $inCAM->{doinfo}{gTOOLdrill_size} };

		foreach my $t (@drillSizes) {
			unless ( scalar( grep { $_ == $t } @holeTypes ) ) {
				push( @holeTypes, $t );
			}
		}

	}

	#sort ASC
	@holeTypes = sort { $a <=> $b } @holeTypes;

	#min aspect ratio
	my $aspectRatio = "";
	if ( scalar(@holeTypes) ) {

		$aspectRatio = sprintf "%0.2f", ( $pcbThick / $holeTypes[0] );
	}

	return ( min(@holeTypes), $aspectRatio );
}

# Return Tenting program based on miniial hole diameter and minimal hole aspect ratio
sub __GetTentingProgram {
	my $self      = shift;
	my $minHole   = shift;
	my $minHoleAR = shift;

	my $prog = undef;

	# If min hole < 150µm OR Aspect ratio > 9 => tenting 2
	if ( $minHole <= 150 || $minHoleAR > 9 ) {

		$prog = 2;
	}
	else {

		$prog = 3;
	}

	return $prog;
}

sub __GetPatternProgram {
	my $self            = shift;
	my $rsMillExist     = shift;
	my $blindDrillExist = shift;
	my $pcbClass        = shift;

	my $prog = undef;
	if ( !$rsMillExist && !$blindDrillExist && $pcbClass < 9 ) {

		$prog = 1;
	}
	else {

		$prog = 3;
	}

	return $prog;
}

sub __GetFlashProgram {
	my $self            = shift;
	my $rsMillExist     = shift;
	my $blindDrillExist = shift;
	my $pcbClass        = shift;

	my $prog = undef;
	if ( !$rsMillExist && !$blindDrillExist && $pcbClass < 9 ) {

		$prog = 0;
	}
	else {

		$prog = 1;
	}

	return $prog;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

