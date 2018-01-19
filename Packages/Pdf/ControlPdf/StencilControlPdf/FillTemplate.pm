
#-------------------------------------------------------------------------------------------#
# Description: This class fill special template class
# Template class than contain all needed data, which are pasted to final PDF
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::StencilControlPdf::FillTemplate;

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
use aliased 'Programs::Stencil::StencilSerializer::StencilSerializer';
use aliased 'Programs::Stencil::StencilCreator::Enums'           => 'StnclEnums';
use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper' => 'StnclHelper';

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
	my $previewTopPath = shift;
	my $infoToPdf      = shift;    # if put info about operator to pdf

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Load info about pcb

	my $ser    = StencilSerializer->new( $self->{"jobId"} );
	my $params = $ser->LoadStenciLParams();
	my %inf    = StnclHelper->GetStencilInfo( $self->{"jobId"} );

	my $custSetExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, "customer_set" );    # zakaznicke sady

	my %authorInf = $self->__GetEmployyInfo();

	#my $rsPath = GeneralHelper->Root() . "\\Packages\\Pdf\\ControlPdf\\HtmlTemplate\\Img\\redSquare.jpg";
	$template->SetKey( "ScriptsRoot", GeneralHelper->Root() );

	# =================== Table general information ============================
	$template->SetKey( "GeneralInformation", "General information", "Obecné informace" );

	$template->SetKey( "PcbDataName", "Stencil data name", "Název souboru" );
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

	$template->SetKey( "PcbParameters", "Stencil parameters", "Parametry šablony" );

	$template->SetKey( "Dimension", "Dimension", "Rozměry" );

	my $dim =
	    sprintf( "%0.1f mm", $params->GetStencilSizeX() ) . " x "
	  . sprintf( "%0.1f mm", $params->GetStencilSizeY() ) . " x "
	  . sprintf( "%0.3f mm", $params->GetThickness() );
	$template->SetKey( "DimensionVal", $dim );

	$template->SetKey( "PutIntoFrame", "Stick into frame", "Vlepit do rámu" );

	my $frame = $params->GetSchema()->{"type"} eq StnclEnums->Schema_FRAME ? 1 : 0;
	$template->SetKey( "PutIntoFrameVal", $frame ? "Yes, using squeegee from readable side" : "No", $frame ? "Ano, pohyb stěrky z čitelné strany" : "Ne" );

	$template->SetKey( "Technology", "Technology", "Technologie" );

	my $techEn = "";
	my $techCz = "";

	if ( $inf{"tech"} eq StnclEnums->Technology_LASER ) {
		$techEn = "Laser";
		$techCz = "Laserová";
	}
	elsif ( $inf{"tech"} eq StnclEnums->Technology_ETCH ) {
		$techEn = "Etching";
		$techCz = "Leptaná";
	}
	elsif ( $inf{"tech"} eq StnclEnums->Technology_DRILL ) {
		$techEn = "Drilling";
		$techCz = "Vrtání";
	}

	$template->SetKey( "TechnologyVal", $techEn, $techCz );

	$template->SetKey( "Fiducials", "Fiducial marks", "Fiduciální značky" );

	my $fiducInf    = $params->GetFiducial();
	my $fiducTextEn = "";
	my $fiducTextCz = "";

	if ( $fiducInf->{"halfFiducials"} ) {
		
		my $readable = $fiducInf->{"fiducSide"} eq "readable" ? 1:0;
 
		if ( $inf{"tech"} eq StnclEnums->Technology_LASER ) {
			$fiducTextEn = "Half-lasered (from ".($readable? "readable" : "nonreadable")."	side)";
			$fiducTextCz = "Vypálené do poloviny (z ".($readable? "čitelné" : "nečitelné")." strany)";
		}
		elsif ( $inf{"tech"} eq StnclEnums->Technology_ETCH ) {
			$fiducTextEn = "Half-etched (from ".($readable? "readable" : "nonreadable")." side)";
			$fiducTextCz = "Vyleptané do poloviny (z ".($readable? "čitelné" : "nečitelné")." strany)";
		}
	}
	else {
		$fiducTextEn = "No";
		$fiducTextCz = "Ne";
	}

	$template->SetKey( "FiducialsVal",$fiducTextEn, $fiducTextCz );

	$template->SetKey( "Type", "Type", "Type" );
	
	my $typeEn = "";
	my $typeCz = "";
	if($params->GetStencilType() eq StnclEnums->StencilType_TOP){
		$typeEn = "For TOP pcb side";
		$typeCz = "Pro vrchní TOP stranu dps";
	
	}elsif($params->GetStencilType() eq StnclEnums->StencilType_BOT){
		$typeEn = "For BOTTOM pcb side";
		$typeCz = "Pro spodní BOT stranu pcb ";
	}elsif($params->GetStencilType() eq StnclEnums->StencilType_TOPBOT){
		$typeEn = "For TOP+BOTTOM pcb side";
		$typeCz = "Pro vrchní TOP + spodní BOT stranu dps";
	}
	
	
	$template->SetKey( "TypeVal", $typeEn, $typeCz );
	
	$template->SetKey( "SourceType", "Data source", "Zdroj dat" );
	
	my $sourceTypeEn = "";
	my $sourceTypeCz = "";
	
	if($params->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_CUSTDATA){
		$sourceTypeEn = "Customer data";
		$sourceTypeCz = "Dodáno zákazníkem";
	
	}elsif($params->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_JOB){
		$sourceTypeEn = "Order - ".$params->GetDataSource()->{"sourceJob"}.($params->GetDataSource()->{"sourceJobIsPool"}?" (POOL)":"");
		$sourceTypeCz = "Zakázka - ".$params->GetDataSource()->{"sourceJob"}.($params->GetDataSource()->{"sourceJobIsPool"}?" (POOL)":"");
	} 
	
	$template->SetKey( "SourceTypeVal", $sourceTypeEn, $sourceTypeCz );
	
	# Information about stencil source data
# sourceType => sourceJob/sourceCustomerData
# sourceJob => jobId
# sourceJobIsPool => 1/0
sub SetDataSource {
	my $self = shift;
	my $val  = shift;

	$self->{"data"}->{"isPool"} = $val;
} 
	

 
	# =================== Table views ============================
 
 	my $legendProfEn = "";
 	my $legendProfCz = "";
 
 	if($params->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_JOB){
		$legendProfEn = '<img  height="15" src="'.GeneralHelper->Root().'\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\profile.png" /> pcb profile';
		$legendProfCz = '<img  height="15" src="'.GeneralHelper->Root().'\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\profile.png" /> profil dps';
 	}
 	
	$template->SetKey( "LegendProfile", $legendProfEn, $legendProfCz );
	
	my $legendDataEn = "";
 	my $legendDataCz = "";
	
	if($params->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_JOB){
	 	$legendDataEn = '<img  height="15" src="'.GeneralHelper->Root().'\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\data.png" /> stencil data limits';
		$legendDataCz = '<img  height="15" src="'.GeneralHelper->Root().'\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\data.png" /> ohraničení plošek šablony';
	}
	
	$template->SetKey( "LegendData", $legendDataEn, $legendDataCz );	
 
	my $legendFiducEn = '';
 	my $legendFiducCz = '';
 
 	if($fiducInf->{"halfFiducials"}){
 		
 		my $readable = $fiducInf->{"fiducSide"} eq "readable" ? 1:0;
 		
 		if ( $inf{"tech"} eq StnclEnums->Technology_LASER ) {
			$fiducTextEn = "Positions of half-lasered fiducials (from ".($readable? "readable" : "nonreadable")." side)";
			$fiducTextCz = "Pozice fiduciálních značek vypálených do poloviny (z ".($readable? "čitelné" : "nečitelné")." strany)";
		}
		elsif ( $inf{"tech"} eq StnclEnums->Technology_ETCH ) {
			$fiducTextEn = "Positions of half-lasered fiducials (from ".($readable? "readable" : "nonreadable")." side)";
			$fiducTextCz = "Pozice fiduciálních značek vypálených do poloviny (z ".($readable? "čitelné" : "nečitelné")." strany)";
		}
 		
 		$legendFiducEn = '<img  height="15" src="'.GeneralHelper->Root().'\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\fiduc.png" /> '.$fiducTextEn;
 		$legendFiducCz = '<img  height="15" src="'.GeneralHelper->Root().'\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\fiduc.png" /> '.$fiducTextCz;
 
 	}
 
	$template->SetKey( "LegendFiduc", $legendFiducEn, $legendFiducCz );
	$template->SetKey( "TopView", "View from readable side (squeegee side)", "Pohled z čitelné strany (strana stěrky)" );
	$template->SetKey( "TopViewImg", $previewTopPath );
 
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
