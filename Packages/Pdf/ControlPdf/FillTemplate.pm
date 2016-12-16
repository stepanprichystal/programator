
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
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

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $pcbType = HegMethods->GetTypeOfPcb($jobId);
	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	if ( $pcbType eq "Neplatovany" ) {

		$layerCnt = 0;
	}

	my %authorInf  = $self->__GetAuthorInfo();
	my %nifFile    = $self->__GetNifFileInfo();
	my %stackupInf = $self->__GetStackupInfo($layerCnt);

	my $rsPath = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\HtmlTemplate\\Img\\redSquare.jpg";
	$template->SetKey( "RedSquare", $rsPath );

	# =================== Table general information ============================
	$template->SetKey( "GeneralInformation", "General information", "Obecné informace" );

	$template->SetKey( "PcbDataName", "Pcb data name", "Název souboru" );
	$template->SetKey( "PcbDataNameVal", HegMethods->GetPcbName( $self->{"jobId"} ) );

	$template->SetKey( "Author", "Cam engineer", "Zpracoval" );
	$template->SetKey( "AuthorVal", $authorInf{"name"} );

	$template->SetKey( "PcbId", "Internal pcb Id", "Interní id" );
	$template->SetKey( "PcbIdVal", $self->{"jobId"} );

	$template->SetKey( "Email",    "Email" );
	$template->SetKey( "EmailVal", $authorInf{"email"} );

	$template->SetKey( "ReportGenerated", "Report date ", "Datum reportu" );

	$template->SetKey( "ReportGeneratedVal", strftime "%d/%m/%Y", localtime );

	$template->SetKey( "Phone", "Phone", "Telefon" );
	$template->SetKey( "PhoneVal", $authorInf{"phone"} );

	# =================== Table Pcb parameters ============================

	$template->SetKey( "PcbParameters", "Pcb parameters", "Parametry dps" );

	$template->SetKey( "SingleSize", "Single size", "Rozměr kusu" );
	$template->SetKey( "SingleSizeVal", $nifFile{"single"});

	$template->SetKey( "SilkTop", "Silkscreen top", "Potisk top" );
	$template->SetKey( "SilkTopVal", $nifFile{"c_silk_screen_colour"}, Translator->Cz( $nifFile{"c_silk_screen_colour"} ) );

	$template->SetKey( "PanelSize", "Panel size", "Rozměr panelu" );

	$template->SetKey( "PanelSizeVal", $nifFile{"panel"});

	$template->SetKey( "SilkBot", "Silkscreen bot", "Potisk bot" );
	$template->SetKey( "SilkBotVal", $nifFile{"s_silk_screen_colour"}, Translator->Cz( $nifFile{"s_silk_screen_colour"} ) );

	$template->SetKey( "PcbThickness", "Pcb thickness", "Tloušťka dps" );

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

	$template->SetKey( "PcbThickness", "Total thickness", "Celková tloušťka" );
	$template->SetKey( "PcbThicknessVal", $stackupInf{"thick"} );

	$template->SetKey( "PreviewStackup", $stackupPath );

	# =================== Table views ============================

	$template->SetKey( "TopView", "Top view", "Pohled top" );
	$template->SetKey( "TopViewImg", $previewTopPath );

	$template->SetKey( "BotView", "Bot view", "Pohled bot" );
	$template->SetKey( "BotViewImg", $previewBotPath );

	return 1;
}

sub __GetAuthorInfo {
	my $self = shift;

	my %inf = ();

	$inf{"phone"} = "777 888 555";
	$inf{"email"} = "stepan.prichzstal mail.oo";
	$inf{"name"}  = "Štěpán Přichystal";

	return %inf;

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

	 
	$inf{"single"} = $inf{"single_x"} . "mm x " . $inf{"single_y"} . "mm";

	my $panelSize = "";
	if ( !defined $inf{"panel_x"} || $inf{"panel_x"} eq "" ) {

		$inf{"panel"} = " - ";
	}
	else {

		$inf{"panel"} = $inf{"panel_x"} . "mm x " . $inf{"panel_y"} . "mm";
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

		$inf{"thick"} = sprintf( "%.2f mm", $self->{"nifFile"}->GetValue("c_silk_screen_colour") );
		$inf{"material"} = $self->{"nifFile"}->GetValue("s_silk_screen_colour");

	}
	else {

		#get info from stackup
		my $stackup = Stackup->new( $self->{"jobId"} );
		$inf{"thick"} = sprintf( "%.2f mm", $stackup->GetFinalThick() / 1000 );
		$inf{"material"} = $stackup->GetStackupType();
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
