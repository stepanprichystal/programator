
#-------------------------------------------------------------------------------------------#
# Description: SMAZAT - pomocnz builder , ktery exportuje informace pro flexi vyvojovy postup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderFlexiTmp;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;
use Time::localtime;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::CAMJob::Dim::JobDim';

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

	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};
	my %nifData = %{ $self->{"nifData"} };

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );
	my $stackup;

	if ( $layerCnt > 2 ) {
		$stackup = Stackup->new( $self->{'jobId'} );
	}

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );
	my $w   = abs( $lim{"xMax"} - $lim{"xMin"} );
	my $h   = abs( $lim{"yMax"} - $lim{"yMin"} );

	my $pcbFlexType = JobHelper->GetPcbFlexType($jobId);

	# =========================
	# Zdrojové data postupu
	# =========================

	my $info = ( HegMethods->GetAllByPcbId($jobId) )[0];

	unless ( defined $pcbFlexType ) {

		return 0;
	}

	# postup Hlavicka ----------------

	$section->AddRow( "orderId",  HegMethods->GetPcbOrderNumber($jobId) );
	$section->AddRow( "jobName",  $info->{"board_name"} );
	$section->AddRow( "term",     $info->{"termin"} );
	$section->AddRow( "customer", HegMethods->GetCustomerInfo($jobId)->{"customer"} );

	# postup parametry-----------

	my $jobClass = CamJob->GetJobPcbClass( $inCAM, $jobId );
	die "Job pcb class is empty" if ( $jobClass eq "" || $jobClass == 0 );
	$section->AddRow( "kons_trida_flex",   $jobClass );
	$section->AddRow( "pocet_vrstev_flex", "*" );

	$section->AddRow( "tloustka_cu", JobHelper->GetBaseCuThick( $jobId, "c" ) . "um" );

	my $tlFlexCu = JobHelper->GetBaseCuThick( $jobId, "c" );

	if ( $pcbFlexType eq EnumsGeneral->PcbFlexType_RIGIDFLEXI ) {

		my @cores = $stackup->GetAllCores();
		$tlFlexCu = $cores[ int( scalar(@cores) / 2 ) ]->GetTopCopperLayer()->GetThick();
	}

	$section->AddRow( "tl_flex_cu", $tlFlexCu . "um" );

	my %dim = JobDim->GetDimension( $inCAM, $jobId );
	my $pocet = int( $info->{"pocet"} / $dim{"nasobnost"});
	
	if($info->{"pocet"} % $dim{"nasobnost"} ){
		$pocet++;
	}

	$section->AddRow( "pocet_prirezu", $pocet );
	$section->AddRow( "plocha", sprintf( "%0.1f dm2", $w * $h * $pocet / 10000 ) );

	$section->AddRow( "tenting_plocha", sprintf( "%0.1f cm2", $w * $h / 100 ) );

	# postup  operace Flexi -------------

	if ( $layerCnt > 2 ) {

		my @flexCores = grep { $_->GetQId() == 10 } $stackup->GetAllCores();

		for ( my $i = 0 ; $i < scalar(@flexCores) ; $i++ ) {

			my @mat = HegMethods->GetCoreStoreInfo( $flexCores[$i]->GetQId(), $flexCores[$i]->GetId(), $flexCores[$i]->GetTopCopperLayer()->GetId() );

			@mat = grep { abs( $_->{"sirka"} - $w ) < 5 && abs( $_->{"hloubka"} - $h ) < 5 } @mat;

			$section->AddRow( "material_flex_" . ( $i + 1 ), $mat[0]{"nazev_mat"} );
		}
	}
	else {

		$section->AddRow( "material_flex_1", $info->{"material_nazev"} );

	}

	my $archive = JobHelper->GetJobArchive($jobId);

	my ($dir) = $archive =~ /(\w\d{3}\\\w\d{6})/i;

	my $ncArchiv = "Q:\\" . $dir;

	$section->AddRow( "program_vrtani_flex", $ncArchiv . "\\nc\\" . $jobId . "_c" );

	if ( $layerCnt > 2 ) {
		$section->AddRow( "program_vrtani_okoli_flex", $ncArchiv . "\\nc\\" . $jobId . "_v1" );
	}

	# postup operace Coverlay -------------
	$section->AddRow( "material_coverlay",            "Coverlay LF 0110 304,8 x 457,2mm" );
	$section->AddRow( "program_frezovani_coverlay_c", $ncArchiv . "\\nc\\" . $jobId . "_coverlayc" );
	$section->AddRow( "program_frezovani_coverlay_s", $ncArchiv . "\\nc\\" . $jobId . "_coverlays" );

	# postup operace Rigid -------------

	if ( $info->{"poznamka"} =~ /type=rigid-flexi/i ) {
		
		# program na zakryti
		 if ( $info->{"poznamka"} !~ /type=rigid-flexi-i/i ) {
		$section->AddRow( "expozice_zakryti_top",   "307x407_plna_cu_top_mdi.xml" );
		 }
		 $section->AddRow( "expozice_zakryti_bot",   "307x407_plna_cu_bot_mdi.xml" );
		

		my @rigidCores = grep { $_->GetQId() != 10 } $stackup->GetAllCores();

		# identifikuj jadra v Rigid casti TOP

		if ( $info->{"poznamka"} !~ /type=rigid-flexi-i/i ) {

			my @rigidCoresTOP = ();

			foreach my $c ($stackup->GetAllCores()) {

				if ( $c->GetQId() == 10 ) {
					last;
				}

				push( @rigidCoresTOP, $c );
			}

			$section->AddRow( "jadra_top_rigid_cast", join( ";", map { "J" . $_->GetCoreNumber() } @rigidCoresTOP ) );
		}

		my @rigidCoresBOT = ();
		foreach my $c (reverse $stackup->GetAllCores()) {

				if ( $c->GetQId() == 10 ) {
					last;
				}

				push( @rigidCoresBOT, $c );
		}

		$section->AddRow( "jadra_bot_rigid_cast", join( ";", map { "J" . $_->GetCoreNumber() } reverse @rigidCoresBOT ) );

		# program_vrtani_rigid_jadro_bot=d152456.c
		my @matTop = HegMethods->GetCoreStoreInfo( $rigidCores[0]->GetQId(), $rigidCores[0]->GetId(), $rigidCores[0]->GetTopCopperLayer()->GetId() );
		@matTop = grep { abs( $_->{"sirka"} - $w ) < 5 && abs( $_->{"hloubka"} - $h ) < 5 } @matTop;

		$section->AddRow( "material_rigid_top", $matTop[0]{"nazev_mat"} );

		my @matBot =
		  HegMethods->GetCoreStoreInfo( $rigidCores[-1]->GetQId(), $rigidCores[-1]->GetId(), $rigidCores[-1]->GetTopCopperLayer()->GetId() );
		@matBot = grep { abs( $_->{"sirka"} - $w ) < 5 && abs( $_->{"hloubka"} - $h ) < 5 } @matBot;

		$section->AddRow( "material_rigid_bot", $matBot[0]{"nazev_mat"} );

		if ( $info->{"poznamka"} !~ /type=rigid-flexi-i/i ) {

			$section->AddRow( "program_vrtani_rigid_jadro_top", $ncArchiv . "\\nc\\" . $jobId . "_v1" );
			$section->AddRow( "program_hl_freza_rigid_top_1",   $ncArchiv . "\\nc\\" . $jobId . "_jfzs" . $rigidCores[0]->GetCoreNumber() );
			$section->AddRow( "program_hl_freza_rigid_top_2",   $ncArchiv . "\\nc\\" . $jobId . "_jfzc" . $rigidCores[0]->GetCoreNumber() );
		}

		$section->AddRow( "program_vrtani_rigid_jadro_bot", $ncArchiv . "\\nc\\" . $jobId . "_v1" );
		$section->AddRow( "program_hl_freza_rigid_bot_1",   $ncArchiv . "\\nc\\" . $jobId . "_jfzc" . $rigidCores[-1]->GetCoreNumber() );
		$section->AddRow( "program_hl_freza_rigid_bot_2",   $ncArchiv . "\\nc\\" . $jobId . "_jfzs" . $rigidCores[-1]->GetCoreNumber() );

		$section->AddRow( "program_prokovene_vrtani", $ncArchiv . "\\nc\\" . $jobId . "_c1" );

		# postup operace Prepreg-------------
		my @noflowPrepreg = map { $_->GetAllPrepregs() } grep { $_->GetType() eq StackEnums->MaterialType_PREPREG } $stackup->GetAllLayers();
		@noflowPrepreg = grep { $_->GetQId() == 10 } @noflowPrepreg;

		my @noflowPrepregMat =
		  HegMethods->GetPrepregStoreInfo( $noflowPrepreg[0]->GetQId(), $noflowPrepreg[0]->GetId() );

		$section->AddRow( "material_prepreg", $noflowPrepregMat[0]{"nazev_mat"} );

		$section->AddRow( "program_frezovani_prepreg", $ncArchiv . "\\nc\\" . $jobId . "_prepreg" );
 
 		my $prepregPerPanel = scalar(grep {  $_->GetQId() == 10 } map { $_->GetAllPrepregs() } grep { $_->GetType() eq StackEnums->MaterialType_PREPREG } $stackup->GetAllLayers());
 		
 		$section->AddRow( "pocet_prepregu_na_prirez", $prepregPerPanel );
 
		# postup ostatni operace

		#if v poznamce je flexi
	}

	# Expozice ------------------------
	$section->AddRow( "expozice_c", $jobId . "c_mdi.xml" );
	$section->AddRow( "expozice_s", $jobId . "s_mdi.xml" );

	if ( $info->{"poznamka"} =~ /type=rigid-flexi/i ) {

		my $flexCore = ( grep { $_->GetQId() == 10 } $stackup->GetAllCores() )[0];    # predpokladam jen 1 flex jadro

		$section->AddRow( "expozice_flex_c", $jobId . $flexCore->GetTopCopperLayer()->GetCopperName() . "_mdi.xml" );
		$section->AddRow( "expozice_flex_s", $jobId . $flexCore->GetBotCopperLayer()->GetCopperName() . "_mdi.xml" );

		if ( $info->{"poznamka"} !~ /type=rigid-flexi-i/i ) {
			foreach my $core ( $stackup->GetAllCores() ) {

				if ( $core->GetCoreNumber() == $flexCore->GetCoreNumber() - 1 ) {
					$section->AddRow( "expozice_rigid_top_s", $jobId . $core->GetBotCopperLayer()->GetCopperName() . "_mdi.xml" );
					last;
				}
			}
		}

		foreach my $core ( $stackup->GetAllCores() ) {

			if ( $core->GetCoreNumber() == $flexCore->GetCoreNumber() + 1 ) {
				$section->AddRow( "expozice_rigid_bot_c", $jobId . $core->GetTopCopperLayer()->GetCopperName() . "_mdi.xml" );
				last;
			}
		}
	}
	
	
	# Vrtani po prokovu
	if ( $layerCnt > 2 ) {
		$section->AddRow( "program_freza_po_prokovu", $ncArchiv . "\\nc\\" . $jobId . "_fc1" );
	}else{
		$section->AddRow( "program_freza_po_prokovu", $ncArchiv . "\\nc\\" . $jobId . "_fc" );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

