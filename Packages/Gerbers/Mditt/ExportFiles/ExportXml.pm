
#-------------------------------------------------------------------------------------------#
# Description: Export XML files for MDI gerbers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::Mditt::ExportFiles::ExportXml;

#3th party library
use strict;
use warnings;
use XML::LibXML;
use XML::Tidy;

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
use aliased 'Packages::Gerbers::Mditt::ExportFiles::Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
use constant MAXPNLH => 700;    # maximal height of panel, for exposing pnl "Vertical" (not rotated)

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	# PROPEERTIES

	$self->{"pcbType"} = JobHelper->GetPcbType( $self->{"jobId"} );

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

	$self->{"jobConfigXML"} = undef;    # Final job config XML

	return $self;
}

sub Create {
	my $self   = shift;
	my $pnlDim = shift;                 # real limits of physical layer data / panel dimension

	# Load job config template
	my $templPath = GeneralHelper->Root() . "\\Packages\\Gerbers\\Mditt\\ExportFiles\\jobconfig_templ.xml";
	$self->{"jobConfigXML"} = XML::LibXML->load_xml( "location" => $templPath );

	# Store dimensions
	my $elPartSize = ( $self->{"jobConfigXML"}->findnodes('/jobconfig/job/process_parameters/part_size') )[0];

	$elPartSize->setAttribute( "x", $pnlDim->{"w"} );
	$elPartSize->setAttribute( "y", $pnlDim->{"h"} );

	#$self->__ExportXml( $l->{"gROWname"}, $mirror, $polarity, $stretchX, $stretchY, $etching, $fiducDCode, $pnlDim );
}

# Set default job/layer settings into jobconfig template
# + set specific settings for layer side
sub AddPrimarySide {
	my $self       = shift;
	my $layerName  = shift;
	my $fiducDCode = shift;
	my $outputName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1)  general tings and common tings for all layers
	my $lTIF = $self->{"tifFile"}->GetLayer($layerName);

	die "Output layer tings was not found in tif file for layer: " . $layerName unless ( defined $lTIF );

	# Store z JOB thickness
	my $elPartSize = ( $self->{"jobConfigXML"}->findnodes('/jobconfig/job/process_parameters/part_size') )[0];
	my $etching    = $lTIF->{'etchingType'};
	my $thickness  = $self->__GetThickByLayer( $layerName, $etching );
	$elPartSize->setAttribute( "z", $thickness );

	# 2)  common layer tings for all layers

	# Store order parts number
	my $orderNum = HegMethods->GetPcbOrderNumber($jobId);
	my $info     = HegMethods->GetInfoAfterStartProduce( $jobId . "-" . $orderNum );
	my $parts    = 0;

	if ( defined $info->{'pocet_prirezu'} && $info->{'pocet_prirezu'} > 0 ) {
		$parts += $info->{'pocet_prirezu'};
	}

	if ( defined $info->{'prirezu_navic'} && $info->{'prirezu_navic'} > 0 ) {
		$parts += $info->{'prirezu_navic'};
	}

	my $elPartsTotal  = ( $self->{"jobConfigXML"}->findnodes('/jobconfig/job_layer/process_parameters/parts_total') )[0];
	my $elPartsRemain = ( $self->{"jobConfigXML"}->findnodes('/jobconfig/job_layer/process_parameters/parts_remaining') )[0];

	$elPartsRemain->removeChildNodes();
	$elPartsRemain->appendText($parts);
	$elPartsTotal->removeChildNodes();
	$elPartsTotal->appendText($parts);

	# Store z JOB thickness again
	my $elPartThick = ( $self->{"jobConfigXML"}->findnodes('/jobconfig/job_layer/process_parameters/part_thickness') )[0];

	$elPartThick->removeChildNodes();
	$elPartThick->appendText($thickness);

	# Store scaling

	# Default parameters for stretch and scale
	my $stretchX = $lTIF->{'stretchX'};
	my $stretchY = $lTIF->{'stretchY'};

	# Scale mode:
	#	0:  None (= Fixed mit #1.0)
	#	1:  Measured
	#	2:  Fixed
	#	3:  AutoFixed
	my $scalingMode = 1;
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

	my $elScaleMode = ( $self->{"jobConfigXML"}->findnodes('/jobconfig/job_layer/process_parameters/registration/scaling_mode_global') )[0];

	$elScaleMode->removeChildNodes();
	$elScaleMode->appendText($scalingMode);

	my $elScalePreset = ( $self->{"jobConfigXML"}->findnodes('/jobconfig/job_layer/process_parameters/registration/scale_preset_global') )[0];
	$elScalePreset->setAttribute( "x", $stretchXVal );
	$elScalePreset->setAttribute( "y", $stretchYVal );

	# 3)  specific tings per layer
	$self->__AddJobLayerSett( $layerName, $fiducDCode, $outputName );
}

# Set specific settings for layer side
sub AddSecondarySide {
	my $self       = shift;
	my $layerName  = shift;
	my $fiducDCode = shift;
	my $outputName = shift;

	#  specific tings per layer
	$self->__AddJobLayerSett( $layerName, $fiducDCode, $outputName );

}

# Export prepared XML template
# One per each layer side
# One XML is always "primary", contain all setings also for secondary side
sub Export {
	my $self = shift;

	# Export XML files for all layers. One XML file is primar and contains all information
	my $elLayerNames = ( $self->{"jobConfigXML"}->findnodes('/jobconfig/layer_names') )[0];
	my @layers       = $self->{"jobConfigXML"}->findnodes('/jobconfig/layer_names/layer_name');

	my $primaryXML = undef;

	for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

		my $gerName = $layers[$i]->textContent();
		$gerName =~ s/\.ger//;

		my $finalFile = undef;

		if ( $i == 0 ) {

			# export primary XML

			$primaryXML = $gerName . ".jobconfig.xml";

			$finalFile = EnumsPaths->Jobs_PCBMDITT . $primaryXML;

			my $xmlString = $self->{"jobConfigXML"}->toString();

			$xmlString =~ s/></>\n</gi;

			FileHelper->WriteString( $finalFile, $xmlString );

			# create new   XML::Tidy object by loading:  MainFile.xml
			my $tidy_obj = XML::Tidy->new( 'filename' => $finalFile );
			$tidy_obj->tidy("tab");
			$tidy_obj->write();

		}
		else {

			# export secondary reference XML
			die "Primart xml file name is not defined" unless ( defined $primaryXML );

			$finalFile = EnumsPaths->Jobs_PCBMDITT . $gerName . ".jobconfig.xml";

			my $templPath = GeneralHelper->Root() . "\\Packages\\Gerbers\\Mditt\\ExportFiles\\jobconfigsec_templ.xml";
			$self->{"jobConfigXML"} = XML::LibXML->load_xml( "location" => $templPath );

			my $elJobConfig = ( $self->{"jobConfigXML"}->findnodes('/jobconfig') )[0];
			$elJobConfig->setAttribute( "xml-link_file", $primaryXML );    # Set layer id

			my $xmlString = $self->{"jobConfigXML"}->toString();
			FileHelper->WriteString( $finalFile, $xmlString );

		}

		unless ( -e $finalFile ) {
			die "Xml file for MDI gerber ($finalFile) doesn't exist.\n";
		}
	}

}

sub __AddJobLayerSett {
	my $self       = shift;
	my $layerName  = shift;
	my $fiducDCode = shift;
	my $outputName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Find layer tings in TIF file
	my $lTIF = $self->{"tifFile"}->GetLayer($layerName);

	die "Output layer tings was not found in tif file for layer: " . $layerName unless ( defined $lTIF );

	my $mirrorTIF   = $lTIF->{'mirror'};
	my $polarityTIF = $lTIF->{'polarity'};
	my $etchingTIF  = $lTIF->{'etchingType'};

	# 1) Add layer + layer id to global jobconfig settings

	my $elLayerNames = ( $self->{"jobConfigXML"}->findnodes('/jobconfig/layer_names') )[0];
	my @nodes        = $self->{"jobConfigXML"}->findnodes('/jobconfig/layer_names/layer_name');
	my $node         = $elLayerNames->addNewChild( undef, "layer_name" );

	$node->removeChildNodes();                    # Set gerber layer name
	$node->appendText( $outputName . ".ger" );    # Set gerber layer name

	$node->setAttribute( "id", scalar(@nodes) + 1 );    # Set layer id

	# 2) Add specific settings for layer

	# Load job layer template
	my $templPath  = GeneralHelper->Root() . "\\Packages\\Gerbers\\Mditt\\ExportFiles\\joblayer_templ.xml";
	my $layerXML   = XML::LibXML->load_xml( "location" => $templPath );
	my $elJobLayer = ( $layerXML->findnodes('/job_layer') )[0];

	# Set layer id
	$elJobLayer->setAttribute( "id", scalar(@nodes) + 1 );

	# Set mirror
	my $mirrorY = $mirrorTIF == 1 ? 0 : 1;
	my $elMirror = ( $layerXML->findnodes('/job_layer/creation/mirror') )[0];
	$elMirror->setAttribute( "y", ( $mirrorY ? "true" : "false" ) );

	# Set Rotatin
	my $rotationCW = 0;

	my $pnlH = ( $self->{"jobConfigXML"}->findnodes('/jobconfig/job/process_parameters/part_size') )[0]->getAttribute("y");

	if ($mirrorY) {
		if ( $pnlH > MAXPNLH ) {
			$rotationCW = 270;
		}
		else {
			$rotationCW = 180;
		}
	}
	else {
		if ( $pnlH > MAXPNLH ) {
			$rotationCW = 270;
		}
		else {
			$rotationCW = 0;
		}
	}

	my $elRotation = ( $layerXML->findnodes('/job_layer/creation/rotation_cw') )[0];

	$elRotation->removeChildNodes();
	$elRotation->appendText($rotationCW);

	# Set polarity
	my $polarity = undef;
	if ( $polarityTIF eq 'negative' ) {
		$polarity = 0;
	}
	else {
		$polarity = 1;
	}

	my $elPolarity = ( $layerXML->findnodes('/job_layer/creation/polarity') )[0];
	$elPolarity->removeChildNodes();
	$elPolarity->appendText($polarity);

	# Set exposure energy
	my $energy = 27;    # Default energy for resist = 25

	if ( $layerName =~ /^m[cs]2?$/ ) {

		#  power by mask color
		my %mask = ();

		if ( $layerName =~ /^m[cs]2/ ) {
			%mask = HegMethods->GetSolderMaskColor2($jobId);
		}
		else {
			%mask = HegMethods->GetSolderMaskColor($jobId);
		}

		my $clr = $mask{ ( $layerName =~ /c/ ? "top" : "bot" ) };

		if ( $clr =~ /Z/i ) {
			$energy = 90;    # green #POZOR dle MH jiz nikdy nemenit hodnotu 250!
		}
		elsif ( $clr =~ /B/i ) {
			$energy = 240;    # black
		}
		elsif ( $clr =~ /M/i ) {
			$energy = 240;    # blue
		}
		elsif ( $clr =~ /[WX]/i ) {
			$energy = 220;    # white
		}
		elsif ( $clr =~ /R/i ) {
			$energy = 240;    # red
		}
		elsif ( $clr =~ /G/i ) {
			$energy = 350;    # green SMD flex
		}
		else {
			die "Energy for color: $clr is not defined";
		}
	}

	my $elEnergy = ( $layerXML->findnodes('/job_layer/process_parameters/exposure/exposure_energy') )[0];
	$elEnergy->removeChildNodes();
	$elEnergy->appendText($energy);

	# Set fiducial name
	my $elFiducId = ( $layerXML->findnodes('/job_layer/process_parameters/fiducial_groups/fiducial_group/fiducial_id_global') )[0];
	$elFiducId->removeChildNodes();
	$elFiducId->appendText($fiducDCode);

	# Set image object
	my $elImageObject = undef;
	if (    ( $layerName =~ /^mc\d?$/ && CamHelper->LayerExists( $inCAM, $jobId, "c" ) && $self->{"pcbType"} ne EnumsGeneral->PcbType_NOCOPPER )
		 || ( $layerName =~ /^ms\d?$/ && CamHelper->LayerExists( $inCAM, $jobId, "s" ) ) )
	{
		$elImageObject = $self->__AddFiducSquare($layerName);
	}
	else {

		$elImageObject = $self->__AddFiducCircle($layerName);
	}

	# Add image object template to job layer template
	( $layerXML->findnodes('/job_layer/process_parameters/fiducial_groups/fiducial_group/fiducials_default/fiducial') )[0]
	  ->appendChild($elImageObject);

	# Add job layer settings template to whoel jobconfig
	# 0) Add comment to layer

	my $coment = $self->{"jobConfigXML"}->createComment(" Layer settings for layer: $layerName ");

	( $self->{"jobConfigXML"}->findnodes('/jobconfig') )[0]->appendChild($coment);
	( $self->{"jobConfigXML"}->findnodes('/jobconfig') )[0]->appendChild($elJobLayer);

}

# copper + soldermask
sub __AddFiducCircle {
	my $self      = shift;
	my $layerName = shift;

	my $templIOPath   = GeneralHelper->Root() . "\\Packages\\Gerbers\\Mditt\\ExportFiles\\imageobjectCircle_templ.xml";
	my $imageXML      = XML::LibXML->load_xml( "location" => $templIOPath );
	my $elImageObject = ( $imageXML->findnodes('/image_object') )[0];

	# Find layer tings in TIF file
	my $lTIF = $self->{"tifFile"}->GetLayer($layerName);

	die "Output layer tings was not found in tif file for layer: " . $layerName unless ( defined $lTIF );
	my $etchingTIF = $lTIF->{'etchingType'};

	# Default parameters for image

	my $diameter                      = 3;       #Default diamater 3mm
	my $iterations                    = 3;
	my $upper_tolerance_factor        = 0.04;
	my $lower_tolerance_factor        = -0.04;
	my $upper_tolerance_factor_change = 0.02;
	my $lower_tolerance_factor_change = -0.02;

	# Signal layers c, s
	if ( $layerName =~ /^[cs]$/ ) {

		# When tenting, fiducial holes are plated => smaller
		if ( $etchingTIF eq "tenting" ) {
			$diameter               = 2.87;
			$upper_tolerance_factor = 0.075;
			$lower_tolerance_factor = -0.75;

		}
		else {

			# When pattern + flash, fiducial holes are plated => smaller
			if ( $self->{"nifFile"}->GetValue("flash") > 0 ) {
				$diameter               = 2.87;
				$upper_tolerance_factor = 0.075;
				$lower_tolerance_factor = -0.075;

			}
			else {
				$diameter               = 3;
				$upper_tolerance_factor = 0.06;
				$lower_tolerance_factor = -0.06;
			}
		}
	}

	# Solder mask layer mc, ms, mcflex, msflex
	elsif ( $layerName =~ /^m[cs]2?$/ ) {
		
		$diameter               = 2.85;
		$upper_tolerance_factor = 0.08;
		$lower_tolerance_factor = -0.08;

	}

	# Plug hole layers, gold connector layers
	elsif ( $layerName =~ /^plg[cs]$/ || $layerName =~ /^gold[cs]$/ ) {

		$diameter               = 2.87;
		$upper_tolerance_factor = 0.08;
		$lower_tolerance_factor = -0.08;
	}

	# Set diameter
	my $elDiameter = ( $imageXML->findnodes('/image_object/circle/diameter') )[0];
	$elDiameter->removeChildNodes();
	$elDiameter->appendText($diameter);

	# Set tolerances
	my $elTolerance = ( $imageXML->findnodes('/image_object/tolerance') )[0];

	$elTolerance->setAttribute( "upper_tolerance_factor", $upper_tolerance_factor );
	$elTolerance->setAttribute( "lower_tolerance_factor", $lower_tolerance_factor );

	$elTolerance->setAttribute( "upper_tolerance_factor_change", $upper_tolerance_factor_change );
	$elTolerance->setAttribute( "lower_tolerance_factor_change", $lower_tolerance_factor_change );

	$elTolerance->setAttribute( "iterations", $iterations );

	return $elImageObject;
}

sub __AddFiducSquare {
	my $self      = shift;
	my $layerName = shift;

	die "Not solder mask layer" unless ( $layerName =~ /^m[cs]\d?$/ );

	my $templIOPath   = GeneralHelper->Root() . "\\Packages\\Gerbers\\Mditt\\ExportFiles\\imageobjectSquare_templ.xml";
	my $imageXML      = XML::LibXML->load_xml( "location" => $templIOPath );
	my $elImageObject = ( $imageXML->findnodes('/image_object') )[0];

	# Default parameters for image

	my $iterations                    = 0;
	my $upper_tolerance_factor        = 0.075;
	my $lower_tolerance_factor        = -0.075;
	my $upper_tolerance_factor_change = 0.00;
	my $lower_tolerance_factor_change = -0.00;

	# Set tolerances
	my $elTolerance = ( $imageXML->findnodes('/image_object/tolerance') )[0];

	$elTolerance->setAttribute( "upper_tolerance_factor", $upper_tolerance_factor );
	$elTolerance->setAttribute( "lower_tolerance_factor", $lower_tolerance_factor );

	$elTolerance->setAttribute( "upper_tolerance_factor_change", $upper_tolerance_factor_change );
	$elTolerance->setAttribute( "lower_tolerance_factor_change", $lower_tolerance_factor_change );

	$elTolerance->setAttribute( "iterations", $iterations );

	return $elImageObject;

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

	use aliased 'Packages::Gerbers::Mditt::ExportFiles::ExportXml';

	my $ExportXml = ExportXml->new();
	$ExportXml->__LoadTemplate();

}

1;
