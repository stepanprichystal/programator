
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
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Packages::TifFile::TifSigLayers';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';

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

		$self->{"stackup"} = Stackup->new( $self->{"jobId"} );
		$self->{"stackupNC"} = StackupNC->new( $self->{"jobId"}, $self->{"inCAM"} );
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
	my $self       = shift;
	my $l          = shift;
	my $fiducDCode = shift;
	my $pnlDim     = shift;    # real limits of phzsical layer data / panel dimension

	my $mirror   = undef;
	my $polarity = undef;
	my $etching  = undef;

	if ( $l->{"gROWname"} =~ /^[cs]$/ || $l->{"gROWname"} =~ /^v\d$/ ) {

		my %sigLayers = $self->{"tifFile"}->GetSignalLayers();
		$mirror   = $sigLayers{ $l->{"gROWname"} }->{'mirror'};
		$polarity = $sigLayers{ $l->{"gROWname"} }->{'polarity'};
		$etching  = $sigLayers{ $l->{"gROWname"} }->{'etchingType'};
	}
	elsif ( $l->{"gROWname"} =~ /^v\douter$/ ) {

		# fake outer core signal layers
		$mirror   = ( $l->{"gROWname"} =~ /^v1outer$/ ? 0 : 1 );
		$polarity = "negative";
		$etching  = undef;

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

	$self->__ExportXml( $l->{"gROWname"}, $mirror, $polarity, $etching, $fiducDCode, $pnlDim );

}

sub __ExportXml {
	my $self       = shift;
	my $layerName  = shift;
	my $mirror     = shift;
	my $polarity   = shift;
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

		if ( $layerName =~ /^m[cs]flex/ ) {
			
			$power = 250;    # SD 2460 - UV FLEX
		}
		else {

			if ( $layerName =~ /^m[cs]2/ ) {
				%mask = HegMethods->GetSolderMaskColor2($jobId);
			}
			else {
				%mask = HegMethods->GetSolderMaskColor($jobId);
			}

			my $clr = $mask{ ( $layerName =~ /c/ ? "top" : "bot" ) };

			if ( $clr =~ /Z/i ) {
				$power = 280;    # green
			}
			elsif ( $clr =~ /B/i ) {
				$power = 240;    # black
			}
			elsif ( $clr =~ /M/i ) {
				$power = 240;    # blue
			}
			elsif ( $clr =~ /W/i ) {
				$power = 220;    # white
			}
			elsif ( $clr =~ /R/i ) {
				$power = 240;    # red
			}
			else {
				$power = 230;    # other
			}
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

	$templ->{"job_params"}->[0]->{"job_name"}->[0] = $jobId . $layerName . "_mdi";
	$templ->{"job_params"}->[0]->{"job_name"}->[0] =~ s/outer//;    # remove "outer" from outer core fake layers

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

	if ($mirror) {
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
	$templ->{"job_params"}->[0]->{"fiducial_ID_global"}->[0] = $fiducDCode;

	#my $xmlString = XMLout( $templ, RootName => "job_params" );

	my $xmlString = XMLout(
		$templ,
		KeepRoot   => 1,
		AttrIndent => 0,

		XMLDecl => '<?xml version="1.0" encoding="utf-8"?>'
	);

	my $finalFile = EnumsPaths->Jobs_MDI . $self->{"jobId"} . $layerName . "_mdi.xml";
	$finalFile =~ s/outer//;    # remove "outer" from outer core fake layers

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

	if ( $layer =~ /^[cs]$/ || $layer =~ /^v\d(outer)?$/ ) {

		# Signal layer, plug layers

		if ( $self->{"layerCnt"} > 2 ) {

			# Multilayer PCB

			my $stackup   = $self->{"stackup"};
			my $stackupNC = $self->{"stackupNC"};

			if ( $layer =~ /^[cs]$/ ) {

				# Outer signal layers

				$thick = $self->{"stackup"}->GetFinalThick() / 1000;

				# if via fill, there is extra pre plating
				$thick += 2 * $PREPLTTHICKNESS if ( CamDrilling->GetViaFillExists( $inCAM, $jobId ) );

				$thick += 2 * $PLTTHICKNESS if ( $etchingType eq EnumsGeneral->Etching_TENTING );

			}
			elsif ( $layer =~ /^v\d(outer)?$/ ) {

				# Inner signal layers

				# This method consider progressive lamiantion
				if ( $layer =~ /^v\douter$/ ) {

					# find existing layer which has same core as this fake layer and
					# compute thickness by existing layer
					if ( $layer =~ /^v1outer$/ ) {

						# Top outer layer

						$thick = $stackup->GetThickByLayerName("v2");

					}
					else {

						# Bot outer layer

						$thick = $stackup->GetThickByLayerName( "v" . ( ( $layer =~ /v(\d)outer/ )[0] - 1 ) );

					}

				}
				else {
					$thick = $stackup->GetThickByLayerName($layer);
				}

				# Check if core OR laminated package contains plated NC operation, if so add extra plating
				# For theses case add extra plating from both sides
				my $stackupNCitem = undef;

				for ( my $i = scalar( $stackupNC->GetPressCnt() ) - 1 ; $i > 0 ; $i-- ) {

					my $press = $stackupNC->GetPress($i);

					if ( $press->GetTopSigLayer()->GetName() eq $layer || $press->GetBotSigLayer()->GetName() eq $layer ) {

						$stackupNCitem = $press;
						last;

					}
				}

				# it there is not progress lamination, find cu core
				unless ( defined $stackupNCitem ) {
					my $coreNum = $stackup->GetCoreByCopperLayer($layer)->GetCoreNumber();
					$stackupNCitem = $stackupNC->GetCore($coreNum);

				}

				die "Nor press package or core was not found for copper layer: $layer" if ( !defined $stackupNCitem );

				my @ncLayers = ( $stackupNCitem->GetNCLayers("top"), $stackupNCitem->GetNCLayers("bot") );
				$thick += 2 * $PLTTHICKNESS if ( grep { $_->{"plated"} } @ncLayers );

			}
		}
		else {

			# Single or double layer PCB

			$thick = HegMethods->GetPcbMaterialThick( $self->{"jobId"} );

			$thick += 2 * $PLTTHICKNESS if ( $etchingType eq EnumsGeneral->Etching_TENTING );

		}

	}
	elsif ( $layer =~ /^plg[cs]$/ ) {

		# Plug layers

		if ( $self->{"layerCnt"} > 2 ) {

			$thick = $self->{"stackup"}->GetFinalThick() / 1000;
		}
		else {

			$thick = HegMethods->GetPcbMaterialThick( $self->{"jobId"} );
		}

		$thick += 2 * $PREPLTTHICKNESS;
	}
	elsif ( $layer =~ /^m[cs]2?$/ || $layer =~ /^gold[cs]$/ ) {

		# Solder mask layers

		if ( $self->{"layerCnt"} > 2 ) {

			$thick = $self->{"stackup"}->GetFinalThick() / 1000;
		}
		else {

			$thick = HegMethods->GetPcbMaterialThick( $self->{"jobId"} );
		}

		$thick += 2 * $PLTTHICKNESS if ( $self->{"layerCnt"} >= 2 );

		if ( $layer =~ /^m[cs]2?$/ ) {

			$thick += 2 * $SMTHICNESS;
		}

		if ( $layer =~ /^gold[cs]$/ ) {

			my $smLayer = "m" . ( $layer =~ /^gold([cs])$/ )[0];

			$thick += 2 * $SMTHICNESS if ( CamHelper->LayerExists( $inCAM, $jobId, $smLayer ) )

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

