#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::ValueConvertor;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsGeneral';

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Stackup::Stackup';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub GetJobLayerTitle {
	my $self = shift;
	my $l    = shift;
	my $cz   = shift;

	my $title = "";

	# inner layer
	if ( $l->{"gROWname"} =~ /^v(\d)$/i ) {

		my $lNum = $1;
		$title = "Inner layer number: $lNum.";
		if ($cz) {
			$title = "Vnitrni vrstva cislo: $lNum.";
		}
	}

	# board base layer
	elsif ( $l->{"gROWname"} =~ /^[pm]?[cs]$/i ) {

		my %en = ();
		$en{"pc"} = "Silk screen top";
		$en{"ps"} = "Silk screen bot";
		$en{"mc"} = "Solder mask top";
		$en{"ms"} = "Solder mask bot";
		$en{"c"}  = "Component layer";
		$en{"s"}  = "Solder layer (bot)";

		my %czl = ();
		$czl{"pc"} = "Potisk top";
		$czl{"ps"} = "Potisk bot";
		$czl{"mc"} = "Nepajiva maska top";
		$czl{"ms"} = "Nepajiva maska bot";
		$czl{"c"}  = "Strana spoju (top)";
		$czl{"s"}  = "Strana soucastek (bot)";

		$title = $en{ $l->{"gROWname"} };
		if ($cz) {
			$title = $czl{ $l->{"gROWname"} };
		}
	}

	# nc layers
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill ) {

		$title = "Plated through drilling";
		if ($cz) {
			$title = "Prokovene vrtani";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop ) {
		$title = "Plated blind drilling from top";
		if ($cz) {
			$title = "Slepe vrtani z top";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot ) {
		$title = "Plated blind drilling from bot";
		if ($cz) {
			$title = "Slepe vrtani z bot";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill ) {
		$title = "Plated core drilling";
		if ($cz) {
			$title = "Prokovene vrtani jadra";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill ) {
		$title = "Plated milling";
		if ($cz) {
			$title = "Prokovene frezovani";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop ) {
		$title = "Plated z-axis milling from top";
		if ($cz) {
			$title = "Prokovene zahloubene frezovani z top";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot ) {
		$title = "Plated z-axis milling from bot";
		if ($cz) {
			$title = "Prokovene zahloubene frezovani z bot";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill ) {
		$title = "Non-plated milling";
		if ($cz) {
			$title = "Neprokovene frezovani";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop ) {
		$title = "Non-plated z-axis milling from top";
		if ($cz) {
			$title = "Neprokovene zahloubene frezovani z top";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot ) {
		$title = "Non-plated z-axis milling from bop";
		if ($cz) {
			$title = "Neprokovene zahloubene frezovani z bot";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill ) {
		$title = "Non-plated milling before etching";
		if ($cz) {
			$title = "Neprokovene frezovani pred leptanim";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop ) {
		$title = "Non-plated core milling from top";
		if ($cz) {
			$title = "Neprokovene hloubkove frezovani jadra z top";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot ) {
		$title = "Non-plated core milling from bot";
		if ($cz) {
			$title = "Neprokovene hloubkove frezovani jadra z bot";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill ) {
		$title = "Milling of connector edge";
		if ($cz) {
			$title = "Frezovani hrany konektoru.";
		}
	}

	return $title;

}

sub GetJobLayerInfo {
	my $self = shift;
	my $l    = shift;
	my $cz   = shift;

	my $info = "";

	# inner layer
	if ( $l->{"gROWname"} =~ /^v(\d)$/i ) {

		if ( $l->{"gROWlayer_type"} eq "power_ground" ) {
			$info = "Power-ground displayed as negative";
			if ($cz) {
				$info = "Power-ground zobrazena negativne";
			}
		}
	}
	elsif ( $l->{"type"} ) {

		# get start/stop layer
		my $startStop = "From: " . $l->{"gROWdrl_start_name"} . " to: " . $l->{"gROWdrl_end_name"};
		if ($cz) {
			$startStop = "z: " . $l->{"gROWdrl_start_name"} . " do: " . $l->{"gROWdrl_end_name"};
		}

		# nc layers

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop ) {
			$info = $startStop;

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot ) {
			$info = $startStop;

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill ) {
			$info = $startStop;

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill && $l->{"gROWname"} =~ /^m\d$/ ) {
			$info = $startStop;

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop ) {
			$info = $startStop;

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot ) {
			$info = $startStop;

		}

		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop ) {
			$info = $startStop;
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot ) {
			$info = $startStop;
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill ) {
			$info = "Milling is used for achive best final quality";
			if ($cz) {
				$info = "Frezovanio je pouzivano pro dosazeni vysoke kvality opracovani.";
			}
		}

		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill ) {
			$info = "Milling is used before electrical testing";
			if ($cz) {
				$info = "Frezovani pred elektrickym testem pro korektni prubeh testu.";
			}
		}
	}

	return $info;

}

sub GetNifCodeValue {
	my $self = shift;
	my $code = shift;

	my $info = "";

	# inner layer
	if ( $code =~ /^pc$/i ) {

		$info = "Silk screen top";
	}

	elsif ( $code =~ /^ps$/i ) {

		$info = "Silk screen bot";
	}

	elsif ( $code =~ /^mc$/i ) {

		$info = "Solder mask top";
	}
	elsif ( $code =~ /^ms$/i ) {

		$info = "Solder mask bot";
	}
	elsif ( $code =~ /^c$/i ) {

		$info = "Component side";
	}
	elsif ( $code =~ /^s$/i ) {

		$info = "Solder side";
	}

	return $info;
}

sub GetMaskColorToCode {
	my $self  = shift;
	my $color = shift;

	if ( $color eq "" ) {
		return "";
	}

	my %colorMap = ();
	$colorMap{"Green"}       = "Z";
	$colorMap{"Black"}       = "B";
	$colorMap{"White"}       = "W";
	$colorMap{"Blue"}        = "M";
	$colorMap{"Transparent"} = "T";
	$colorMap{"Red"}         = "R";

	return $colorMap{$color};
}

sub GetMaskCodeToColor {
	my $self = shift;
	my $code = shift;

	if ( $code eq "" ) {
		return "";
	}

	my %colorMap = ();
	$colorMap{"Z"} = "Green";
	$colorMap{"B"} = "Black";
	$colorMap{"W"} = "White";
	$colorMap{"M"} = "Blue";
	$colorMap{"T"} = "Transparent";
	$colorMap{"R"} = "Red";

	return $colorMap{$code};

}

sub GetSilkColorToCode {
	my $self  = shift;
	my $color = shift;

	if ( $color eq "" ) {
		return "";
	}

	my %colorMap = ();
	$colorMap{"White"}  = "B";
	$colorMap{"Yellow"} = "Z";
	$colorMap{"Black"}  = "C";

	return $colorMap{$color};
}

sub GetSilkCodeToColor {
	my $self = shift;
	my $code = shift;

	if ( $code eq "" ) {
		return "";
	}

	my %colorMap = ();
	$colorMap{"B"} = "White";
	$colorMap{"Z"} = "Yellow";
	$colorMap{"C"} = "Black";

	return $colorMap{$code};

	#
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Helpers::JobHelper';

	#print JobHelper->GetBaseCuThick("F13608", "v3");

	#print "\n1";
}

1;

