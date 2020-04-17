
#-------------------------------------------------------------------------------------------#
# Description: Build section about general pcb information
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderPcb;
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
use aliased 'CamHelpers::CamMatrix';

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStepRepeat';

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

	#reference
	if ( $self->_IsRequire("reference") ) {
		$section->AddRow( "reference", uc( $self->{"jobId"} ) );
	}

	#zpracoval
	if ( $self->_IsRequire("zpracoval") ) {

		$section->AddRow( "zpracoval", $nifData{"zpracoval"} );
	}

	#kons_trida
	if ( $self->_IsRequire("kons_trida") ) {
		my $pcbClass = CamJob->GetLimJobPcbClass( $inCAM, $jobId, "max" );    #attribut pnl_class from job
		$section->AddRow( "kons_trida", $pcbClass );
	}

	#konstr_trida_vnitrni_vrstvy
	if ( $self->{"layerCnt"} > 2 ) {

		if ( $self->_IsRequire("konstr_trida_vnitrni_vrstvy") ) {

			my $pcbClass = 0;

			if ( $self->{"layerCnt"} > 2 ) {
				$pcbClass = CamJob->GetJobPcbClassInner( $inCAM, $jobId );    #attribut pnl_class from job
			}

			$section->AddRow( "konstr_trida_vnitrni_vrstvy", $pcbClass );
		}
	}

	#pocet_vrstev
	if ( $self->_IsRequire("pocet_vrstev") ) {

		my $val = 0;
		unless ( HegMethods->GetTypeOfPcb($jobId) eq 'Neplatovany' ) {

			$val = $self->{"layerCnt"};
		}

		$section->AddRow( "pocet_vrstev", $val );
	}

	#c_mask_colour
	if ( $self->_IsRequire("c_mask_colour") ) {

		unless ( $nifData{"c_mask_colour"} ) {
			$nifData{"c_mask_colour"} = "";
		}

		$section->AddRow( "maska_c_1", $nifData{"c_mask_colour"} );
	}

	#s_mask_colour
	if ( $self->_IsRequire("s_mask_colour") ) {

		unless ( $nifData{"s_mask_colour"} ) {
			$nifData{"s_mask_colour"} = "";
		}

		$section->AddRow( "maska_s_1", $nifData{"s_mask_colour"} );
	}
	
	#c_mask_colour2
	if ( $self->_IsRequire("c_mask_colour2") ) {

		unless ( $nifData{"c_mask_colour2"} ) {
			$nifData{"c_mask_colour2"} = "";
		}

		$section->AddRow( "maska_c_2", $nifData{"c_mask_colour2"} );
	}

	#s_mask_colour2
	if ( $self->_IsRequire("s_mask_colour2") ) {

		unless ( $nifData{"s_mask_colour2"} ) {
			$nifData{"s_mask_colour2"} = "";
		}

		$section->AddRow( "maska_s_2", $nifData{"s_mask_colour2"} );
	}
	

	#c_silk_screen_colour
	if ( $self->_IsRequire("c_silk_screen_colour") ) {

		unless ( $nifData{"c_silk_screen_colour"} ) {
			$nifData{"c_silk_screen_colour"} = "";
		}

		$section->AddRow( "potisk_c_1", $nifData{"c_silk_screen_colour"} );
	}

	#s_silk_screen_colour
	if ( $self->_IsRequire("s_silk_screen_colour") ) {

		unless ( $nifData{"s_silk_screen_colour"} ) {
			$nifData{"s_silk_screen_colour"} = "";
		}

		$section->AddRow( "potisk_s_1", $nifData{"s_silk_screen_colour"} );
	}

	#c_silk_screen_colour2
	if ( $self->_IsRequire("c_silk_screen_colour2") ) {

		unless ( $nifData{"c_silk_screen_colour2"} ) {
			$nifData{"c_silk_screen_colour2"} = "";
		}

		$section->AddRow( "potisk_c_2", $nifData{"c_silk_screen_colour2"} );
	}

	#s_silk_screen_colour2
	if ( $self->_IsRequire("s_silk_screen_colour2") ) {

		unless ( $nifData{"s_silk_screen_colour2"} ) {
			$nifData{"s_silk_screen_colour2"} = "";
		}

		$section->AddRow( "potisk_s_2", $nifData{"s_silk_screen_colour2"} );
	}

	#flexi_maska
	if ( $self->_IsRequire("flexi_maska") ) {

		unless ( $nifData{"flexi_maska"} ) {
			$nifData{"flexi_maska"} = "";
		}

		$section->AddRow( "flexi_maska", $nifData{"flexi_maska"} );
	}

	#coverlay
	if ( $self->_IsRequire("coverlay") ) {

		my @coverLay =
		  grep { $_->{"gROWlayer_type"} eq "coverlay" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

		my $top = 0;
		my $bot = 0;

		foreach my $c (@coverLay) {

			my $side = CamMatrix->GetNonSignalLayerSide( $inCAM, $jobId, $c->{"gROWname"} );

			$top = 1 if ( $side eq "top" );
			$bot = 1 if ( $side eq "bot" );

		}

		my $res = "";
		$res = "C" if ( $top  && !$bot );
		$res = "S" if ( !$top && $bot );
		$res = "2" if ( $top  && $bot );

		$section->AddRow( "coverlay", $res );
	}

	#tenting
	if ( $self->_IsRequire("tenting") ) {

		my $val = "N";

		if ( $nifData{"tenting"} == 1 ) {
			$val = "A";
		}

		$section->AddRow( "tenting", $val );
	}

	#lak_typ
	if ( $self->_IsRequire("lak_typ") ) {
		$section->AddRow( "lak_typ", $self->__GetLakTyp() );
	}

	#uhlik_typ
	if ( $self->_IsRequire("uhlik_typ") ) {
		$section->AddRow( "uhlik_typ", $self->__GetUhlikTyp() );
	}

	#stiffener
	if ( $self->_IsRequire("stiffener") ) {

		my @stiffener =
		  grep { $_->{"gROWlayer_type"} eq "stiffener" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

		my $top = 0;
		my $bot = 0;

		foreach my $s (@stiffener) {

			my $side = CamMatrix->GetNonSignalLayerSide( $inCAM, $jobId, $s->{"gROWname"} );

			$top = 1 if ( $side eq "top" );
			$bot = 1 if ( $side eq "bot" );
		}

		my $res = "";
		$res = "C" if ( $top  && !$bot );
		$res = "S" if ( !$top && $bot );
		$res = "2" if ( $top  && $bot );

		$section->AddRow( "stiffener", $res );
	}

	#film_konektoru
	if ( $self->_IsRequire("film_konektoru") ) {
		$section->AddRow( "film_konektoru", $self->__GetGoldFilmTyp() );
	}

	# technologie
	if ( $self->_IsRequire("technologie") ) {

		my $technology = undef;

		$technology = "G" if ( $nifData{"technology"} eq EnumsGeneral->Technology_GALVANICS );
		$technology = "M" if ( $nifData{"technology"} eq EnumsGeneral->Technology_RESIST );
		$technology = "J" if ( $nifData{"technology"} eq EnumsGeneral->Technology_OTHER );
		$technology = "S" if ( $nifData{"technology"} eq EnumsGeneral->Technology_SCREENPRINT );

		$section->AddRow( "technologie", $technology );
	}

	#prokoveni
	if ( $self->_IsRequire("prokoveni") ) {

		my $prokoveni = "N";
		$prokoveni = "A" if ( $nifData{"technology"} eq EnumsGeneral->Technology_GALVANICS );

		$section->AddRow( "prokoveni", $prokoveni );
	}

	#typ_dps
	if ( $self->_IsRequire("typ_dps") ) {
		$section->AddRow( "typ_dps", $self->__GetTypDps() );
	}

	#datum_pripravy
	if ( $self->_IsRequire("datum_pripravy") ) {
		my $date = sprintf "%04.f-%02.f-%02.f", ( localtime->year() + 1900 ), ( localtime->mon() + 1 ), localtime->mday();
		$section->AddRow( "datum_pripravy", $date );
	}

}

sub __GetLakTyp {
	my $self = shift;
	return $self->__GetLayerExist( "lc", "ls" );
}

sub __GetUhlikTyp {
	my $self = shift;
	return $self->__GetLayerExist( "gc", "gs" );
}

sub __GetGoldFilmTyp {
	my $self = shift;
	return $self->__GetLayerExist( "goldc", "golds" );
}

sub __GetLayerExist {
	my $self = shift;
	my $top  = shift;
	my $bot  = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = "panel";

	my $lcExist = CamHelper->LayerExists( $inCAM, $jobId, $top );
	my $lsExist = CamHelper->LayerExists( $inCAM, $jobId, $bot );

	my $res = "";

	if ( $lcExist && $lsExist ) {
		$res = 2;
	}
	elsif ( $lcExist && !$lsExist ) {
		$res = "C";
	}
	elsif ( !$lcExist && $lsExist ) {
		$res = "S";
	}

	return $res;
}

#sub __GetProkoveni {
#	my $self = shift;
#
#	my $inCAM    = $self->{"inCAM"};
#	my $jobId    = $self->{"jobId"};
#	my $stepName = "panel";
#	my $result   = 'N';
#
#	if ( $self->{"layerCnt"} >= 2
#		 && CamDrilling->GetNCLayersByTypes(
#											 $inCAM, $jobId,
#											 [
#											   EnumsGeneral->LAYERTYPE_plt_nDrill,        EnumsGeneral->LAYERTYPE_plt_bDrillTop,
#											   EnumsGeneral->LAYERTYPE_plt_bDrillBot,     EnumsGeneral->LAYERTYPE_plt_nFillDrill,
#											   EnumsGeneral->LAYERTYPE_plt_bFillDrillTop, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot,
#											   EnumsGeneral->LAYERTYPE_plt_nMill,         EnumsGeneral->LAYERTYPE_plt_bMillTop,
#											   EnumsGeneral->LAYERTYPE_plt_bMillBot
#											 ]
#		 )
#	  )
#	{
#
#		$result = 'A';
#	}
#
#	return ($result);
#}
#
#sub __GetTechnologie {
#	my $self = shift;
#
#	my $inCAM    = $self->{"inCAM"};
#	my $jobId    = $self->{"jobId"};
#	my $stepName = "panel";
#
#	my $prokoveni = $self->__GetProkoveni();
#
#	die "Attribute \"Prokoveni\" is not defined" if ( !defined $prokoveni );
#
#	my $tech = 'G';    # galvanika
#	$tech = 'M' if ( $prokoveni eq "N" );    # leptaci resist
#
#	return ($tech);
#}

sub __GetTypDps {
	my $self = shift;

	my $jobId  = $self->{"jobId"};
	my $isPool = HegMethods->GetPcbIsPool($jobId);
	my $isType = HegMethods->GetTypeOfPcb($jobId);

	my $res = "";

	if ( $isType eq 'Sablona' ) {
		$res = "sablona";

	}
	elsif ($isPool) {

		$res = "pool";
	}

	return ($res);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

