
#-------------------------------------------------------------------------------------------#
# Description: This class fill special template class
# Template class than contain all needed data, which are pasted to final PDF
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::HtmlTemplate::FillTemplatePrevInfo;

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
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::CAMJob::OutputData::Helper' => 'OutDataHelper';

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

# Set keys regarding html temlate content
sub FillKeysData {
	my $self           = shift;
	my $template       = shift;
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
	$template->SetKey( "AuthorVal", $infoToPdf ? ( $authorInf{"jmeno"} . " " . $authorInf{"prijmeni"} ) : "-" );

	$template->SetKey( "PcbId", "Internal pcb Id", "Interní id" );
	$template->SetKey( "PcbIdVal", uc( $self->{"jobId"} ) );

	$template->SetKey( "Email", "Email" );
	$template->SetKey( "EmailVal", $infoToPdf ? ( $authorInf{"e_mail"} ) : "-" );

	$template->SetKey( "ReportGenerated", "Report date ", "Datum reportu" );

	$template->SetKey( "ReportGeneratedVal", strftime "%d/%m/%Y", localtime );

	$template->SetKey( "Phone", "Phone", "Telefon" );
	$template->SetKey( "PhoneVal", $infoToPdf ? ( $authorInf{"telefon_prace"} ) : "-" );

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
	my $silkTopValCz = Translator->Cz( $pcbInfo{"potisk_c_1"} );

	if ( CamHelper->LayerExists( $inCAM, $jobId, "pc2" ) ) {
		$silkTopValEn .= " + " . $pcbInfo{"potisk_c_2"} . " (top silkscreen)";
		$silkTopValCz .= " + " . Translator->Cz( $pcbInfo{"potisk_c_2"} ) . " (vrchní potisk)";
	}

	$template->SetKey( "SilkTopVal", $silkTopValEn, $silkTopValCz );

	$template->SetKey( "PanelSize", "Panel size", "Rozměr panelu" );

	$template->SetKey( "PanelSizeVal", $pcbInfo{"panel"} );

	$template->SetKey( "SilkBot", "Silkscreen bot", "Potisk bot" );

	my $silkBotValEn = $pcbInfo{"potisk_s_1"};
	my $silkBotValCz = Translator->Cz( $pcbInfo{"potisk_s_1"} );

	if ( CamHelper->LayerExists( $inCAM, $jobId, "ps2" ) ) {
		$silkBotValEn .= " + " . $pcbInfo{"potisk_s_2"} . " (top silkscreen)";
		$silkBotValCz .= " + " . Translator->Cz( $pcbInfo{"potisk_s_2"} ) . " (vrchní potisk)";
	}

	$template->SetKey( "SilkBotVal", $silkBotValEn, $silkBotValCz );

	$template->SetKey( "PcbThickness", "Material thickness", "Tloušťka materiálu" );

	$template->SetKey( "PcbThicknessVal", $stackupInf{"thick"} );

	$template->SetKey( "MaskTop", "Solder mask top", "Maska top" );

	my $maskTopValEn = $pcbInfo{"maska_c_1"};
	my $maskTopValCz = Translator->Cz( $pcbInfo{"maska_c_1"} );

	# Second masks are not sotred in nif file only in IS so check IS
	my %masks2 = HegMethods->GetSolderMaskColor2($jobId);
	if ( defined $masks2{"top"} && $masks2{"top"} ne "" ) {
		$maskTopValEn .= " + " . ValueConvertor->GetMaskCodeToColor( $masks2{"top"} ) . " (top solder mask)";
		$maskTopValCz .= " + " . Translator->Cz( ValueConvertor->GetMaskCodeToColor( $masks2{"top"} ) ) . " (vrchní maska)";
	}

	$template->SetKey( "MaskTopVal", $maskTopValEn, $maskTopValCz );

	$template->SetKey( "LayerNumber", "Number of layers", "Počet vrstev" );
	my $sigLayerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	$sigLayerCnt = 0 if ( $pcbType eq EnumsGeneral->PcbType_NOCOPPER );    # There are one signal layers in matrix
	$sigLayerCnt = 1 if ( $pcbType eq EnumsGeneral->PcbType_1VFLEX );      # There are two signal layers in matrix

	$template->SetKey( "LayerNumberVal", $sigLayerCnt );

	$template->SetKey( "MaskBot", "Solder mask bot", "Maska bot" );

	my $maskBotValEn = $pcbInfo{"maska_s_1"};
	my $maskBotValCz = Translator->Cz( $pcbInfo{"maska_s_1"} );

	# Second masks are not sotred in nif file only in IS so check IS
	if ( defined $masks2{"bot"} && $masks2{"bot"} ne "" ) {
		$maskBotValEn .= " + " . ValueConvertor->GetMaskCodeToColor( $masks2{"bot2"} ) . " (top solder mask)";
		$maskBotValCz .= " + " . Translator->Cz( ValueConvertor->GetMaskCodeToColor( $masks2{"bot"} ) ) . " (vrchní maska)";
	}

	$template->SetKey( "MaskBotVal", $maskBotValEn, $maskBotValCz );

	#	$template->SetKey( "CoverlayTopDisp",    "display:none" );
	#	$template->SetKey( "CoverlayTopValDisp", "display:none" );
	#	$template->SetKey( "CoverlayBotDisp",    "display:none" );
	#	$template->SetKey( "CoverlayBotValDisp", "display:none" );
	#
	#	$template->SetKey( "FlexMaskTopDisp",    "display:none" );
	#	$template->SetKey( "FlexMaskTopValDisp", "display:none" );
	#	$template->SetKey( "FlexMaskBotDisp",    "display:none" );
	#	$template->SetKey( "FlexMaskBotValDisp", "display:none" );
	#
	#	$template->SetKey( "StiffenerDisp",    "display:none" );
	#	$template->SetKey( "StiffenerValDisp", "display:none" );

	$template->SetKey( "CoverlayTop", "Coverlay top", "Coverlay top" );
	my $cvrTopEn = join( "; ", map { OutDataHelper->GetJobLayerTitle( { "gROWname" => $_ } ) } @{ $pcbInfo{"coverlayTop"} } );
	my $cvrTopCz = join( "; ", map { OutDataHelper->GetJobLayerTitle( { "gROWname" => $_ }, undef, 1 ) } @{ $pcbInfo{"coverlayTop"} } );
	$template->SetKey( "CoverlayTopVal", $cvrTopEn, $cvrTopCz );

	$template->SetKey( "CoverlayBot", "Coverlay bot", "Coverlay bot" );
	my $cvrBotEn = join( "; ", map { OutDataHelper->GetJobLayerTitle( { "gROWname" => $_ } ) } @{ $pcbInfo{"coverlayBot"} } );
	my $cvrBotCz =
	  join( "; ", map { OutDataHelper->GetJobLayerTitle( { "gROWname" => $_ }, undef, 1 ) } @{ $pcbInfo{"coverlayBot"} } );
	$template->SetKey( "CoverlayBotVal", $cvrBotEn, $cvrBotCz );

	$template->SetKey( "FlexMaskTop", "Flexible mask top", "Flexibilní maska top" );
	$template->SetKey( "FlexMaskTopVal",
					   ( $pcbInfo{"flexMaskTop"} ? "Screen printed green" : "" ),
					   ( $pcbInfo{"flexMaskTop"} ? "Sítosik zelená"     : "" ) );

	$template->SetKey( "FlexMaskBot", "Flexible mask bot", "Flexibilní maska bot" );
	$template->SetKey( "FlexMaskBotVal",
					   ( $pcbInfo{"flexMaskBot"} ? "Screen printed green" : "" ),
					   ( $pcbInfo{"flexMaskBot"} ? "Sítosik zelená"     : "" ) );

	$template->SetKey( "Stiffener", "Stiffener", "Výztuž" );
	my $stiffEn = join( "; ", map { OutDataHelper->GetJobLayerTitle( { "gROWname" => $_ } ) } @{ $pcbInfo{"stiffener"} } );
	my $stiffCz = join( "; ", map { OutDataHelper->GetJobLayerTitle( { "gROWname" => $_ }, undef, 1 ) } @{ $pcbInfo{"stiffener"} } );
	$template->SetKey( "StiffenerVal", $stiffEn, $stiffCz );

	# =================== Table Markings ============================

	$template->SetKey( "Markings", "Added markings", "Přidané značení" );

	$template->SetKey( "UlLogo", "Ul logo" );
	$template->SetKey( "UlLogoVal", $pcbInfo{"ul_logo"}, Translator->Cz( $pcbInfo{"ul_logo"} ) );

	$template->SetKey( "DataCode",    "Data code",          "Datum" );
	$template->SetKey( "DataCodeVal", $pcbInfo{"datacode"}, Translator->Cz( $pcbInfo{"datacode"} ) );

 

	return 1;
}

# Set keys regarding html layout desing
sub FillKeysLayout {
	my $self     = shift;
	my $template = shift;

	# Default se visibility none
	$template->SetKey( "CoverlayTopDisp",    "display:none" );
	$template->SetKey( "CoverlayTopValDisp", "display:none" );
	$template->SetKey( "CoverlayBotDisp",    "display:none" );
	$template->SetKey( "CoverlayBotValDisp", "display:none" );

	$template->SetKey( "FlexMaskTopDisp",    "display:none" );
	$template->SetKey( "FlexMaskTopValDisp", "display:none" );
	$template->SetKey( "FlexMaskBotDisp",    "display:none" );
	$template->SetKey( "FlexMaskBotValDisp", "display:none" );

	$template->SetKey( "StiffenerDisp",    "display:none" );
	$template->SetKey( "StiffenerValDisp", "display:none" );

	$template->SetKey( "FlexSurfTopDisp", "display:none" );
	$template->SetKey( "FlexSurfBotDisp", "display:none" );

	my $pcbType = JobHelper->GetPcbType( $self->{"jobId"} );

	# Set visibility of coverlay cells
	if (    $pcbType eq EnumsGeneral->PcbType_1VFLEX
		 || $pcbType eq EnumsGeneral->PcbType_2VFLEX
		 || $pcbType eq EnumsGeneral->PcbType_MULTIFLEX
		 || $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO
		 || $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI )
	{

		$template->SetKey( "CoverlayTopDisp",    "display:block" );
		$template->SetKey( "CoverlayTopValDisp", "display:block" );
		$template->SetKey( "CoverlayBotDisp",    "display:block" );
		$template->SetKey( "CoverlayBotValDisp", "display:block" );
		$template->SetKey( "FlexSurfTopDisp",    "display:block" );
		$template->SetKey( "FlexSurfBotDisp",    "display:block" );

	}

	# Set visibility of flexible mask cells
	if (    $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO
		 || $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI )
	{
		$template->SetKey( "FlexMaskTopDisp",    "display:block" );
		$template->SetKey( "FlexMaskTopValDisp", "display:block" );
		$template->SetKey( "FlexMaskBotDisp",    "display:block" );
		$template->SetKey( "FlexMaskBotValDisp", "display:block" );
		$template->SetKey( "FlexSurfTopDisp",    "display:block" );
		$template->SetKey( "FlexSurfBotDisp",    "display:block" );
	}

	# Set visibility of stiffener mask cells
	if (    $pcbType eq EnumsGeneral->PcbType_1VFLEX
		 || $pcbType eq EnumsGeneral->PcbType_2VFLEX
		 || $pcbType eq EnumsGeneral->PcbType_MULTIFLEX )
	{
		$template->SetKey( "StiffenerDisp",    "display:block" );
		$template->SetKey( "StiffenerValDisp", "display:block" );
	}

}

# Return hash with pcb info from nif file
sub __GetPcbInfo {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %inf = ();

	my $nifFile = NifFile->new( $self->{"jobId"} );

	unless ( $nifFile->Exist() ) {

		return %inf;
	}

	$inf{"potisk_c_1"} = ValueConvertor->GetSilkCodeToColor( $nifFile->GetValue("potisk_c_1") );
	$inf{"potisk_s_1"} = ValueConvertor->GetSilkCodeToColor( $nifFile->GetValue("potisk_s_1") );
	$inf{"potisk_c_2"} = ValueConvertor->GetSilkCodeToColor( $nifFile->GetValue("potisk_c_2") );
	$inf{"potisk_s_2"} = ValueConvertor->GetSilkCodeToColor( $nifFile->GetValue("potisk_s_2") );
	$inf{"maska_c_1"}  = ValueConvertor->GetMaskCodeToColor( $nifFile->GetValue("maska_c_1") );
	$inf{"maska_s_1"}  = ValueConvertor->GetMaskCodeToColor( $nifFile->GetValue("maska_s_1") );

	my @boardBase = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	# Fillcoverlay

	my @coversTop = ();
	my @coversBot = ();
	foreach my $l ( grep { $_->{"gROWlayer_type"} eq "coverlay" } @boardBase ) {

		my $sigLayer = "";
		if ( CamMatrix->GetNonSignalLayerSide( $inCAM, $jobId, $l->{"gROWname"}, undef, \$sigLayer ) eq "top" ) {
			push( @coversTop, $sigLayer );
		}
		else {
			push( @coversBot, $sigLayer );
		}
	}

	$inf{"coverlayTop"} = \@coversTop;
	$inf{"coverlayBot"} = \@coversBot;

	# Flex mask

	$inf{"flexMaskTop"} = scalar( grep { $_->{"gROWname"} eq "mcflex" } @boardBase ) ? 1 : 0;
	$inf{"flexMaskBot"} = scalar( grep { $_->{"gROWname"} eq "msflex" } @boardBase ) ? 1 : 0;

	# Stiffener

	my @stiffener = ();

	foreach my $l ( grep { $_->{"gROWlayer_type"} eq "stiffener" } @boardBase ) {

		push( @stiffener, ( $l->{"gROWname"} =~ /^\w+([csv]\d*)$/ )[0] );
	}

	$inf{"stiffener"} = \@stiffener;

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
		my $stackup = Stackup->new( $self->{"inCAM"}, $self->{"jobId"} );
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
