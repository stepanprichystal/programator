
#-------------------------------------------------------------------------------------------#
# Description: This class fill special template class
# Template class than contain all needed data, which are pasted to final PDF
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::FillTemplate;

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

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"nifFile"} = NifFile->new( $self->{"jobId"} );

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
	my %nifFile    = $self->__GetNifFileInfo();
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

	$template->SetKey( "SingleSizeVal", $nifFile{"single"} );

	$template->SetKey( "SilkTop", "Silkscreen top", "Potisk top" );
	$template->SetKey( "SilkTopVal", $nifFile{"c_silk_screen_colour"}, Translator->Cz( $nifFile{"c_silk_screen_colour"} ) );

	$template->SetKey( "PanelSize", "Panel size", "Rozměr panelu" );

	$template->SetKey( "PanelSizeVal", $nifFile{"panel"} );

	$template->SetKey( "SilkBot", "Silkscreen bot", "Potisk bot" );
	$template->SetKey( "SilkBotVal", $nifFile{"s_silk_screen_colour"}, Translator->Cz( $nifFile{"s_silk_screen_colour"} ) );

	$template->SetKey( "PcbThickness", "Material thickness", "Tloušťka materiálu" );

	$template->SetKey( "PcbThicknessVal", $stackupInf{"thick"} );

	$template->SetKey( "MaskTop",    "Solder mask top",         "Maska top" );
	$template->SetKey( "MaskTopVal", $nifFile{"c_mask_colour"}, Translator->Cz( $nifFile{"c_mask_colour"} ) );

	$template->SetKey( "LayerNumber", "Number of layers", "Počet vrstev" );
	$template->SetKey( "LayerNumberVal", $layerCnt );

	$template->SetKey( "MaskBot",    "Solder mask bot",         "Maska bot" );
	$template->SetKey( "MaskBotVal", $nifFile{"s_mask_colour"}, Translator->Cz( $nifFile{"s_mask_colour"} ) );

	# =================== Table Markings ============================

	$template->SetKey( "Markings", "Added markings", "Přidané značení" );

	$template->SetKey( "UlLogo", "Ul logo" );
	$template->SetKey( "UlLogoVal", $nifFile{"ul_logo"}, Translator->Cz( $nifFile{"ul_logo"} ) );

	$template->SetKey( "DataCode",    "Data code",          "Datum" );
	$template->SetKey( "DataCodeVal", $nifFile{"datacode"}, Translator->Cz( $nifFile{"datacode"} ) );

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

sub __GetNifFileInfo {
	my $self = shift;

	my %inf = ();

	unless ( $self->{"nifFile"}->Exist() ) {

		return %inf;
	}

	$inf{"c_silk_screen_colour"} = ValueConvertor->GetSilkCodeToColor( $self->{"nifFile"}->GetValue("c_silk_screen_colour") );
	$inf{"s_silk_screen_colour"} = ValueConvertor->GetSilkCodeToColor( $self->{"nifFile"}->GetValue("s_silk_screen_colour") );
	$inf{"c_mask_colour"}        = ValueConvertor->GetMaskCodeToColor( $self->{"nifFile"}->GetValue("c_mask_colour") );
	$inf{"s_mask_colour"}        = ValueConvertor->GetMaskCodeToColor( $self->{"nifFile"}->GetValue("s_mask_colour") );

	$inf{"single"} = $self->{"nifFile"}->GetValue("single_x") . " mm x " . $self->{"nifFile"}->GetValue("single_y") . " mm";

	my $panelSize = "";
	if ( !defined $self->{"nifFile"}->GetValue("panel_x") || $self->{"nifFile"}->GetValue("panel_x") eq "" ) {

		$inf{"panel"} = " - ";
	}
	else {

		$inf{"panel"} = $self->{"nifFile"}->GetValue("panel_x") . " mm x " . $self->{"nifFile"}->GetValue("panel_y") . " mm";
	}

	$inf{"datacode"} = ValueConvertor->GetNifCodeValue( $self->{"nifFile"}->GetValue("datacode") );
	$inf{"ul_logo"}  = ValueConvertor->GetNifCodeValue( $self->{"nifFile"}->GetValue("ul_logo") );

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
