
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Mdi::ExportFiles::ExportXml;

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library
use aliased 'Helpers::GeneralHelper';

#use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsPaths';

#use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';

#use aliased 'CamHelpers::CamHelper';
#use aliased 'Packages::Export::GerExport::Helper';

#use aliased 'CamHelpers::CamSymbol';
#use aliased 'CamHelpers::CamJob';
#use aliased 'Packages::Polygon::PolygonHelper';
#use aliased 'Packages::Polygon::Features::Features::RouteFeatures';
#use aliased 'Packages::Gerbers::Export::ExportLayers';
#use aliased 'Packages::ItemResult::ItemResult';
#use aliased 'Packages::Mdi::ExportFiles::FiducMark';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Packages::TifFile::TifSigLayers';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"stackup"} = shift;

	$self->{"profLim"} = shift;

	$self->{"tifFile"} = TifSigLayers->new( $self->{"jobId"} );
	$self->{"nifFile"} =  NifFile->new( $self->{"jobId"} );
	
	unless($self->{"tifFile"}->TifFileExist()){
		die "Dif file must exist when MDI data are exported.\n";
	}
	
	unless($self->{"nifFile"}->Exist()){
		die "Nif file must exist when MDI data are exported.\n";
	}
	
 

	return $self;
}

sub Export {
	my $self        = shift;
	my $l           = shift;
	my $fiduc_layer = shift;

	my $mirror   = undef;
	my $polarity = undef;
	my $etching  = undef;

	if ( $l->{"gROWlayer_type"} eq "signal" || $l->{"gROWlayer_type"} eq "power_ground" || $l->{"gROWlayer_type"} eq "mixed" ) {

		my %sigLayers = $self->{"tifFile"}->GetSignalLayers();
		$mirror   = $sigLayers{ $l->{"gROWname"} }->{'mirror'};
		$polarity = $sigLayers{ $l->{"gROWname"} }->{'polarity'};
		$etching  = $sigLayers{ $l->{"gROWname"} }->{'etchingType'};

	}
	else {
		if ( $l->{"gROWname"} =~ /c/ ) {
			$mirror = 0;
		}
		elsif ( $l->{"gROWname"} =~ /s/ ) {
			$mirror = 1;
		}

		$polarity = "positive";

	}
	
	$self->__ExportXml( $l->{"gROWname"}, $mirror, $polarity, $etching, $fiduc_layer );
	
	

}

sub __ExportXml {
	my $self        = shift;
	my $layerName   = shift;
	my $mirror      = shift;
	my $polarity    = shift;
	my $etching     = shift;
	my $fiduc_layer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $templ = $self->__LoadTemplate();

	unless ($templ) {
		return 0;
	}
	my ( $lowerlimit, $upperlimit, $acceptance, $brightness, $power, $iterations, $upper, $lower, $diameter );
	my $x_position;
	my $y_position;

	if ( $layerName eq 'c' or $layerName eq 's' ) {
		if ( $etching eq "tenting" ) {
			$diameter   = 2.87;
			$brightness = 8;
			$upperlimit = 0.08;
			$lowerlimit = -0.08;
			$acceptance = 70;
			$x_position = 0.5;
			$y_position = -1.0;

		}
		else {
			if (  $self->{"nifFile"}->GetValue("flash") > 0 ) {
				$diameter   = 2.87;
				$brightness = 8;
				$upperlimit = 0.08;
				$lowerlimit = -0.08;
				$acceptance = 70;
				$x_position = 0;
				$y_position = 0;
			}
			else {
				$diameter   = 3;
				$brightness = 3;
				$upperlimit = 0.06;
				$lowerlimit = -0.06;
				$acceptance = 70;
				$x_position = 0;
				$y_position = 0;
			}

		}
	}
	elsif ( $layerName eq 'mc' or $layerName eq 'ms' ) {
		$power      = 230;
		$diameter   = 2.85;
		$brightness = 3;
		$upperlimit = 0.08;
		$lowerlimit = -0.08;
		$acceptance = 70;
		$x_position = 0;
		$y_position = 0;

	}
	else {
		$diameter   = 3;
		$brightness = 3;
		$upperlimit = 0.04;
		$lowerlimit = -0.04;
		$acceptance = 70;
		$x_position = 0.0;
		$y_position = 0.0;
	}

	$iterations = 3;
	$upper      = 0.02;
	$lower      = -0.02;

 
	my $xPnlSize = $self->{"profLim"}->{"xMax"} - $self->{"profLim"}->{"xMin"};
	my $yPnlSize = $self->{"profLim"}->{"yMax"} - $self->{"profLim"}->{"yMin"};

	# Fill xml

	$templ->{"job_params"}->{"job_name"}        = $jobId;
	$templ->{"job_params"}->{"parts_total"}     = 0;
	$templ->{"job_params"}->{"parts_remaining"} = 0;

	$templ->{"job_params"}->{"part_size"}->{"z"} = $self->__GetThickByLayer($layerName);
	$templ->{"job_params"}->{"part_size"}->{"x"} = $xPnlSize;
	$templ->{"job_params"}->{"part_size"}->{"y"} = $yPnlSize;

	$templ->{"job_params"}->{"image_position"}->{"x"} = $x_position;
	$templ->{"job_params"}->{"image_position"}->{"y"} = $y_position;

	if ($mirror) {
		if ( $xPnlSize > 520 ) {
			$templ->{"job_params"}->{"rotation"} = 3;
		}
		else {
			$templ->{"job_params"}->{"rotation"} = 0;
		}
	}
	else {
		if ( $yPnlSize > 520 ) {
			$templ->{"job_params"}->{"rotation"} = 3;
		}
		else {
			$templ->{"job_params"}->{"rotation"} = 2;
		}
	}

	$templ->{"job_params"}->{"mirror"}->{"x"} = 0;
	$templ->{"job_params"}->{"mirror"}->{"y"} = $mirror;

	$templ->{"job_params"}->{"image_object_default"}->{"image_object"}->{"diameter_x"}->{"iterations"}   = $iterations;
	$templ->{"job_params"}->{"image_object_default"}->{"image_object"}->{"diameter_x"}->{"lowch"}        = $upper;
	$templ->{"job_params"}->{"image_object_default"}->{"image_object"}->{"diameter_x"}->{"uppch"}        = $lower;
	$templ->{"job_params"}->{"image_object_default"}->{"image_object"}->{"diameter_x"}->{"value"}        = $diameter;
	$templ->{"job_params"}->{"image_object_default"}->{"image_object"}->{"diameter_x"}->{"upptol"}       = $upperlimit;
	$templ->{"job_params"}->{"image_object_default"}->{"image_object"}->{"diameter_x"}->{"lowtol"}       = $lowerlimit;
	$templ->{"job_params"}->{"image_object_default"}->{"image_object"}->{"image_recognition_acceptance"} = $acceptance;
	$templ->{"job_params"}->{"image_object_default"}->{"image_object"}->{"image_acquisition_brightness"} = $brightness;

	if ( $polarity eq 'negative' ) {
		$templ->{"job_params"}->{"polarity"} = 0;
	}
	else {
		$templ->{"job_params"}->{"polarity"} = 1;
	}
	if ($power) {
		$templ->{"job_params"}->{"exposure_energy"} = $power;
	}
	$templ->{"job_params"}->{"fiducial_ID_global"} = $fiduc_layer;
	
	my $xmlString = XMLout( $templ->{"job_params"}, RootName => "job_params" );
 
	FileHelper->WriteString( EnumsPaths->Jobs_MDI .$self->{"jobId"}.$layerName . "_mdi.xml", $xmlString );
}




sub __LoadTemplate {
	my $self = shift;

	my $templPath = GeneralHelper->Root() . "\\Packages\\Mdi\\ExportFiles\\template.xml";
	my $templXml  = FileHelper->Open($templPath);

	my @thickList = ();

	my $xml = XMLin(
					 $templXml,
					 ForceArray => undef,
					 KeyAttr    => undef,
					 KeepRoot   => 1,
	);

	return $xml;
}

sub __GetThickByLayer {
	my $self = shift;

	my $layer = shift;    #layer of number. Simple c,1,2,s or v1, v2 use ENUMS::Layers

	my $thick = 0;        #total thick

	if ( HegMethods->GetTypeOfPcb( $self->{"jobId"} ) eq 'Vicevrstvy' ) {

		my $stackup = $self->{"stackup"};

		$thick = $stackup->GetThickByLayerName($layer);

		my $cuLayer = $stackup->GetCuLayer($layer);

		#test by Mira, add 80um (except cores)
		if ( $cuLayer->GetType() eq EnumsGeneral->Layers_TOP || $cuLayer->GetType() eq EnumsGeneral->Layers_BOT ) {
			$thick += 0.080;
		}

	}
	else {

		$thick = HegMethods->GetPcbMaterialThick( $self->{"jobId"} );

		#test by Mira, add 80um (except cores)
		$thick += 0.080;
	}

	return ( sprintf "%3.2f", ($thick) );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Mdi::ExportFiles::ExportXml';

	my $ExportXml = ExportXml->new();
	$ExportXml->__LoadTemplate();

}

1;

