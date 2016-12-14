#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::JobHelper;

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

# Return base cu thick by layer
sub GetBaseCuThick {
	my $self      = shift;
	my $jobId     = shift;
	my $layerName = shift;

	my $cuThick;

	if ( HegMethods->GetTypeOfPcb($jobId) eq 'Vicevrstvy' ) {

		my $stackup = Stackup->new($jobId);

		my $cuLayer = $stackup->GetCuLayer($layerName);
		$cuThick = $cuLayer->GetThick();
	}
	else {

		$cuThick = HegMethods->GetOuterCuThick( $jobId, $layerName );
	}

	return $cuThick;
}

#return final thick of pcb in µm
sub GetFinalPcbThick {
	my $self  = shift;
	my $jobId = shift;

	my $thick;

	if ( HegMethods->GetTypeOfPcb($jobId) eq 'Vicevrstvy' ) {

		my $stackup = Stackup->new($jobId);

		$thick = $stackup->GetFinalThick();
	}
	else {

		$thick = HegMethods->GetPcbMaterialThick($jobId);
		$thick = $thick * 1000;
	}

	return $thick;
}

#Return 1 if stackup for pcb exist
sub StackupExist {
	my $self  = shift;
	my $jobId = shift;

	unless ( FileHelper->ExistsByPattern( EnumsPaths->Jobs_STACKUPS, $jobId . "_" ) ) {

		return 0;
	}
	else {

		return 1;
	}

}

sub GetJobArchive {
	my $self  = shift;
	my $jobId = shift;

	return EnumsPaths->Jobs_ARCHIV . substr( $jobId, 0, 3 ) . "\\" . $jobId . "\\";

}

sub GetJobOutput {
	my $self  = shift;
	my $jobId = shift;

	return EnumsPaths->InCAM_jobs . $jobId . "\\output\\";

}

sub GetPcbType {
	my $self = shift;

	my $jobId = shift;

	my $isType = HegMethods->GetTypeOfPcb($jobId);
	my $type;

	if ( $isType eq 'Neplatovany' ) {

		$type = EnumsGeneral->PcbTyp_NOCOPPER;
	}
	elsif ( $isType eq 'Jednostranny' ) {

		$type = EnumsGeneral->PcbTyp_ONELAYER;

	}
	elsif ( $isType eq 'Oboustranny' ) {

		$type = EnumsGeneral->PcbTyp_TWOLAYER;

	}
	else {

		$type = EnumsGeneral->PcbTyp_MULTILAYER;
	}

	return $type;
}

sub GetIsolationByClass {
	my $self  = shift;
	my $class = shift;

	my $isolation;

	if ( $class <= 3 ) {

		$isolation = 400;

	}
	elsif ( $class <= 4 ) {

		$isolation = 300;

	}
	elsif ( $class <= 5 ) {

		$isolation = 200;

	}
	elsif ( $class <= 6 ) {

		$isolation = 150;

	}
	elsif ( $class <= 7 ) {

		$isolation = 125;

	}
	elsif ( $class <= 8 ) {

		$isolation = 100;
	}

	return $isolation;

}

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

