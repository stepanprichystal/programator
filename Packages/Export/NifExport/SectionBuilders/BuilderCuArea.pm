
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

#local library
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';

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
	my $pcbThick    = JobHelper->GetFinalPcbThick($jobId);
	my $surface     = HegMethods->GetPcbSurface($jobId);
	my $pcbClass    = CamJob->GetJobPcbClass( $inCAM, $jobId );

	my $stackup;
	my $stackupNC;
	my $coreCnt;
	my $pressCnt;
 

	if ( $self->{"layerCnt"} > 2 ) {
		$stackup   = Stackup->new($jobId);
		$stackupNC = StackupNC->new( $inCAM, $stackup );
		$coreCnt   = $stackupNC->GetCoreCnt();
		$pressCnt  = $stackupNC->GetPressCnt();
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
		$section->AddComment("Plocha Cu odmaskovane dps");
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

					%result = CamCopperArea->GetCuAreaMaskByBox( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", "c", undef, "mc", undef, \%frLim );

				}
				else {

					%result = CamCopperArea->GetCuAreaMask( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", "c", undef, "mc" );
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

					%result = CamCopperArea->GetCuAreaMaskByBox( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", undef, "s", undef, "ms", \%frLim );

				}
				else {

					%result = CamCopperArea->GetCuAreaMask( $cuThickness, $pcbThick, $inCAM, $jobId, "panel", undef, "s", undef, "ms" );
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

		my %result = CamCopperArea->GetGoldFingerArea( $cuThickness, $pcbThick, $inCAM, $jobId, "panel" );

		my $area = 0;

		if ( $result{"exist"} ) {
			$area = $result{"area"};
		}

		# comment
		$section->AddComment("Plocha Cu (top+bot) pro zlaceny konektor");

		$section->AddRow( "zlacena_plocha", $area );
	}



	# Cu area (if blind holes) during pressing
	if ( $self->{"layerCnt"} > 2 && $pressCnt > 0 ) {

		# comment
		$section->AddComment(" Plocha Cu pouze s vrtanim, slepe otvory ");

		for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

			my $pressOrder = $i + 1;
			my $press      = $stackupNC->GetPress($pressOrder);

			my $stackupNCTopL = $press->GetTopSigLayer();
			my $stackupNCBotL = $press->GetBotSigLayer();

			my $existTopPlt_nDrill = $press->ExistNCLayers( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_nDrill );
			my $existPlt_bDrillTop = $press->ExistNCLayers( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_bDrillTop );

			my $existBotPlt_nDrill = $press->ExistNCLayers( Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_nDrill );
			my $existPlt_bDrillBot = $press->ExistNCLayers( Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_bDrillBot );

			if ( $existTopPlt_nDrill || $existPlt_bDrillTop || $existBotPlt_nDrill || $existPlt_bDrillBot ) {

				my $actualThick = $stackup->GetThickByLayerName( $stackupNCTopL->GetName() ) * 1000;    #in µm
				my $baseCuThick = $stackup->GetCuLayer( $stackupNCTopL->GetName() )->GetThick();

				my %resultTop;
				my %resultBot;

				if ( $pressOrder == $stackupNC->GetPressCnt() ) {
					%resultTop = CamCopperArea->GetCuAreaByBox( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", $stackupNCTopL->GetName(),
																, undef, \%frLim, undef, 1 );
					%resultBot = CamCopperArea->GetCuAreaByBox( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", undef, $stackupNCBotL->GetName(),
																, \%frLim, undef, 1 );
				}
				else {
					%resultTop =
					  CamCopperArea->GetCuArea( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", $stackupNCTopL->GetName(), undef, undef, 1 );
					%resultBot =
					  CamCopperArea->GetCuArea( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", undef, $stackupNCBotL->GetName(), undef, 1 );
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
			my $core    = $stackupNC->GetCore($coreNum);

			my $existDrillTop = $core->ExistNCLayers( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_cDrill );
			my $existDrillBot = $core->ExistNCLayers( Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_cDrill );

			if ( $existDrillTop || $existDrillBot ) {

				my $stackupNCTopL = $core->GetTopSigLayer();
				my $stackupNCBotL = $core->GetBotSigLayer();

				my $actualThick = $stackup->GetThickByLayerName( $stackupNCTopL->GetName() ) * 1000;    #in µm
				my $baseCuThick = $stackup->GetCuLayer( $stackupNCTopL->GetName() )->GetThick();

				my %resultTop =
				  CamCopperArea->GetCuArea( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", $stackupNCTopL->GetName(), undef, undef, 1 );
				my %resultBot =
				  CamCopperArea->GetCuArea( $baseCuThick, $actualThick, $inCAM, $jobId, "panel", undef, $stackupNCBotL->GetName(), undef, 1 );

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

	#pattern
	if ( $self->_IsRequire("pattern") ) {

		my $prog;

		if ( !$pltMillExist && $surface !~ /^b$/i && !$rsMillExist && !$blindDrillExist ) {

			$prog = 1;
		}
		else {
			$prog = 3;
		}

		$section->AddRow( "pattern", $prog );
	}

	#flash
	if ( $self->_IsRequire("flash") ) {

		my $prog;

		if ( !$pltMillExist && $surface !~ /^b$/i && !$rsMillExist && !$blindDrillExist ) {

			$prog = 0;
		}
		else {
			$prog = 1;
		}

		$section->AddRow( "flash", $prog );
	}

	#prog_tenting
	if ( $self->_IsRequire("prog_tenting") ) {

		my $prog;

		if ( $pcbClass >= 8 ) {
			$prog = 2;
		}
		else {

			$prog = 3;
		}

		$section->AddRow( "prog_tenting", $prog );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

