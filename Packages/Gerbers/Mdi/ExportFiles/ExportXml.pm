
#-------------------------------------------------------------------------------------------#
# Description: Export XML files for MDI gerbers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::Mdi::ExportFiles::ExportXml;

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Packages::TifFile::TifLayers';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	if ( $self->{"layerCnt"} > 2 ) {

		$self->{"stackup"} = Stackup->new( $self->{"inCAM"}, $self->{"jobId"} );
		$self->{"stackupNC"} = StackupNC->new( $self->{"inCAM"}, $self->{"jobId"} );
	}

	$self->{"tifFile"} = TifLayers->new( $self->{"jobId"} );
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
	my $self       = shift;
	my $l          = shift;
	my $fiducDCode = shift;
	my $pnlDim     = shift;    # real limits of physical layer data / panel dimension

	# Find layer settings in TIF file
	my $lTIF = $self->{"tifFile"}->GetLayer( $l->{"gROWname"} );

	die "Output layer settings was not found in tif file for layer: " . $l->{"gROWname"} unless ( defined $lTIF );

	my $mirror   = $lTIF->{'mirror'};
	my $polarity = $lTIF->{'polarity'};
	my $etching  = $lTIF->{'etchingType'};
	my $stretchX = $lTIF->{'stretchX'};
	my $stretchY = $lTIF->{'stretchY'};

	$self->__ExportXml( $l->{"gROWname"}, $mirror, $polarity, $stretchX, $stretchY, $etching, $fiducDCode, $pnlDim );
}

sub __ExportXml {
	my $self       = shift;
	my $layerName  = shift;
	my $mirror     = shift;
	my $polarity   = shift;
	my $stretchX   = shift;
	my $stretchY   = shift;
	my $etching    = shift;
	my $fiducDCode = shift;
	my $pnlDim     = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $templ = $self->__LoadTemplate();

	unless ($templ) {
		return 0;
	}

	# Default parameters for image
	my $power      = undef;
	my $brightness = 3;
	my $acceptance = 70;
	my $x_position = 0.0;
	my $y_position = 0.0;

	# Defaul parameters for fiducial holes
	my $diameter   = 3;
	my $iterations = 3;
	my $lower      = -0.02;
	my $lowerlimit = -0.04;
	my $upper      = 0.02;
	my $upperlimit = 0.04;

	# Default parameters for stretch and scale
	my $scalingMode = 1;    # Scale data by measured value from MDI CCD
	my $stretchXVal = 0;
	my $stretchYVal = 0;

	if ( $stretchX != 0 || $stretchY != 0 ) {

		$scalingMode = 2;    # Scale data by fixed value

		# Scale only cores, which not have plated drilling
		if ( $self->{"layerCnt"} > 2 ) {

			my %lPars = JobHelper->ParseSignalLayerName($layerName);

			my $p = $self->{"stackup"}->GetProductByLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );
			if ( $p->GetIsPlated() ) {
				$scalingMode = 1;
			}
		}
		else {

			my @ncLayers = grep { !$_->{"technical"} } CamDrilling->GetPltNCLayers( $self->{"inCAM"}, $self->{"jobId"} );

			if ( scalar(@ncLayers) ) {
				$scalingMode = 1;
			}
		}

		$stretchXVal = sprintf( "%.5f", ( 100 + $stretchX ) / 100 );
		$stretchYVal = sprintf( "%.5f", ( 100 + $stretchY ) / 100 );
	}

	$templ->{"job_params"}->[0]->{"scale_preset"}->[0]->{"x"} = $stretchXVal;

	# Signal layers c, s
	if ( $layerName =~ /^[cs]$/ ) {

		# When tenting, fiducial holes are plated => smaller
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

			# When pattern + flash, fiducial holes are plated => smaller
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

	# Solder mask layer mc, ms, mcflex, msflex
	elsif ( $layerName =~ /^m[cs]2?(flex)?$/ ) {

		# set power by mask color
		my %mask = ();

		if ( $layerName =~ /^m[cs]2/ ) {
			%mask = HegMethods->GetSolderMaskColor2($jobId);
		}
		else {
			%mask = HegMethods->GetSolderMaskColor($jobId);
		}

		my $clr = $mask{ ( $layerName =~ /c/ ? "top" : "bot" ) };

		if ( $clr =~ /Z/i ) {
			$power = 250;    # green #POZOR dle MH jiz nikdy nemenit hodnotu 250!
		}
		elsif ( $clr =~ /B/i ) {
			$power = 240;    # black
		}
		elsif ( $clr =~ /M/i ) {
			$power = 240;    # blue
		}
		elsif ( $clr =~ /[WX]/i ) {
			$power = 220;    # white
		}
		elsif ( $clr =~ /R/i ) {
			$power = 240;    # red
		}
		elsif ( $clr =~ /G/i ) {
			$power = 350;    # green SMD flex
		}
		else {
			die "Energy for color: $clr is not defined";
		}

		$diameter   = 2.85;
		$brightness = 3;
		$upperlimit = 0.08;
		$lowerlimit = -0.08;
		$acceptance = 70;
		$x_position = 0;
		$y_position = 0;

	}

	# Plug hole layers, gold connector layers
	elsif ( $layerName =~ /^plg[cs]$/ || $layerName =~ /^gold[cs]$/ ) {

		$diameter   = 2.87;
		$brightness = 8;
		$upperlimit = 0.08;
		$lowerlimit = -0.08;
		$acceptance = 70;
		$x_position = 0.5;
		$y_position = -1.0;
	}

	# Fill xml
	my $fileName = $layerName;

	if ( $fileName =~ /outer/ ) {
		$fileName = Helper->ConverOuterName2FileName( $layerName, $self->{"layerCnt"} );
	}
	elsif ( $layerName =~ /^v\d+$/ ) {

		my %lPars = JobHelper->ParseSignalLayerName($layerName);

		my $p = $self->{"stackup"}->GetProductByLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

		if ( $p->GetProductType() eq StackEnums->Product_PRESS ) {

			my $side = $self->{"stackup"}->GetSideByCuLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

			my $matL = $p->GetProductOuterMatLayer( $side eq "top" ? "first" : "last" )->GetData();

			if ( $matL->GetType() eq StackEnums->MaterialType_COPPER && !$matL->GetIsFoil() ) {

				# Convert standard inner signal layer name to name "after press"
				$fileName = Helper->ConverInnerName2AfterPressFileName($layerName);
			}
		}

	}

	$templ->{"job_params"}->[0]->{"job_name"}->[0] = $jobId . $fileName . "_mdi";

	my $orderNum = HegMethods->GetPcbOrderNumber($jobId);
	my $info     = HegMethods->GetInfoAfterStartProduce( $jobId . "-" . $orderNum );
	my $parts    = 0;

	if ( defined $info->{'pocet_prirezu'} && $info->{'pocet_prirezu'} > 0 ) {
		$parts += $info->{'pocet_prirezu'};
	}

	if ( defined $info->{'prirezu_navic'} && $info->{'prirezu_navic'} > 0 ) {
		$parts += $info->{'prirezu_navic'};
	}

	$templ->{"job_params"}->[0]->{"parts_total"}->[0]     = $parts;
	$templ->{"job_params"}->[0]->{"parts_remaining"}->[0] = $parts;

	$templ->{"job_params"}->[0]->{"part_size"}->[0]->{"z"} = $self->__GetThickByLayer( $layerName, $etching );
	$templ->{"job_params"}->[0]->{"part_size"}->[0]->{"x"} = $pnlDim->{"w"};
	$templ->{"job_params"}->[0]->{"part_size"}->[0]->{"y"} = $pnlDim->{"h"};

	$templ->{"job_params"}->[0]->{"image_position"}->[0]->{"x"} = $x_position;
	$templ->{"job_params"}->[0]->{"image_position"}->[0]->{"y"} = $y_position;

	my $mirrorY = $mirror == 1 ? 0 : 1;

	if ($mirrorY) {
		if ( $pnlDim->{"h"} > 540 ) {
			$templ->{"job_params"}->[0]->{"rotation"}->[0] = 3;
		}
		else {
			$templ->{"job_params"}->[0]->{"rotation"}->[0] = 0;
		}
	}
	else {
		if ( $pnlDim->{"h"} > 540 ) {
			$templ->{"job_params"}->[0]->{"rotation"}->[0] = 3;
		}
		else {
			$templ->{"job_params"}->[0]->{"rotation"}->[0] = 2;
		}
	}

	$templ->{"job_params"}->[0]->{"scaling_mode"}->[0]        = $scalingMode;
	$templ->{"job_params"}->[0]->{"scale_preset"}->[0]->{"x"} = $stretchXVal;
	$templ->{"job_params"}->[0]->{"scale_preset"}->[0]->{"y"} = $stretchYVal;

	$templ->{"job_params"}->[0]->{"mirror"}->[0]->{"x"} = 0;
	$templ->{"job_params"}->[0]->{"mirror"}->[0]->{"y"} = $mirrorY;

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
	$templ->{"job_params"}->[0]->{"fiducial_ID_global"}->[0] = $fiducDCode;

	#my $xmlString = XMLout( $templ, RootName => "job_params" );

	my $xmlString = XMLout(
		$templ,
		KeepRoot   => 1,
		AttrIndent => 0,

		XMLDecl => '<?xml version="1.0" encoding="utf-8"?>'
	);

	my $finalFile = EnumsPaths->Jobs_MDI . $self->{"jobId"} . $fileName . "_mdi.xml";

	FileHelper->WriteString( $finalFile, $xmlString );

	unless ( -e $finalFile ) {
		die "Xml file for MDI gerber ($finalFile) doesn't exist.\n";
	}
}

sub __LoadTemplate {
	my $self = shift;

	my $templPath = GeneralHelper->Root() . "\\Packages\\Gerbers\\Mdi\\ExportFiles\\template.xml";
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
	my $self        = shift;
	my $layer       = shift;    #
	my $etchingType = shift;    # EnumsGeneral->Etching_xxxx

	my $jobId = $self->{"jobId"};
	my $inCAM = $self->{"inCAM"};

	my $PLTTHICKNESS    = 0.035;    # plating is 35µm from one side
	my $PREPLTTHICKNESS = 0.015;    # pre-plating is 15µm from one side (viafilling)
	my $SMTHICNESS      = 0.025;    # solder mask thickness around 25µm
	my $RESISTTHICNESS  = 0.070;    # resist thickness around 70µm (resist plus protection foil)

	my $thick = 0;                  #total thick

	if ( $layer =~ /^m[cs]2?(flex)?$/ || $layer =~ /^gold[cs]$/ ) {

		# Solder mask layers
		# Gold layers

		if ( $self->{"layerCnt"} > 2 ) {

			$thick = $self->{"stackup"}->GetFinalThick(0) / 1000;
		}
		else {

			$thick = HegMethods->GetPcbMaterialThick( $self->{"jobId"} );
		}

		$thick += 2 * $PLTTHICKNESS if ( $self->{"layerCnt"} >= 2 );

		if ( $layer =~ /^m[cs]2?(flex)?$/ ) {

			$thick += 2 * $SMTHICNESS;
		}

		if ( $layer =~ /^gold[cs]$/ ) {

			my $smLayer = "m" . ( $layer =~ /^gold([cs])$/ )[0];

			$thick += 2 * $SMTHICNESS if ( CamHelper->LayerExists( $inCAM, $jobId, $smLayer ) )

		}

	}
	else {

		# Signal layer, plug layers

		my %lPars = JobHelper->ParseSignalLayerName($layer);

		if ( $self->{"layerCnt"} > 2 ) {

			# Multilayer PCB

			my $stackup = $self->{"stackup"};

			my $product = $stackup->GetProductByLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

			die "Stackup product was not found by layer: $layer " unless ( defined $product );

			# Outer signal layers

			$thick = $product->GetThick(0) / 1000;    # without outer plating

			# if via fill, there is extra pre plating
			$thick += 2 * $PREPLTTHICKNESS if ( $product->GetPlugging() );
			$thick += 2 * $PLTTHICKNESS
			  if ( !$product->GetOuterCoreTop() && !$product->GetOuterCoreBot() && $etchingType eq EnumsGeneral->Etching_TENTING );

		}
		else {

			# Single or double layer PCB

			$thick = HegMethods->GetPcbMaterialThick( $self->{"jobId"} );

			if ( $lPars{"plugging"} ) {

				# plg layer

				$thick += 2 * $PREPLTTHICKNESS;

			}
			else {

				# signal layer
				$thick += 2 * $PLTTHICKNESS if ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) );
				$thick += 2 * $PLTTHICKNESS if ( $etchingType eq EnumsGeneral->Etching_TENTING );
			}
		}

	}

	# add value of resist from both sides
	$thick += 2 * $RESISTTHICNESS;

	$thick = sprintf( "%.3f", $thick );

	return $thick;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Gerbers::Mdi::ExportFiles::ExportXml';

	my $ExportXml = ExportXml->new();
	$ExportXml->__LoadTemplate();

}

1;

