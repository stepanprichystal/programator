
#-------------------------------------------------------------------------------------------#
# Description: This class fill special template class
# Template class than contain all needed data, which are pasted to final PDF
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::FillTemplate;

#3th party library
use utf8;

use strict;
use warnings;

use POSIX qw(strftime);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::NifFile::NifFile';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::ValueConvertor';
use aliased 'Helpers::Translator';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	

	return $self;
}

sub Fill {
	my $self           = shift;
	my $template       = shift;
	my $stackupPath    = shift;
	my $previewTopPath = shift;
	my $previewBotPath = shift;
	my $infoToPdf      = shift;    # if put info about operator to pdf

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Load info about pcb

	my $pcbType = HegMethods->GetTypeOfPcb($jobId);
	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	if ( $pcbType eq "Neplatovany" ) {

		$layerCnt = 0;
	}

	my $custSetExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_set" );    # zakaznicke sady

	my %authorInf  = $self->__GetEmployyInfo();
	my %pcbInfo    = $self->__GetPcbInfo();
	my %stackupInf = $self->__GetStackupInfo($layerCnt);

	#my $rsPath = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\HtmlTemplate\\Img\\redSquare.jpg";
	$template->SetKey( "ScriptsRoot", GeneralHelper->Root() );

	# =================== Table general information ============================
	$template->SetKey( "GeneralInformation", "General information", "Obecné informace" );

	$template->SetKey( "PcbDataName", "Pcb data name", "Název souboru" );
	$template->SetKey( "PcbDataNameVal", HegMethods->GetPcbName( $self->{"jobId"} ) );

	$template->SetKey( "Author", "Cam engineer", "Zpracoval" );
	$template->SetKey( "AuthorVal", $infoToPdf ? ($authorInf{"jmeno"} . " " . $authorInf{"prijmeni"}) : "-" );

	$template->SetKey( "PcbId", "Internal pcb Id", "Interní id" );
	$template->SetKey( "PcbIdVal", uc( $self->{"jobId"} ) );

	$template->SetKey( "Email",    "Email" );
	$template->SetKey( "EmailVal", $infoToPdf ? ($authorInf{"e_mail"}) : "-" );

	$template->SetKey( "ReportGenerated", "Report date ", "Datum reportu" );

	$template->SetKey( "ReportGeneratedVal", strftime "%d/%m/%Y", localtime );

	$template->SetKey( "Phone", "Phone", "Telefon" );
	$template->SetKey( "PhoneVal", $infoToPdf ? ($authorInf{"telefon_prace"}) : "-" );

	# =================== Table Pcb parameters ============================

	$template->SetKey( "PcbParameters", "Pcb parameters", "Parametry dps" );

	if ( $custSetExist eq "yes" ) {
		$template->SetKey( "SingleSize", "Set size", "Rozměr sady" );
	}
	else {
		$template->SetKey( "SingleSize", "Single size", "Rozměr kusu" );
	}

	$template->SetKey( "SingleSizeVal", $pcbInfo{"single"} );

	$template->SetKey( "SilkTop", "Silkscreen top", "Potisk top" );
	
	my $silkTopValEn = $pcbInfo{"potisk_c_1"};
	my $silkTopValCz = Translator->Cz($pcbInfo{"potisk_c_1"});
		
	if(CamHelper->LayerExists($inCAM, $jobId, "pc2")){
		$silkTopValEn .= " + ".$pcbInfo{"potisk_c_2"}. " (top silkscreen)";
		$silkTopValCz .= " + ".Translator->Cz($pcbInfo{"potisk_c_2"}). " (vrchní potisk)";
	}
	
	$template->SetKey( "SilkTopVal", $silkTopValEn, $silkTopValCz );


	$template->SetKey( "PanelSize", "Panel size", "Rozměr panelu" );

	$template->SetKey( "PanelSizeVal", $pcbInfo{"panel"} );

	$template->SetKey( "SilkBot", "Silkscreen bot", "Potisk bot" );
	
	my $silkBotValEn = $pcbInfo{"potisk_s_1"};
	my $silkBotValCz = Translator->Cz($pcbInfo{"potisk_s_1"});
	
	if(CamHelper->LayerExists($inCAM, $jobId, "ps2")){
		$silkBotValEn .= " + ".$pcbInfo{"potisk_s_2"}. " (top silkscreen)";
		$silkBotValCz .= " + ".Translator->Cz($pcbInfo{"potisk_s_2"}). " (vrchní potisk)";
	}
	
	$template->SetKey( "SilkBotVal", $silkBotValEn, $silkBotValCz );

	$template->SetKey( "PcbThickness", "Material thickness", "Tloušťka materiálu" );

	$template->SetKey( "PcbThicknessVal", $stackupInf{"thick"} );

	$template->SetKey( "MaskTop",    "Solder mask top",         "Maska top" );
	
	my $maskTopValEn = $pcbInfo{"maska_c_1"};
	my $maskTopValCz = Translator->Cz($pcbInfo{"maska_c_1"});
 
 	# Second masks are not sotred in nif file only in IS so check IS
 	my %masks2 = HegMethods->GetSolderMaskColor2($jobId);
 	if(defined $masks2{"top"} && $masks2{"top"} ne ""){
		$maskTopValEn .= " + ".ValueConvertor->GetMaskCodeToColor($masks2{"top"}). " (top solder mask)";
		$maskTopValCz .= " + ".Translator->Cz(ValueConvertor->GetMaskCodeToColor($masks2{"top"})). " (vrchní maska)";
	}
 
	$template->SetKey( "MaskTopVal", $maskTopValEn, $maskTopValCz );

	$template->SetKey( "LayerNumber", "Number of layers", "Počet vrstev" );
	$template->SetKey( "LayerNumberVal", $layerCnt );

	$template->SetKey( "MaskBot",    "Solder mask bot",         "Maska bot" );
	
	my $maskBotValEn = $pcbInfo{"maska_s_1"};
	my $maskBotValCz = Translator->Cz($pcbInfo{"maska_s_1"});
 
 	# Second masks are not sotred in nif file only in IS so check IS
 	if(defined $masks2{"bot"} && $masks2{"bot"} ne ""){
		$maskBotValEn .= " + ".ValueConvertor->GetMaskCodeToColor($masks2{"bot2"}). " (top solder mask)";
		$maskBotValCz .= " + ".Translator->Cz(ValueConvertor->GetMaskCodeToColor($masks2{"bot"})). " (vrchní maska)";
	}	
	
	
	$template->SetKey( "MaskBotVal", $maskBotValEn, $maskBotValCz );

	# =================== Table Markings ============================

	$template->SetKey( "Markings", "Added markings", "Přidané značení" );

	$template->SetKey( "UlLogo", "Ul logo" );
	$template->SetKey( "UlLogoVal", $pcbInfo{"ul_logo"}, Translator->Cz( $pcbInfo{"ul_logo"} ) );

	$template->SetKey( "DataCode",    "Data code",          "Datum" );
	$template->SetKey( "DataCodeVal", $pcbInfo{"datacode"}, Translator->Cz( $pcbInfo{"datacode"} ) );

	# =================== Table stackup ============================

	$template->SetKey( "Stackup", "Stackup", "Složení" );

	$template->SetKey( "MaterialQuality", "Material quality", "Druh materiálu" );
	$template->SetKey( "MaterialQualityVal", $stackupInf{"material"} );

	$template->SetKey( "PcbThickness", "Material thickness", "Tloušťka materiálu" );
	$template->SetKey( "PcbThicknessVal", $stackupInf{"thick"} );

	$template->SetKey( "PreviewStackup", $stackupPath );

	# =================== Table views ============================

	$template->SetKey( "TopView", "Top view", "Pohled top" );
	$template->SetKey( "TopViewImg", $previewTopPath );

	$template->SetKey( "BotView", "Bot view", "Pohled bot" );
	$template->SetKey( "BotViewImg", $previewBotPath );

	return 1;
}

# Return hash with pcb info from nif file
sub __GetPcbInfo {
	my $self = shift;

	my %inf = ();

	my $nifFile = NifFile->new( $self->{"jobId"} );

	unless ( $nifFile->Exist() ) {

		return %inf;
	}

	$inf{"potisk_c_1"} = ValueConvertor->GetSilkCodeToColor( $nifFile->GetValue("potisk_c_1") );
	$inf{"potisk_s_1"} = ValueConvertor->GetSilkCodeToColor( $nifFile->GetValue("potisk_s_1") );
	$inf{"potisk_c_2"} = ValueConvertor->GetSilkCodeToColor( $nifFile->GetValue("potisk_c_2") );
	$inf{"potisk_s_2"} = ValueConvertor->GetSilkCodeToColor( $nifFile->GetValue("potisk_s_2") );
	$inf{"maska_c_1"}        = ValueConvertor->GetMaskCodeToColor( $nifFile->GetValue("maska_c_1") );
	$inf{"maska_s_1"}        = ValueConvertor->GetMaskCodeToColor( $nifFile->GetValue("maska_s_1") );

	$inf{"single"} = $nifFile->GetValue("single_x") . " mm x " . $nifFile->GetValue("single_y") . " mm";

	my $panelSize = "";
	if ( !defined $nifFile->GetValue("panel_x") || $nifFile->GetValue("panel_x") eq "" ) {

		$inf{"panel"} = " - ";
	}
	else {

		$inf{"panel"} = $nifFile->GetValue("panel_x") . " mm x " . $nifFile->GetValue("panel_y") . " mm";
	}

	$inf{"datacode"} = ValueConvertor->GetNifCodeValue( $nifFile->GetValue("datacode") );
	$inf{"ul_logo"}  = ValueConvertor->GetNifCodeValue( $nifFile->GetValue("ul_logo") );

	return %inf;

}

sub __GetStackupInfo {
	my $self     = shift;
	my $layerCnt = shift;

	my %inf = ();

	# get info from norris
	if ( $layerCnt <= 2 ) {

		$inf{"thick"} = sprintf( "%.2f mm", HegMethods->GetPcbMaterialThick( $self->{"jobId"} ) );
	}
	else {

		#get info from stackup
		my $stackup = Stackup->new( $self->{"jobId"} );
		$inf{"thick"} = sprintf( "%.2f mm", $stackup->GetFinalThick() / 1000 );
	}

	$inf{"material"} = HegMethods->GetMaterialKind( $self->{"jobId"}, 1 );

	return %inf;

}

sub __GetEmployyInfo {
	my $self = shift;

	my $name = CamAttributes->GetJobAttrByName( $self->{"inCAM"}, $self->{"jobId"}, "user_name" );

	my %employyInf = ();

	if ( defined $name && $name ne "" ) {

		%employyInf = %{ HegMethods->GetEmployyInfo($name) }

	}

	return %employyInf;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
