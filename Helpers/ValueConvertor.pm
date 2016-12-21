#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::ValueConvertor;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::Translator';
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
			$title = "Vnitřní vrstva číslo: $lNum.";
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
		$czl{"mc"} = "Nepájivá maska top";
		$czl{"ms"} = "Nepájivá maska bot";
		$czl{"c"}  = "Strana spojů (top)";
		$czl{"s"}  = "Strana součástek (bot)";

		$title = $en{ $l->{"gROWname"} };
		if ($cz) {
			$title = $czl{ $l->{"gROWname"} };
		}
	}

	# nc layers
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill ) {

		$title = "Plated through drilling";
		if ($cz) {
			$title = "Prokovené vrtání";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop ) {
		$title = "Plated blind drilling from top";
		if ($cz) {
			$title = "Slepé vrtání z top";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot ) {
		$title = "Plated blind drilling from bot";
		if ($cz) {
			$title = "Slepé vrtání z bot";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill ) {
		$title = "Plated core drilling";
		if ($cz) {
			$title = "Prokovené vrtání jádra";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill ) {
		$title = "Plated milling";
		if ($cz) {
			$title = "Prokovené frézování";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop ) {
		$title = "Plated z-axis milling from top";
		if ($cz) {
			$title = "Prokovené zahloubené frézování z top";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot ) {
		$title = "Plated z-axis milling from bot";
		if ($cz) {
			$title = "Prokovené zahloubené frézování z bot";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill ) {
		$title = "Non-plated milling";
		if ($cz) {
			$title = "Neprokovené frézování";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop ) {
		$title = "Non-plated z-axis milling from top";
		if ($cz) {
			$title = "Neprokovené zahloubené frézování z top";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot ) {
		$title = "Non-plated z-axis milling from bot";
		if ($cz) {
			$title = "Neprokovené zahloubené frézování z bot";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill ) {
		$title = "Non-plated milling before etching";
		if ($cz) {
			$title = "Neprokovené frézování před leptáním";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop ) {
		$title = "Non-plated core milling from top";
		if ($cz) {
			$title = "Neprokovené hloubkové leptáním jádra z top";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot ) {
		$title = "Non-plated core milling from bot";
		if ($cz) {
			$title = "Neprokovené hloubkové frézování jádra z bot";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill ) {
		$title = "Milling of connector edge";
		if ($cz) {
			$title = "Frézování hrany konektoru";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score ) {
		$title = "V-scoring";
		if ($cz) {
			$title = "V-drážka";
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
				$info = "Power-ground zobrazena negativně";
			}
		}
	}
	elsif ( $l->{"type"} ) {

		# get start/stop layer
		
		my $from = $self->GetNifCodeValue($l->{"gROWdrl_start_name"});
		my $to = $self->GetNifCodeValue($l->{"gROWdrl_end_name"});
		
		
		my $startStop = "From: " . $from . " to: " . $to;
		if ($cz) {
			$startStop = "z: " . Translator->Cz($from) . " do: " . Translator->Cz($to);
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
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill && $l->{"gROWname"} =~ /^m\d$/ ) {
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
				$info = "Frézování je Používáno pro dosažení vysoké kvality opracování.";
			}
		}

		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill ) {
			$info = "Layer can contains extra \"pilot-holes\".";
			if ($cz) {
				$info = "Vrstva může obsahovat pomocné \"pilot-holes\".";
			}
			
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill ) {
			$info = "Milling is used before electrical testing";
			if ($cz) {
				$info = "Frézování před elektrickým testem pro korektní průběh testu.";
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
	
	}elsif ( $code =~ /^v(\d)$/i ) {

		$info = "Inner layer $1";
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
