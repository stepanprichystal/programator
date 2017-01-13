
#-------------------------------------------------------------------------------------------#
# Description: Export XML files for MDI gerbers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Mdi::ExportFiles::ExportXml;

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Packages::TifFile::TifSigLayers';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"profLim"}  = shift;
	$self->{"layerCnt"} = shift;

	if ( $self->{"layerCnt"} > 2 ) {
		$self->{"stackup"} = Stackup->new( $self->{"jobId"} );
	}

	$self->{"tifFile"} = TifSigLayers->new( $self->{"jobId"} );
	$self->{"nifFile"} = NifFile->new( $self->{"jobId"} );

	unless ( $self->{"tifFile"}->TifFileExist() ) {
		die "Dif file must exist when MDI data are exported.\n";
	}

	unless ( $self->{"nifFile"}->Exist() ) {
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
			if ( $self->{"nifFile"}->GetValue("flash") > 0 ) {
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

	$templ->{"job_params"}->[0]->{"job_name"}->[0]        = $jobId . $layerName . "_mdi";
	$templ->{"job_params"}->[0]->{"parts_total"}->[0]     = 0;
	$templ->{"job_params"}->[0]->{"parts_remaining"}->[0] = 0;

	$templ->{"job_params"}->[0]->{"part_size"}->[0]->{"z"} = $self->__GetThickByLayer($layerName);
	$templ->{"job_params"}->[0]->{"part_size"}->[0]->{"x"} = $xPnlSize;
	$templ->{"job_params"}->[0]->{"part_size"}->[0]->{"y"} = $yPnlSize;

	$templ->{"job_params"}->[0]->{"image_position"}->[0]->{"x"} = $x_position;
	$templ->{"job_params"}->[0]->{"image_position"}->[0]->{"y"} = $y_position;

	if ($mirror) {
		if ( $xPnlSize > 520 ) {
			$templ->{"job_params"}->[0]->{"rotation"}->[0] = 3;
		}
		else {
			$templ->{"job_params"}->[0]->{"rotation"}->[0] = 0;
		}
	}
	else {
		if ( $yPnlSize > 520 ) {
			$templ->{"job_params"}->[0]->{"rotation"}->[0] = 3;
		}
		else {
			$templ->{"job_params"}->[0]->{"rotation"}->[0] = 2;
		}
	}

	$templ->{"job_params"}->[0]->{"mirror"}->[0]->{"x"} = 0;
	$templ->{"job_params"}->[0]->{"mirror"}->[0]->{"y"} = $mirror;

	$templ->{"job_params"}->[0]->{"image_object_default"}->[0]->{"image_object"}->[0]->{"diameter_x"}->[0]->{"iterations"}   = $iterations;
	$templ->{"job_params"}->[0]->{"image_object_default"}->[0]->{"image_object"}->[0]->{"diameter_x"}->[0]->{"lowch"}        = $upper;
	$templ->{"job_params"}->[0]->{"image_object_default"}->[0]->{"image_object"}->[0]->{"diameter_x"}->[0]->{"uppch"}        = $lower;
	$templ->{"job_params"}->[0]->{"image_object_default"}->[0]->{"image_object"}->[0]->{"diameter_x"}->[0]->{"value"}        = $diameter;
	$templ->{"job_params"}->[0]->{"image_object_default"}->[0]->{"image_object"}->[0]->{"diameter_x"}->[0]->{"upptol"}       = $upperlimit;
	$templ->{"job_params"}->[0]->{"image_object_default"}->[0]->{"image_object"}->[0]->{"diameter_x"}->[0]->{"lowtol"}       = $lowerlimit;
	$templ->{"job_params"}->[0]->{"image_object_default"}->[0]->{"image_object"}->[0]->{"image_recognition_acceptance"}->[0] = $acceptance;
	$templ->{"job_params"}->[0]->{"image_object_default"}->[0]->{"image_object"}->[0]->{"image_acquisition_brightness"}->[0] = $brightness;

	if ( $polarity eq 'negative' ) {
		$templ->{"job_params"}->[0]->{"polarity"}->[0] = 0;
	}
	else {
		$templ->{"job_params"}->[0]->{"polarity"}->[0] = 1;
	}
	if ($power) {
		$templ->{"job_params"}->[0]->{"exposure_energy"}->[0] = $power;
	}
	$templ->{"job_params"}->[0]->{"fiducial_ID_global"}->[0] = $fiduc_layer;

	#my $xmlString = XMLout( $templ, RootName => "job_params" );

	my $xmlString = XMLout(
		$templ,
		KeepRoot   => 1,
		AttrIndent => 0,

		XMLDecl => '<?xml version="1.0" encoding="utf-8"?>'
	);

	my $finalFile = EnumsPaths->Jobs_MDI . $self->{"jobId"} . $layerName . "_mdi.xml";

	FileHelper->WriteString($finalFile , $xmlString );
	
	unless(-e $finalFile){
		die "Xml file for MDI gerber ($finalFile) doesn't exist.\n";
	}	
}

sub __LoadTemplate {
	my $self = shift;

	my $templPath = GeneralHelper->Root() . "\\Packages\\Mdi\\ExportFiles\\template.xml";
	my $templXml  = FileHelper->Open($templPath);

	my @thickList = ();

	my $xml = XMLin(
					 $templXml,
					 ForceArray => 1,
					 KeepRoot   => 1
	);

	return $xml;
}

sub __GetThickByLayer {
	my $self = shift;

	my $layer = shift;    #l

	my $thick = 0;        #total thick

	# for multilayer copper layer read thick from stackup, else return total thick
	if ( $self->{"layerCnt"} > 2 ) {

		my $stackup = $self->{"stackup"};

		# for signal layers
		if ( $layer =~ /^c$/ || $layer =~ /^s$/ || $layer =~ /^v\d$/ ) {

			$thick = $stackup->GetThickByLayerName($layer);

			my $cuLayer = $stackup->GetCuLayer($layer);

			#test by Mira, add 80um (except cores)
			if ( $cuLayer->GetType() eq EnumsGeneral->Layers_TOP || $cuLayer->GetType() eq EnumsGeneral->Layers_BOT ) {
				$thick += 0.080;
			}
		}
		else {

			# For Mask, Plugs..

			$thick = $stackup->GetFinalThick();
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

