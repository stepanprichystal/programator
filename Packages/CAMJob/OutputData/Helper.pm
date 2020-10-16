#-------------------------------------------------------------------------------------------#
# Description: Helper function for data prepare to output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::Helper;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::CAMJob::OutputData::Enums';
use aliased 'Helpers::ValueConvertor';
use aliased 'Helpers::Translator';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return affected features (cutted) by reference layer (eg. goldc, lc, gc, etc,..)
# And mas if exist and if is requested
sub FeaturesByRefLayer {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $featsL = shift;    # requested layer with features
	my $refL   = shift;    # (eg. goldc, lc, gc, etc,..)
	my $maskL  = shift;    # mask layer (often mc, ms)
	my $lim    = shift;    # area which is processed and result is only fro this area

	my $refLayer = undef;  # default reference layers is gold[m/c]

	# if exist mask too, do intersection between gold and mask layers
	if ( $maskL && CamHelper->LayerExists( $inCAM, $jobId, $maskL ) ) {

		$refLayer = CamLayer->LayerIntersection( $inCAM, $refL, $maskL, $lim );
		CamLayer->Contourize( $inCAM, $refLayer );

	}
	else {

		$refLayer = GeneralHelper->GetGUID();
		$inCAM->COM( "merge_layers", "source_layer" => $refL, "dest_layer" => $refLayer );
	}

	# Do intersection between Gold layer (tmp $goldRef) and selected goldfinegr (tmp $cuGoldFinger)
	my $resultL = CamLayer->LayerIntersection( $inCAM, $refLayer, $featsL, $lim );
	CamLayer->Contourize( $inCAM, $resultL );
	$inCAM->COM( "delete_layer", "layer" => $refLayer );

	return $resultL;
}

sub GetJobLayerTitle {
	my $self       = shift;
	my $l          = shift;
	my $outputType = shift;    # Packages::CAMJob::OutputData::Enums::Type_
	my $cz         = shift;

	my $title = "";

	# outline
	if ( $l->{"gROWname"} =~ /^o$/i ) {

		$title = "Outline";
		if ($cz) {
			$title = "Obrys";
		}
	}

	elsif ( $l->{"gROWname"} =~ /^bend$/i ) {

		$title = "Flexible area outline";
		if ($cz) {
			$title = "Obrys flexibilních částí";
		}
	}

	# inner layer
	elsif ( $l->{"gROWname"} =~ /^v(\d)$/i ) {

		my $lNum = $1;
		$title = "Inner layer number: $lNum.";
		if ($cz) {
			$title = "Vnitřní vrstva číslo: $lNum.";
		}
	}

	# board base layer
	elsif ( $l->{"gROWname"} =~ /^([pmlg]|gold)?[cs]2?$/i ) {

		my %en = ();
		$en{"pc"}    = "Silk screen (top)";
		$en{"ps"}    = "Silk screen (bot)";
		$en{"pc2"}   = "Silk screen (top; second)";
		$en{"ps2"}   = "Silk screen (bot; second)";
		$en{"mc"}    = "Solder mask (top)";
		$en{"ms"}    = "Solder mask (bot)";
		$en{"mc2"}    = "Solder mask (top; second)";
		$en{"ms2"}    = "Solder mask (bot; second)";
		$en{"c"}     = "Component layer (top)";
		$en{"s"}     = "Solder layer (bot)";
		$en{"lc"}    = "Peelable mask (top)";
		$en{"ls"}    = "Peelable mask (bot)";
		$en{"gc"}    = "Carbon paste (top)";
		$en{"gs"}    = "Carbon paste (bot)";
		$en{"goldc"} = "Gold fingers (top)";
		$en{"golds"} = "Gold fingers (bot)";

		my %czl = ();
		$czl{"pc"}    = "Potisk (top)";
		$czl{"ps"}    = "Potisk (bot)";
		$czl{"pc2"}   = "Potisk (top; druhý)";
		$czl{"ps2"}   = "Potisk (bot; druhý)";
		$czl{"mc"}    = "Nepájivá maska (top)";
		$czl{"ms"}    = "Nepájivá maska (bot)";
		$czl{"mc2"}    = "Nepájivá maska (top, druhá)";
		$czl{"ms2"}    = "Nepájivá maska (bot, druhá)";
		$czl{"c"}     = "Strana součástek (top)";
		$czl{"s"}     = "Strana spojů (bot)";
		$czl{"lc"}    = "Snímací lak (top)";
		$czl{"ls"}    = "Snímací lak (bot)";
		$czl{"gc"}    = "Grafit (top)";
		$czl{"gs"}    = "Grafit (bot)";
		$czl{"goldc"} = "Zlacený konektor (top)";
		$czl{"golds"} = "Zlacený konektor (bot)";

		$title = $en{ $l->{"gROWname"} };
		if ($cz) {
			$title = $czl{ $l->{"gROWname"} };
		}
	}
	elsif ( $l->{"gROWname"} =~ /^cvrl(\w*)$/i ) {

		# coverlay
		my $sigLayer = $1;
		my $sigLayerCz;
		my $sigLayerEn;

		if ( $sigLayer eq "c" ) {
			$sigLayerCz = "Strana součástek (top)";
			$sigLayerEn = "Component layer (top)";
		}
		elsif ( $sigLayer eq "s" ) {
			$sigLayerCz = "Strana spojů (bot)";
			$sigLayerEn = "Solder layer (bot)";
		}
		elsif ( $sigLayer =~ /^v(\d)$/i ) {

			my $lNum = $1;
			$sigLayerCz = "Vnitřní vrstva číslo: $lNum.";
			$sigLayerEn = "Inner layer number: $lNum.";
		}

		$title = "Coverlay on " . $sigLayerEn;
		if ($cz) {
			$title = "Coverlay na " . $sigLayerCz;
		}

	}
	elsif ( $l->{"gROWname"} =~ /^stiff(\w*)$/i ) {

		# coverlay
		my $sigLayer = $1;
		my $sigLayerCz;
		my $sigLayerEn;

		if ( $sigLayer eq "c" ) {
			$sigLayerCz = "Strana součástek (top)";
			$sigLayerEn = "Component layer (top)";
		}
		elsif ( $sigLayer eq "s" ) {
			$sigLayerCz = "Strana spojů (bot)";
			$sigLayerEn = "Solder layer (bot)";
		}
		elsif ( $sigLayer =~ /^v(\d)$/i ) {

			my $lNum = $1;
			$sigLayerCz = "Vnitřní vrstva číslo: $lNum.";
			$sigLayerEn = "Inner layer number: $lNum.";
		}

		$title = "Stiffener on " . $sigLayerEn;
		if ($cz) {
			$title = "Stiffener na " . $sigLayerCz;
		}

	}

	# nc layers
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill
			|| ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $outputType eq Enums->Type_NCLAYERS ) )
	{

		$title = "Plated through drilling";
		if ($cz) {
			$title = "Prokovené vrtání";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop
			|| ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop && $outputType eq Enums->Type_NCLAYERS ) )
	{
		$title = "Plated blind drilling from top";
		if ($cz) {
			$title = "Slepé vrtání z top";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot
			|| ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot && $outputType eq Enums->Type_NCLAYERS ) )
	{
		$title = "Plated blind drilling from bot";
		if ($cz) {
			$title = "Slepé vrtání z bot";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $outputType eq Enums->Type_FILLEDHOLES ) {

		$title = "Filled plated through holes";
		if ($cz) {
			$title = "Zaplněné prokovené otvory";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop && $outputType eq Enums->Type_FILLEDHOLES ) {
		$title = "Filled plated blind holes from top";
		if ($cz) {
			$title = "Zaplněné slepé otvory z top";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot && $outputType eq Enums->Type_FILLEDHOLES ) {
		$title = "Filled plated blind holes from bot";
		if ($cz) {
			$title = "Zaplněné slepé otvory z bot";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill && $outputType eq Enums->Type_FILLEDHOLES ) {

		$title = "Filled burried drilling";
		if ($cz) {
			$title = "Zaplněné pohřbené otvory";
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
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nDrill ) {
		$title = "Non-plated drilling";
		if ($cz) {
			$title = "Neprokovené vrtání";
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
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillTop ) {
		$title = "Non-plated core milling from top";
		if ($cz) {
			$title = "Neprokovené hloubkové leptáním jádra z top";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillBot ) {
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
	}elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill ) {
		$title = "Z-axis milling of TOP stiffener";
		if ($cz) {
			$title = "Zahloubené frézování top stiffeneru.";
		}
	}elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffsMill ) {
		$title = "Z-axis milling of BOT stiffener";
		if ($cz) {
			$title = "Zahloubené frézování bot stiffeneru.";
		}
	} 

	die "Title is empty for layer: " . $l->{"gROWname"} if ( $title eq "" );

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

		my $from = ValueConvertor->GetNifCodeValue( $l->{"NCSigStart"} );
		my $to   = ValueConvertor->GetNifCodeValue( $l->{"NCSigEnd"} );

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
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop ) {
			$info = $startStop;

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot ) {
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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

