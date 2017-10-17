
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
		my $pcbClass = CamJob->GetJobPcbClass( $inCAM, $jobId );    #attribut pnl_class from job
		$section->AddRow( "kons_trida", $pcbClass );
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

		$section->AddRow( "c_mask_colour", $nifData{"c_mask_colour"} );
	}

	#s_mask_colour
	if ( $self->_IsRequire("s_mask_colour") ) {

		unless ( $nifData{"s_mask_colour"} ) {
			$nifData{"s_mask_colour"} = "";
		}

		$section->AddRow( "s_mask_colour", $nifData{"s_mask_colour"} );
	}

	#c_silk_screen_colour
	if ( $self->_IsRequire("c_silk_screen_colour") ) {

		unless ( $nifData{"c_silk_screen_colour"} ) {
			$nifData{"c_silk_screen_colour"} = "";
		}

		$section->AddRow( "c_silk_screen_colour", $nifData{"c_silk_screen_colour"} );
	}

	#s_silk_screen_colour
	if ( $self->_IsRequire("s_silk_screen_colour") ) {

		unless ( $nifData{"s_silk_screen_colour"} ) {
			$nifData{"s_silk_screen_colour"} = "";
		}

		$section->AddRow( "s_silk_screen_colour", $nifData{"s_silk_screen_colour"} );
	}

	#tenting
	if ( $self->_IsRequire("tenting") ) {

		my $val = "N";
		if ( $nifData{"tenting"} ) {
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
	
	#film_konektoru
	if ( $self->_IsRequire("film_konektoru") ) {
		$section->AddRow( "film_konektoru", $self->__GetGoldFilmTyp() );
	}	
	

	#prokoveni
	if ( $self->_IsRequire("prokoveni") ) {
		$section->AddRow( "prokoveni", $self->__GetProkoveni() );
	}
	
	#prokoveni
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

sub __GetProkoveni {
	my $self = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = "panel";
	my $result   = 'N';

	my $sExist = CamHelper->LayerExists( $inCAM, $jobId, "s" );

	if ($sExist) {

		my $mExist = CamHelper->LayerExists( $inCAM, $jobId, "m" );
	 
		if ($mExist) {
			
			$result = 'A';
			
		}
		
		# zbytek podminky yrusen 19.5.2017

#			my @steps = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $stepName );
#			
#			foreach my $stepInner (@steps) {
#				
#				my $stepInnerName = $stepInner->{"gSRstep"};
#				
#				$inCAM->INFO(
#							  units       => 'mm',
#							  entity_type => 'layer',
#							  entity_path => "$jobId/$stepInnerName/m",
#							  data_type   => 'FEAT_HIST',
#							  options     => 'break_sr'
#				);
#
#				if ( $inCAM->{doinfo}{gFEAT_HISTtotal} > 0 ) {
#					$result = 'A';
#				}
#			}
#		}

		my $rExist = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill );
		if ($rExist) {
			$result = 'A';
		}
	}

	return ($result);
}


sub __GetTypDps {
	my $self = shift;
 
	my $jobId    = $self->{"jobId"};
	my $isPool = HegMethods->GetPcbIsPool($jobId);
	my $isType = HegMethods->GetTypeOfPcb($jobId);

	my $res = "";	

	if ( $isType eq 'Sablona' ) {
		$res = "sablona";
	
	}elsif($isPool){
		
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

