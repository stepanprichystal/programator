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
			$title = "Obrys flexibiln??ch ????st??";
		}
	}

	# inner layer
	elsif ( $l->{"gROWname"} =~ /^v(\d+)$/i ) {

		my $lNum = $1;
		$title = "Inner layer number: $lNum.";
		if ($cz) {
			$title = "Vnit??n?? vrstva ????slo: $lNum.";
		}
	}

	# board base layer
	elsif ( $l->{"gROWname"} =~ /^([pmlg]|gold)?[cs]2?(flex)?$/i ) {

		my %en = ();
		$en{"pc"}     = "Silk screen (top)";
		$en{"ps"}     = "Silk screen (bot)";
		$en{"pc2"}    = "Silk screen (top; second)";
		$en{"ps2"}    = "Silk screen (bot; second)";
		$en{"mc"}     = "Solder mask (top)";
		$en{"ms"}     = "Solder mask (bot)";
		$en{"mc2"}    = "Solder mask (top; second)";
		$en{"ms2"}    = "Solder mask (bot; second)";
		$en{"mcflex"} = "Flexible solder mask (top)";
		$en{"msflex"} = "Flexible solder mask (bot)";
		$en{"c"}      = "Component layer (top)";
		$en{"s"}      = "Solder layer (bot)";
		$en{"lc"}     = "Peelable mask (top)";
		$en{"ls"}     = "Peelable mask (bot)";
		$en{"gc"}     = "Carbon paste (top)";
		$en{"gs"}     = "Carbon paste (bot)";
		$en{"goldc"}  = "Gold fingers (top)";
		$en{"golds"}  = "Gold fingers (bot)";

		my %czl = ();
		$czl{"pc"}     = "Potisk (top)";
		$czl{"ps"}     = "Potisk (bot)";
		$czl{"pc2"}    = "Potisk (top; druh??)";
		$czl{"ps2"}    = "Potisk (bot; druh??)";
		$czl{"mc"}     = "Nep??jiv?? maska (top)";
		$czl{"ms"}     = "Nep??jiv?? maska (bot)";
		$czl{"mc2"}    = "Nep??jiv?? maska (top, druh??)";
		$czl{"ms2"}    = "Nep??jiv?? maska (bot, druh??)";
		$czl{"mcflex"} = "Flexibiln?? nep??jiv?? maska (top)";
		$czl{"msflex"} = "Flexibiln?? nep??jiv?? maska (bot)";
		$czl{"c"}      = "Strana sou????stek (top)";
		$czl{"s"}      = "Strana spoj?? (bot)";
		$czl{"lc"}     = "Sn??mac?? lak (top)";
		$czl{"ls"}     = "Sn??mac?? lak (bot)";
		$czl{"gc"}     = "Grafit (top)";
		$czl{"gs"}     = "Grafit (bot)";
		$czl{"goldc"}  = "Zlacen?? konektor (top)";
		$czl{"golds"}  = "Zlacen?? konektor (bot)";

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
			$sigLayerCz = "Strana sou????stek (top)";
			$sigLayerEn = "Component layer (top)";
		}
		elsif ( $sigLayer eq "s" ) {
			$sigLayerCz = "Strana spoj?? (bot)";
			$sigLayerEn = "Solder layer (bot)";
		}
		elsif ( $sigLayer =~ /^v(\d)$/i ) {

			my $lNum = $1;
			$sigLayerCz = "Vnit??n?? vrstva ????slo: $lNum.";
			$sigLayerEn = "Inner layer number: $lNum.";
		}

		$title = "Coverlay on " . $sigLayerEn;
		if ($cz) {
			$title = "Coverlay na " . $sigLayerCz;
		}

	}
	elsif ( $l->{"gROWname"} =~ /^stiff(\w*)$/i ) {

		# Stiffener
		my $sigLayer = $1;
		my $sigLayerCz;
		my $sigLayerEn;

		if ( $sigLayer eq "c" ) {
			$sigLayerCz = "Strana sou????stek (top)";
			$sigLayerEn = "Component layer (top)";
		}
		elsif ( $sigLayer eq "s" ) {
			$sigLayerCz = "Strana spoj?? (bot)";
			$sigLayerEn = "Solder layer (bot)";
		}
		elsif ( $sigLayer =~ /^v(\d)$/i ) {

			my $lNum = $1;
			$sigLayerCz = "Vnit??n?? vrstva ????slo: $lNum.";
			$sigLayerEn = "Inner layer number: $lNum.";
		}

		$title = "Stiffener on " . $sigLayerEn;
		if ($cz) {
			$title = "Stiffener na " . $sigLayerCz;
		}

	}
	elsif ( $l->{"gROWname"} =~ /^tp([cs])$/i ) {

		# Adhesive tape
		my $sigLayer = $1;
		my $sigLayerCz;
		my $sigLayerEn;

		if ( $sigLayer eq "c" ) {
			$sigLayerCz = "Strana sou????stek (top)";
			$sigLayerEn = "Component layer (top)";
		}
		elsif ( $sigLayer eq "s" ) {
			$sigLayerCz = "Strana spoj?? (bot)";
			$sigLayerEn = "Solder layer (bot)";
		}

		$title = "Double sided adhesive tape on " . $sigLayerEn;
		if ($cz) {
			$title = "Oboustrann?? lep??c?? p??ska na " . $sigLayerCz;
		}

	}

	# nc layers
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill
			|| ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $outputType eq Enums->Type_NCLAYERS ) )
	{

		$title = "Plated through drilling";
		if ($cz) {
			$title = "Prokoven?? vrt??n??";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop
			|| ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop && $outputType eq Enums->Type_NCLAYERS ) )
	{
		$title = "Plated blind drilling from top";
		if ($cz) {
			$title = "Slep?? vrt??n?? z top";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot
			|| ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot && $outputType eq Enums->Type_NCLAYERS ) )
	{
		$title = "Plated blind drilling from bot";
		if ($cz) {
			$title = "Slep?? vrt??n?? z bot";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $outputType eq Enums->Type_FILLEDHOLES ) {

		$title = "Filled plated through holes";
		if ($cz) {
			$title = "Zapln??n?? prokoven?? otvory";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop && $outputType eq Enums->Type_FILLEDHOLES ) {
		$title = "Filled plated blind holes from top";
		if ($cz) {
			$title = "Zapln??n?? slep?? otvory z top";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot && $outputType eq Enums->Type_FILLEDHOLES ) {
		$title = "Filled plated blind holes from bot";
		if ($cz) {
			$title = "Zapln??n?? slep?? otvory z bot";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill && $outputType eq Enums->Type_FILLEDHOLES ) {

		$title = "Filled burried drilling";
		if ($cz) {
			$title = "Zapln??n?? poh??ben?? otvory";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill ) {
		$title = "Plated core drilling";
		if ($cz) {
			$title = "Prokoven?? vrt??n?? j??dra";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill ) {
		$title = "Plated milling";
		if ($cz) {
			$title = "Prokoven?? fr??zov??n??";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop ) {
		$title = "Plated z-axis milling from top";
		if ($cz) {
			$title = "Prokoven?? zahlouben?? fr??zov??n?? z top";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot ) {
		$title = "Plated z-axis milling from bot";
		if ($cz) {
			$title = "Prokoven?? zahlouben?? fr??zov??n?? z bot";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nDrill ) {
		$title = "Non-plated drilling";
		if ($cz) {
			$title = "Neprokoven?? vrt??n??";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill ) {
		$title = "Non-plated milling";
		if ($cz) {
			$title = "Neprokoven?? fr??zov??n??";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop ) {
		$title = "Non-plated z-axis milling from top";
		if ($cz) {
			$title = "Neprokoven?? zahlouben?? fr??zov??n?? z top";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot ) {
		$title = "Non-plated z-axis milling from bot";
		if ($cz) {
			$title = "Neprokoven?? zahlouben?? fr??zov??n?? z bot";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill ) {
		$title = "Non-plated milling before etching";
		if ($cz) {
			$title = "Neprokoven?? fr??zov??n?? p??ed lept??n??m";
		}

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillTop ) {
		$title = "Non-plated core milling from top";
		if ($cz) {
			$title = "Neprokoven?? hloubkov?? lept??n??m j??dra z top";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillBot ) {
		$title = "Non-plated core milling from bot";
		if ($cz) {
			$title = "Neprokoven?? hloubkov?? fr??zov??n?? j??dra z bot";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill ) {
		$title = "Milling of connector edge";
		if ($cz) {
			$title = "Fr??zov??n?? hrany konektoru";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score ) {
		$title = "V-scoring";
		if ($cz) {
			$title = "V-dr????ka";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill ) {
		$title = "Z-axis milling of TOP stiffener";
		if ($cz) {
			$title = "Zahlouben?? fr??zov??n?? top stiffeneru.";
		}
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffsMill ) {
		$title = "Z-axis milling of BOT stiffener";
		if ($cz) {
			$title = "Zahlouben?? fr??zov??n?? bot stiffeneru.";
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
				$info = "Power-ground zobrazena negativn??";
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
				$info = "Fr??zov??n?? je Pou????v??no pro dosa??en?? vysok?? kvality opracov??n??.";
			}
		}
 
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill ) {
			$info = "Milling is used before electrical testing";
			if ($cz) {
				$info = "Fr??zov??n?? p??ed elektrick??m testem pro korektn?? pr??b??h testu.";
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

