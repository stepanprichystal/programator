
#-------------------------------------------------------------------------------------------#
# Description: This class fill special template class
# Template class than contain all needed data, which are pasted to final PDF
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::StencilControlPdf::HtmlTemplate::FillTemplatePrevInfo;

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
use aliased 'Programs::Stencil::StencilCreator::Enums'           => 'StnclEnums';
use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper' => 'StnclHelper';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}  = shift;
	$self->{"jobId"}  = shift;
	$self->{"params"} = shift;    # Stencil parameters

	return $self;
}

sub FillKeysData {
	my $self      = shift;
	my $template  = shift;
	my $infoToPdf = shift;        # if put info about operator to pdf

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Load info about pcb

	my %inf = StnclHelper->GetStencilInfo( $self->{"jobId"} );

	my $custSetExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_set" );    # zakaznicke sady

	my %authorInf = $self->__GetEmployyInfo();

	#my $rsPath = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\HtmlTemplate\\Img\\redSquare.jpg";
	$template->SetKey( "ScriptsRoot", GeneralHelper->Root() );

	# =================== Table general information ============================
	$template->SetKey( "GeneralInformation", "General information", "Obecn?? informace" );

	$template->SetKey( "PcbDataName", "Stencil data name", "N??zev souboru" );
	$template->SetKey( "PcbDataNameVal", HegMethods->GetPcbName( $self->{"jobId"} ) );

	$template->SetKey( "Author", "Cam engineer", "Zpracoval" );
	$template->SetKey( "AuthorVal", $infoToPdf ? ( $authorInf{"jmeno"} . " " . $authorInf{"prijmeni"} ) : "-" );

	$template->SetKey( "PcbId", "Internal pcb Id", "Intern?? id" );
	$template->SetKey( "PcbIdVal", uc( $self->{"jobId"} ) );

	$template->SetKey( "Email", "Email" );
	$template->SetKey( "EmailVal", $infoToPdf ? ( $authorInf{"e_mail"} ) : "-" );

	$template->SetKey( "ReportGenerated", "Report date ", "Datum reportu" );

	$template->SetKey( "ReportGeneratedVal", strftime "%d/%m/%Y", localtime );

	$template->SetKey( "Phone", "Phone", "Telefon" );
	$template->SetKey( "PhoneVal", $infoToPdf ? ( $authorInf{"telefon_prace"} ) : "-" );

	# =================== Table Pcb parameters ============================

	$template->SetKey( "PcbParameters", "Stencil parameters", "Parametry ??ablony" );

	$template->SetKey( "Dimension", "Dimension", "Rozm??ry" );

	my $dim =
	    sprintf( "%0.1f mm", $self->{"params"}->GetStencilSizeX() ) . " x "
	  . sprintf( "%0.1f mm", $self->{"params"}->GetStencilSizeY() ) . " x "
	  . sprintf( "%0.3f mm", $self->{"params"}->GetThickness() );
	$template->SetKey( "DimensionVal", $dim );

	$template->SetKey( "PutIntoFrame", "Stick into frame", "Vlepit do r??mu" );

	my $frame = $self->{"params"}->GetSchema()->{"type"} eq StnclEnums->Schema_FRAME ? 1 : 0;
	$template->SetKey( "PutIntoFrameVal",
					   $frame ? "Yes, using squeegee from readable side" : "No",
					   $frame ? "Ano, pohyb st??rky z ??iteln?? strany"  : "Ne" );

	$template->SetKey( "Technology", "Technology", "Technologie" );

	my $techEn = "";
	my $techCz = "";

	if ( $inf{"tech"} eq StnclEnums->Technology_LASER ) {
		$techEn = "Laser";
		$techCz = "Laserov??";
	}
	elsif ( $inf{"tech"} eq StnclEnums->Technology_ETCH ) {
		$techEn = "Etching";
		$techCz = "Leptan??";
	}
	elsif ( $inf{"tech"} eq StnclEnums->Technology_DRILL ) {
		$techEn = "Drilling";
		$techCz = "Vrt??n??";
	}

	$template->SetKey( "TechnologyVal", $techEn, $techCz );

	$template->SetKey( "Fiducials", "Fiducial marks", "Fiduci??ln?? zna??ky" );

	my $fiducInf    = $self->{"params"}->GetFiducial();
	my $fiducTextEn = "";
	my $fiducTextCz = "";

	if ( $fiducInf->{"halfFiducials"} ) {

		my $readable = $fiducInf->{"fiducSide"} eq "readable" ? 1 : 0;

		if ( $inf{"tech"} eq StnclEnums->Technology_LASER ) {
			$fiducTextEn = "Half-lasered (from " .        ( $readable ? "readable"  : "nonreadable" ) . "	side)";
			$fiducTextCz = "Vyp??len?? do poloviny (z " . ( $readable ? "??iteln??" : "ne??iteln??" ) . " strany)";
		}
		elsif ( $inf{"tech"} eq StnclEnums->Technology_ETCH ) {
			$fiducTextEn = "Half-etched (from " .         ( $readable ? "readable"  : "nonreadable" ) . " side)";
			$fiducTextCz = "Vyleptan?? do poloviny (z " . ( $readable ? "??iteln??" : "ne??iteln??" ) . " strany)";
		}
	}
	else {
		$fiducTextEn = "No";
		$fiducTextCz = "Ne";
	}

	$template->SetKey( "FiducialsVal", $fiducTextEn, $fiducTextCz );

	$template->SetKey( "Type", "Type", "Type" );

	my $typeEn = "";
	my $typeCz = "";
	if ( $self->{"params"}->GetStencilType() eq StnclEnums->StencilType_TOP ) {
		$typeEn = "For TOP pcb side";
		$typeCz = "Pro vrchn?? TOP stranu dps";

	}
	elsif ( $self->{"params"}->GetStencilType() eq StnclEnums->StencilType_BOT ) {
		$typeEn = "For BOTTOM pcb side";
		$typeCz = "Pro spodn?? BOT stranu pcb ";
	}
	elsif ( $self->{"params"}->GetStencilType() eq StnclEnums->StencilType_TOPBOT ) {
		$typeEn = "For TOP+BOTTOM pcb side";
		$typeCz = "Pro vrchn?? TOP + spodn?? BOT stranu dps";
	}

	$template->SetKey( "TypeVal", $typeEn, $typeCz );

	$template->SetKey( "SourceType", "Data source", "Zdroj dat" );

	my $sourceTypeEn = "";
	my $sourceTypeCz = "";

	if ( $self->{"params"}->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_CUSTDATA ) {
		$sourceTypeEn = "Customer data";
		$sourceTypeCz = "Dod??no z??kazn??kem";

	}
	elsif ( $self->{"params"}->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_JOB ) {
		$sourceTypeEn =
		    "Order - "
		  . $self->{"params"}->GetDataSource()->{"sourceJob"}
		  . ( $self->{"params"}->GetDataSource()->{"sourceJobIsPool"} ? " (POOL)" : "" );
		$sourceTypeCz =
		    "Zak??zka - "
		  . $self->{"params"}->GetDataSource()->{"sourceJob"}
		  . ( $self->{"params"}->GetDataSource()->{"sourceJobIsPool"} ? " (POOL)" : "" );
	}

	$template->SetKey( "SourceTypeVal", $sourceTypeEn, $sourceTypeCz );

	return 1;
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
