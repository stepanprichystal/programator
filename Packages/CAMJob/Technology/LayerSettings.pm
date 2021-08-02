
#-------------------------------------------------------------------------------------------#
# Description: This class load/compute default values which consum ExportChecker.
# Here are placed values, which take long time for computation, thus here will be computed
# only once, when ExporterChecker starts.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Technology::LayerSettings;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Tests::Test';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums' => 'StackupEnums';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';
use aliased 'Packages::Routing::PlatedRoutArea';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Technology::EtchOperation';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Technology::DataComp::SigLayerComp';
use aliased 'Packages::Technology::DataComp::NCLayerComp';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $jobId = shift;
	my $step  = shift // "panel";

	my $self = {};
	bless $self;

	$self->{"jobId"} = $jobId;
	$self->{"step"}  = $step;
	$self->{"init"}  = 0;

	return $self;
}

sub Init {
	my $self  = shift;
	my $inCAM = shift;

	# Optional pre-loaded parametrs

	$self->{"pcbType"}          = shift;
	$self->{"pcbIsFlex"}        = shift;
	$self->{"pcbClass"}         = shift;
	$self->{"pcbClassInner"}    = shift;
	$self->{"layerCnt"}         = shift;
	$self->{"sigLayerComp"}     = shift;
	$self->{"NCLayerComp"}      = shift;
	$self->{"NCLayers"}         = shift;
	$self->{"platedRoutExceed"} = shift;
	$self->{"surface"}          = shift;
	$self->{"stackupNC"}        = shift;

	unless ( defined $self->{"pcbType"} ) {
		$self->{"pcbType"} = JobHelper->GetPcbType( $self->{"jobId"} );
	}

	unless ( defined $self->{"pcbIsFlex"} ) {
		$self->{"pcbIsFlex"} = JobHelper->GetIsFlex( $self->{"jobId"} );
	}

	unless ( defined $self->{"pcbClass"} ) {

		$self->{"pcbClass"} = CamJob->GetJobPcbClass( $inCAM, $self->{"jobId"} );
	}

	unless ( defined $self->{"pcbClassInner"} ) {
		$self->{"pcbClassInner"} = CamJob->GetJobPcbClass( $inCAM, $self->{"jobId"} );
	}

	unless ( defined $self->{"layerCnt"} ) {

		$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $inCAM, $self->{"jobId"} );
	}

	unless ( defined $self->{"sigLayerComp"} ) {
		$self->{"sigLayerComp"} = SigLayerComp->new( $inCAM, $self->{"jobId"}, $self->{"step"} );
	}

	unless ( defined $self->{"NCLayers"} ) {
		my @NCLayers = CamJob->GetNCLayers( $inCAM, $self->{"jobId"} );
		CamDrilling->AddNCLayerType( \@NCLayers );
		CamDrilling->AddLayerStartStop( $inCAM, $self->{"jobId"}, \@NCLayers );
		$self->{"NCLayers"} = \@NCLayers;
	}

	unless ( defined $self->{"platedRoutExceed"} ) {
		$self->{"platedRoutExceed"} = PlatedRoutArea->PlatedAreaExceed( $inCAM, $self->{'jobId'}, $self->{"step"} );
	}

	unless ( defined $self->{"surface"} ) {
		$self->{"surface"} = HegMethods->GetPcbSurface( $self->{"jobId"} );
	}

	unless ( defined $self->{"stackupNC"} ) {
		if ( $self->{"layerCnt"} > 2 ) {

			$self->{"stackupNC"} = StackupNC->new( $inCAM, $self->{'jobId'} );
		}
	}

	$self->{"rsExist"} = CamDrilling->NCLayerExists( $inCAM, $self->{'jobId'}, EnumsGeneral->LAYERTYPE_nplt_rsMill );

	$self->{"init"} = 1;
}

# Set polarity, mirro, compensation for board layers
# this is used for OPFX export, tif file export
sub GetDefSignalLSett {
	my $self = shift;
	my $l    = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	my %lPars = JobHelper->ParseSignalLayerName( $l->{"gROWname"} );

	my $etching = $self->GetDefaultEtchType( $l->{"gROWname"} );
	my $plt     = 1;

	if ( $etching eq EnumsGeneral->Etching_ONLY || $lPars{"outerCore"} ) {
		$plt = 0;
	}

	my $technology = $self->GetDefaultTechType( $l->{"gROWname"} );

	my %lSett = $self->GetSignalLSett( $l, $plt, $etching, $technology );

	return %lSett;

}

# Set polarity, mirro, compensation for board layers
# this is used for OPFX export, tif file export
sub GetSignalLSett {
	my $self = shift;
	my $l    = shift;
	my $plt  = shift;    # Is layer plated

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	# EnumsGeneral->Etching_PATTERN
	# EnumsGeneral->Etching_TENTING
	my $etchType = shift;

	# EnumsGeneral->Technology_GALVANICS
	# EnumsGeneral->Technology_RESIST
	my $technology = shift;

	die "Signal layer si not allowed"
	  if (    $l->{"gROWlayer_type"} ne "signal"
		   && $l->{"gROWlayer_type"} ne "power_ground"
		   && $l->{"gROWlayer_type"} eq "mixed" );

	my %lPars = JobHelper->ParseSignalLayerName( $l->{"gROWname"} );

	my %lSett = ( "name" => $l->{"gROWname"} );

	# 1) Set etching type

	$lSett{"etchingType"} = $etchType;

	# 2) Settechnology type

	$lSett{"technologyType"} = $technology;

	# 3) Set compensation

	my $class = undef;    # Signal layer construction class

	if ( $lPars{"sourceName"} =~ /^v\d+$/ ) {
		$class = $self->__GetPcbClassInner();
	}
	else {
		$class = $self->__GetPcbClass();
	}

	my $cuThick = $self->__GetBaseCuThick( $lPars{"sourceName"} );

	if ( $self->__GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER || $lPars{"plugging"} ) {

		$lSett{"comp"} = 0;
	}
	else {

		my $comp = EtchOperation->GetCompensation( $cuThick, $class, $plt, $etchType );

		# If layer is negative, set negative compensation
		if ( defined $comp && $l->{"gROWpolarity"} eq "negative" ) {
			$comp = -$comp;
		}

		unless ( defined $comp ) {
			$comp = "NaN";
		}

		$lSett{"comp"} = $comp;

		#Diag( "Layer: " . $lSett{"name"} . "; Cu thick: $cuThick; Class: $class; Plated: $plt; EthingType: $etchType" );

	}

	# 4) Set polarity by etching type
	if ( $etchType eq EnumsGeneral->Etching_PATTERN ) {
		$lSett{"polarity"} = "positive";
	}
	elsif ( $etchType eq EnumsGeneral->Etching_TENTING || $etchType eq EnumsGeneral->Etching_ONLY ) {
		$lSett{"polarity"} = "negative";
	}

	# 5) Exception for layer c, s and Galvanic gold. Polarity always postitive
	if ( $l->{"gROWname"} eq "c" || $l->{"gROWname"} eq "s" ) {

		if ( $self->{"surface"} =~ /g/i ) {
			$lSett{"polarity"} = "positive";
		}
	}

	#Switch polarity, if layer is NEGATIVE in InCAM matrix
	if ( $l->{"gROWpolarity"} eq "negative" ) {

		if ( $lSett{"polarity"} eq "negative" ) {
			$lSett{"polarity"} = "positive";
		}
		elsif ( $lSett{"polarity"} eq "positive" ) {
			$lSett{"polarity"} = "negative";
		}
	}

	# 6) Set mirror
	if ( $lPars{"sourceName"} =~ /^c$/i ) {
		$lSett{"mirror"} = 1;
	}
	elsif ( $lPars{"sourceName"} =~ /^s$/i ) {
		$lSett{"mirror"} = 0;
	}

	elsif ( $lPars{"sourceName"} =~ /^v\d+$/i ) {

		my $side = undef;

		my $product = $self->{"stackupNC"}->GetProductByLayer( $lPars{"sourceName"} );

		if ( $lPars{"sourceName"} eq $product->GetTopCopperLayer() ) {

			$side = "top";
		}
		elsif ( $lPars{"sourceName"} eq $product->GetBotCopperLayer() ) {

			$side = "bot";
		}

		if ( $side eq "top" ) {

			$lSett{"mirror"} = 1;

		}
		else {

			$lSett{"mirror"} = 0;
		}
	}

	# 7) Set Shrink
	my %matComp = $self->{"sigLayerComp"}->GetLayerCompensation( $l->{"gROWname"} );
	$lSett{"stretchX"} = $matComp{"x"};
	$lSett{"stretchY"} = $matComp{"y"};

	die "Layer name is not defined for layer:" . $l->{"gROWname"}      if ( !defined $lSett{"name"} );
	die "Etching type is not defined for layer:" . $l->{"gROWname"}    if ( !defined $lSett{"etchingType"} );
	die "Technology type is not defined for layer:" . $l->{"gROWname"} if ( !defined $lSett{"technologyType"} );
	die "Compensation is not defined for layer:" . $l->{"gROWname"}    if ( !defined $lSett{"comp"} );
	die "Polarity is not defined for layer:" . $l->{"gROWname"}        if ( !defined $lSett{"polarity"} );
	die "Mirror is not defined for layer:" . $l->{"gROWname"}          if ( !defined $lSett{"mirror"} );
	die "Shrink X is not defined for layer:" . $l->{"gROWname"}        if ( !defined $lSett{"stretchX"} );
	die "Shrink Y is not defined for layer:" . $l->{"gROWname"}        if ( !defined $lSett{"stretchY"} );

	return %lSett;
}

# Set polarity, mirro, compensation for board layers
# this is used for OPFX export, tif file export
sub GetNonSignalLSett {
	my $self = shift;
	my $l    = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	die "Signal layer si not allowed"
	  if (    $l->{"gROWlayer_type"} eq "signal"
		   || $l->{"gROWlayer_type"} eq "power_ground"
		   || $l->{"gROWlayer_type"} eq "mixed" );

	my %lSett = ( "name" => $l->{"gROWname"} );

	# 1) Set polarity

	if ( $l->{"gROWlayer_type"} eq "silk_screen" ) {

		$lSett{"polarity"} = "negative";

	}
	elsif ( $l->{"gROWlayer_type"} eq "solder_mask" ) {

		$lSett{"polarity"} = "positive";

	}
	else {
		$lSett{"polarity"} = "positive";
	}

	# 2) Set mirror

	# Top soloder mask and top gold connector is mirrored
	if ( $l->{"gROWname"} =~ /^[pm]c2?(olec)?$/i || $l->{"gROWname"} =~ /^goldc$/i ) {

		$lSett{"mirror"} = 1;

	}

	# Bot soloder mask and bot gold connector is mirrored
	elsif ( $l->{"gROWname"} =~ /^[pm]s2?(olec)?$/i || $l->{"gROWname"} =~ /^golds$/i ) {

		$lSett{"mirror"} = 0;

	}

	# Whatever TOP layer processed by screenprinting do not mirror
	# Priprava sita:
	# |____________|  Sito (sitem dolu)
	#    -------      Fotocitliva pasta
	#   __________    Emulze filmu
	#   __________    Film
	#  	==========    Deska
	if ( $l->{"gROWname"} =~ /^[lg]c2?$/i || $l->{"gROWname"} =~ /^mcflex$/i ) {
		$lSett{"mirror"} = 0;
	}

	# Whatever BOT layer processed by screenprinting do mirror
	if ( $l->{"gROWname"} =~ /^[lg]s2?$/i || $l->{"gROWname"} =~ /^msflex$/i ) {
		$lSett{"mirror"} = 1;
	}

	# 3) Set compensation

	$lSett{"comp"} = 0;

	# 6) Set Shrink
	$lSett{"stretchX"} = 0;
	$lSett{"stretchY"} = 0;

	die "Layer name is not defined for layer:" . $l->{"gROWname"} if ( !defined $lSett{"name"} );
	die "Polarity is not defined for layer:" . $l->{"gROWname"}   if ( !defined $lSett{"polarity"} );
	die "Mirror is not defined for layer:" . $l->{"gROWname"}     if ( !defined $lSett{"mirror"} );

	die "Compensation is not defined for layer:" . $l->{"gROWname"} if ( !defined $lSett{"comp"} );
	die "Shrink X is not defined for layer:" . $l->{"gROWname"}     if ( !defined $lSett{"stretchX"} );
	die "Shrink Y is not defined for layer:" . $l->{"gROWname"}     if ( !defined $lSett{"stretchY"} );

	return %lSett;
}

# Set stretch X and Y for NC layers
sub GetNCLSett {
	my $self = shift;
	my $l    = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	my %lSett = ( "name" => $l->{"gROWname"} );

	my %matComp = $self->{"NCLayerComp"}->GetLayerCompensation( $l->{"gROWname"} );
	$lSett{"stretchX"} = $matComp{"x"};
	$lSett{"stretchY"} = $matComp{"y"};

	die "Layer name is not defined for layer:" . $l->{"gROWname"} if ( !defined $lSett{"name"} );
	die "Stretch X is not defined for layer:" . $l->{"gROWname"}  if ( !defined $lSett{"stretchX"} );
	die "Stretch Y is not defined for layer:" . $l->{"gROWname"}  if ( !defined $lSett{"stretchY"} );

	return %lSett;
}

# Return default type of technology
sub GetDefaultTechType {
	my $self      = shift;
	my $layerName = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	my $platedNC = 0;

	# Default type of plating is Etching only
	my $techType = EnumsGeneral->Technology_RESIST;

	my $etch = $self->GetDefaultEtchType($layerName);

	if ( $etch ne EnumsGeneral->Etching_ONLY ) {

		$techType = EnumsGeneral->Technology_GALVANICS;
	}

	return $techType;

}

sub GetDefaultEtchType {
	my $self      = shift;
	my $layerName = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	my $platedNC = 0;

	# Default type of plating is Etching only
	my $etchType = EnumsGeneral->Etching_ONLY;

	if ( $self->{"layerCnt"} == 2 && $self->{"pcbType"} ne EnumsGeneral->PcbType_1VFLEX ) {

		# Flex has always two copper even if it is Single sided

		my @platedNC = grep { $_->{"plated"} && !$_->{"technical"} } $self->__GetNCLayers();

		if ( scalar(@platedNC) ) {

			my @viaFill = grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill } @platedNC;

			if ( $self->{"platedRoutExceed"} || $self->{"rsExist"} || $self->{"pcbIsFlex"} || scalar(@viaFill) ) {
				$etchType = EnumsGeneral->Etching_PATTERN;
			}
			else {
				$etchType = EnumsGeneral->Etching_TENTING;
			}
		}
	}
	elsif ( $self->{"layerCnt"} > 2 ) {

		# Parse signal layer name
		my %lPars = JobHelper->ParseSignalLayerName($layerName);
		my $NCproduct = $self->{"stackupNC"}->GetNCProductByLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

		if (    $NCproduct->ExistNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_bDrillTop, 1 )
			 || $NCproduct->ExistNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_nFillDrill,    1 )
			 || $NCproduct->ExistNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop, 1 )
			 || $NCproduct->ExistNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_cFillDrill,    1 )
			 || $NCproduct->ExistNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_bDrillBot,     1 )
			 || $NCproduct->ExistNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot, 1 ) )
		{
			# if top core layer contains a blind drill top -> pattern (e.g. when 4vv stackup is make from 2 cores)

			$etchType = EnumsGeneral->Etching_PATTERN;

		}
		elsif (    $NCproduct->ExistNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_cDrill, 1 )
				|| $NCproduct->ExistNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_nDrill,   1 )
				|| $NCproduct->ExistNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_bMillTop, 1 )
				|| $NCproduct->ExistNCLayers( undef, undef, EnumsGeneral->LAYERTYPE_plt_bMillBot, 1 ) )
		{

			# if top core layer contains any other plated drill/rout

			$etchType = EnumsGeneral->Etching_TENTING;
		}

		# 3) Check on plated rout most outer layers (only when surface is not hard galvanic gold)

		if ( $layerName eq "c" || $layerName eq "s" ) {

			if ( $self->{"surface"} !~ /g/i ) {

				if ( $self->{"platedRoutExceed"} || $self->{"rsExist"} || $self->__GetPcbClass() == 9 ) {
					$etchType = EnumsGeneral->Etching_PATTERN;
				}
			}
		}
	}

	return $etchType;
}

sub __GetPcbClass {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"pcbClass"};
}

sub __GetPcbClassInner {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	# take class from "outer" if not defined
	if ( !defined $self->{"pcbClassInner"} || $self->{"pcbClassInner"} == 0 ) {
		return $self->__GetPcbClass();
	}

	return $self->{"pcbClassInner"};
}

sub __GetNCLayers {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return @{ $self->{"NCLayers"} };
}

sub __GetPcbType {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"pcbType"};
}

sub __GetBaseCuThick {
	my $self      = shift;
	my $layerName = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	my $cuThick;
	if ( $self->{"layerCnt"} > 2 ) {

		$cuThick = $self->{"stackupNC"}->GetCuLayer($layerName)->GetThick();
	}
	else {

		$cuThick = HegMethods->GetOuterCuThick( $self->{"jobId"}, $layerName );
	}

	return $cuThick;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	Packages::CAMJob::Technology::LayerSettings

	use aliased 'Packages::CAMJob::Technology::LayerSettings';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId     = "d320380";
	my $stepName  = "o+1";
	my $layerName = "c";

	my $d = LayerSettings->new($jobId);
	$d->Init($inCAM);
	my $tech = $d->GetDefSignalLSett("c");

	print $tech;

}

1;

