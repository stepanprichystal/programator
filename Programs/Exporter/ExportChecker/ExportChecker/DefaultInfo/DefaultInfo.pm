
#-------------------------------------------------------------------------------------------#
# Description: This class load/compute default values which consum ExportChecker.
# Here are placed values, which take long time for computation, thus here will be computed
# only once, when ExporterChecker starts.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo;

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
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Technology::EtchOperation';
use aliased 'Packages::Other::CustomerNote';
use aliased 'Packages::Tooling::PressfitOperation';
use aliased 'Packages::Tooling::TolHoleOperation';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::ProductionPanel::PanelDimension';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $jobId = shift;

	my $self = {};
	bless $self;

	$self->{"jobId"} = $jobId;
	$self->{"step"}  = "panel";
	$self->{"init"}  = 0;

	# Defaul values
	$self->{"pcbType"}         = undef;
	$self->{"layerCnt"}        = undef;
	$self->{"stackup"}         = undef;
	$self->{"stackupNC"}       = undef;
	$self->{"pattern"}         = undef;
	$self->{"tenting"}         = undef;
	$self->{"baseLayers"}      = undef;
	$self->{"signalLayers"}    = undef;
	$self->{"signalExtLayers"} = undef;
	$self->{"NCLayers"}        = undef;
	$self->{"scoreChecker"}    = undef;
	$self->{"materialKind"}    = undef;
	$self->{"pcbTypeHelios"}   = undef;    # type by helios oboustranny, neplat etc..
	$self->{"finalPcbThick"}   = undef;
	$self->{"allStepsNames"}   = undef;    # all steps
	$self->{"allLayers"}       = undef;    # all layers
	$self->{"isPool"}          = undef;
	$self->{"surface"}         = undef;
	$self->{"jobAttributes"}   = undef;    # all job attributes
	$self->{"costomerInfo"}    = undef;    # info about customer, name, reference, ...
	$self->{"costomerNote"}    = undef;    # notes about customer, like export paste, info to pdf, ..
	$self->{"pressfitExist"}   = undef;    # if pressfit exist in job
	$self->{"tolHoleExist"}    = undef;    # if tolerance hole exist in job
	$self->{"pcbBaseInfo"}     = undef;    # contain base info about pcb from IS
	$self->{"reorder"}         = undef;    # indicate id in time in export exist reorder
	$self->{"panelType"}       = undef;    # return type of panel from Enums::EnumsProducPanel
	$self->{"pcbSurface"}      = undef;    # surface from IS
	$self->{"pcbThick"}        = undef;    # total thick of pcb
	$self->{"pcbClass"}        = undef;    # pcb class of outer layer
	$self->{"pcbClassInner"}   = undef;    # pcb class of inner layer
	$self->{"pcbIsFlex"}       = undef;    # pcb is flex

	return $self;
}

sub Init {
	my $self = shift;

	# Do not store InCAM object as Object property,
	# becase if is Defalt info used in child thread, InCAM don't work
	my $inCAM = shift;

	$self->__Init($inCAM);

}

sub GetBoardBaseLayers {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return @{ $self->{"baseLayers"} };
}

sub GetSignalLayers {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return @{ $self->{"signalLayers"} };
}

sub GetSignalExtLayers {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return @{ $self->{"signalExtLayers"} };
}

sub GetNCLayers {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return @{ $self->{"NCLayers"} };
}


sub GetPcbClass {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"pcbClass"};
}

sub GetPcbClassInner {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	# take class from "outer" if not defined
	if ( !defined $self->{"pcbClassInner"} || $self->{"pcbClassInner"} == 0 ) {
		return $self->GetPcbClass();
	}

	return $self->{"pcbClassInner"};
}

sub GetLayerCnt {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"layerCnt"};
}

sub GetCompBySigLayer {
	my $self      = shift;
	my $layerName = shift;
	my $plated    = shift;    # EnumsGeneral->Technology_xxx.

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	die "Attr \"plated\" has to be specified" unless ( defined $plated );

	my $class = undef;        # Signal layer construction class

	my %lPars = JobHelper->ParseSignalLayerName($layerName);

	if ( $lPars{"sourceName"} =~ /^v\d+$/ ) {
		$class = $self->GetPcbClassInner();
	}
	else {
		$class = $self->GetPcbClass();
	}

	my $cuThick = $self->GetBaseCuThick( $lPars{"sourceName"} );

	return EtchOperation->GetCompensation( $cuThick, $class, $plated );
}

sub GetScoreChecker {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	my $res = 0;

	if ( $self->{"scoreChecker"} ) {

		return $self->{"scoreChecker"};
	}

}

sub GetPcbType {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"pcbType"};
}

sub GetMaterialKind {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	$self->{"materialKind"} = HegMethods->GetMaterialKind( $self->{"jobId"} );
	return $self->{"materialKind"};
}

sub GetBaseCuThick {
	my $self      = shift;
	my $layerName = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	my $cuThick;
	if ( HegMethods->GetBasePcbInfo( $self->{"jobId"} )->{"pocet_vrstev"} > 2 ) {

		$cuThick = $self->{"stackup"}->GetCuLayer($layerName)->GetThick();

	}
	else {

		$cuThick = HegMethods->GetOuterCuThick( $self->{"jobId"}, $layerName );
	}

	return $cuThick;
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

	if ( $etching eq EnumsGeneral->Etching_ONLY || $lPars{"outerCore"}  ) {
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
		$class = $self->GetPcbClassInner();
	}
	else {
		$class = $self->GetPcbClass();
	}

	my $cuThick = $self->GetBaseCuThick( $lPars{"sourceName"} );

	if ( $self->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER || $lPars{"plugging"} ) {

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

		Diag( "Layer: " . $lSett{"name"} . "; Cu thick: $cuThick; Class: $class; Plated: $plt; EthingType: $etchType" );

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

		my $product = $self->{"stackup"}->GetProductByLayer( $lPars{"sourceName"} );

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
	$lSett{"shrinkX"} = 0;
	$lSett{"shrinkY"} = 0;

	die "Layer name is not defined for layer:" . $l->{"gROWname"}      if ( !defined $lSett{"name"} );
	die "Etching type is not defined for layer:" . $l->{"gROWname"}    if ( !defined $lSett{"etchingType"} );
	die "Technology type is not defined for layer:" . $l->{"gROWname"} if ( !defined $lSett{"technologyType"} );
	die "Compensation is not defined for layer:" . $l->{"gROWname"}    if ( !defined $lSett{"comp"} );
	die "Polarity is not defined for layer:" . $l->{"gROWname"}        if ( !defined $lSett{"polarity"} );
	die "Mirror is not defined for layer:" . $l->{"gROWname"}          if ( !defined $lSett{"mirror"} );
	die "Shrink X is not defined for layer:" . $l->{"gROWname"}        if ( !defined $lSett{"shrinkX"} );
	die "Shrink Y is not defined for layer:" . $l->{"gROWname"}        if ( !defined $lSett{"shrinkY"} );

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
	if ( $l->{"gROWname"} =~ /^mc2?(olec)?$/i || $l->{"gROWname"} =~ /^goldc$/i ) {

		$lSett{"mirror"} = 1;

	}
	 
	# Bot soloder mask and bot gold connector is mirrored
	elsif ( $l->{"gROWname"} =~ /^ms2?(olec)?$/i || $l->{"gROWname"} =~ /^golds$/i ) {

		$lSett{"mirror"} = 0;

	}
	
	# Whatever TOP layer processed by screenprinting do not mirror
	# Priprava sita:
	# |____________|  Sito (sitem dolu)
	#    -------      Fotocitliva pasta
	#   __________    Emulze filmu
	#   __________    Film
	#  	==========    Deska
	if ( $l->{"gROWname"} =~ /^[lgp]c2?$/i ||  $l->{"gROWname"} =~ /^mcflex$/i) {
		$lSett{"mirror"} = 0;
	}
	
	# Whatever BOT layer processed by screenprinting do mirror
	if ( $l->{"gROWname"} =~ /^[lgp]s2?$/i ||  $l->{"gROWname"} =~ /^msflex$/i) {
		$lSett{"mirror"} = 1;
	}
	

	# 3) Set compensation

	$lSett{"comp"} = 0;

	# 6) Set Shrink
	$lSett{"shrinkX"} = 0;
	$lSett{"shrinkY"} = 0;

	die "Layer name is not defined for layer:" . $l->{"gROWname"} if ( !defined $lSett{"name"} );
	die "Polarity is not defined for layer:" . $l->{"gROWname"}   if ( !defined $lSett{"polarity"} );
	die "Mirror is not defined for layer:" . $l->{"gROWname"}     if ( !defined $lSett{"mirror"} );

	die "Compensation is not defined for layer:" . $l->{"gROWname"} if ( !defined $lSett{"comp"} );
	die "Shrink X is not defined for layer:" . $l->{"gROWname"}     if ( !defined $lSett{"shrinkX"} );
	die "Shrink Y is not defined for layer:" . $l->{"gROWname"}     if ( !defined $lSett{"shrinkY"} );

	return %lSett;
}

sub GetStackup {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"stackup"};
}

# Return if step exist Doesn't load from income for each request
sub StepExist {
	my $self     = shift;
	my $stepName = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	my @s = grep { $_ eq $stepName } @{ $self->{"allStepsNames"} };

	if ( scalar(@s) ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Return if layer existDoesn't load from income for each request
sub LayerExist {
	my $self      = shift;
	my $layerName = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	my @l = grep { $_->{"gROWname"} eq $layerName } @{ $self->{"allLayers"} };

	if ( scalar(@l) ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub IsPool {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"isPool"};
}

sub GetJobAttrByName {
	my $self = shift;
	my $attr = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"jobAttributes"}->{$attr};
}

sub GetCustomerNote {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"costomerNote"};
}

sub GetCustomerISInfo {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"costomerInfo"};
}

sub GetPressfitExist {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"pressfitExist"};
}

sub GetToleranceHoleExist {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"tolHoleExist"};
}

sub GetPcbBaseInfo {
	my $self = shift;
	my $key  = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	if ($key) {
		return $self->{"pcbBaseInfo"}->{$key};
	}
	else {
		return $self->{"pcbBaseInfo"};
	}
}

# Return if pressfit existbased on info from IS
sub GetMeritPressfitIS {
	my $self = shift;
	my $key  = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	if ( $self->{"pcbBaseInfo"}->{"merit_presfitt"} =~ /^A$/i ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Return if tolerance hole existbased on info from IS
sub GetToleranceHoleIS {
	my $self = shift;
	my $key  = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	if ( $self->{"pcbBaseInfo"}->{"mereni_tolerance_vrtani"} =~ /^A$/i ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Return if chamfer edge exist in IS
sub GetChamferEdgesIS {
	my $self = shift;
	my $key  = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	if ( $self->{"pcbBaseInfo"}->{"srazeni_hran"} =~ /^A$/i ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Return if any reordr exist for this job id
sub GetIsReorder {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	if ( int( $self->{"reorder"} ) > 1 ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Return type of "produce panel" from Enums::EnumsProducPanel
sub GetPanelType {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"panelType"};
}

# Return pcb surface from IS
sub GetPcbSurface {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"pcbSurface"};
}

# Return total pcb thick from stackup if multiaayer, else from IS (in µm)
sub GetPcbThick {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"pcbThick"};
}

# Return 1 if PCB is flex
sub GetIsFlex {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"pcbIsFlex"};
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

	if ( $self->{"layerCnt"} == 2 ) {

		my @platedNC = grep { $_->{"plated"} && !$_->{"technical"}} $self->GetNCLayers();

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

				if ( $self->{"platedRoutExceed"} || $self->{"rsExist"} ) {
					$etchType = EnumsGeneral->Etching_PATTERN;
				}
			}
		}
	}

	return $etchType;
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __Init {
	my $self  = shift;
	my $inCAM = shift;

	$self->{"pcbType"} = JobHelper->GetPcbType( $self->{"jobId"} );

	my @baseLayers = CamJob->GetBoardBaseLayers( $inCAM, $self->{"jobId"} );
	$self->{"baseLayers"} = \@baseLayers;

	my @signalLayers = CamJob->GetSignalLayer( $inCAM, $self->{"jobId"} );
	$self->{"signalLayers"} = \@signalLayers;

	my @signalExtLayers = CamJob->GetSignalExtLayer( $inCAM, $self->{"jobId"} );
	$self->{"signalExtLayers"} = \@signalExtLayers;

	my @NCLayers = CamJob->GetNCLayers( $inCAM, $self->{"jobId"} );
	CamDrilling->AddNCLayerType(\@NCLayers);
	$self->{"NCLayers"} = \@NCLayers;

	$self->{"pcbClass"} = CamJob->GetJobPcbClass( $inCAM, $self->{"jobId"} );

	$self->{"pcbClassInner"} = CamJob->GetJobPcbClassInner( $inCAM, $self->{"jobId"} );

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $inCAM, $self->{"jobId"} );

	$self->{"platedRoutExceed"} = PlatedRoutArea->PlatedAreaExceed( $inCAM, $self->{'jobId'}, "panel" );

	$self->{"rsExist"} = CamDrilling->NCLayerExists( $inCAM, $self->{'jobId'}, EnumsGeneral->LAYERTYPE_nplt_rsMill );

	if ( $self->{"layerCnt"} > 2 ) {

		$self->{"stackup"} = Stackup->new( $inCAM, $self->{'jobId'} );
		$self->{"stackupNC"} = StackupNC->new( $inCAM, $self->{'jobId'} );
	}

	if ( CamHelper->LayerExists( $inCAM, $self->{"jobId"}, "score" ) ) {

		$self->{"scoreChecker"} = ScoreChecker->new( $inCAM, $self->{"jobId"}, $self->{"step"}, "score", 1 );
		$self->{"scoreChecker"}->Init();
	}

	my @allSteps = CamStep->GetAllStepNames( $inCAM, $self->{"jobId"} );
	$self->{"allStepsNames"} = \@allSteps;    #all steps

	my @allLayers = CamJob->GetAllLayers( $inCAM, $self->{"jobId"} );
	$self->{"allLayers"} = \@allLayers;

	$self->{"isPool"} = HegMethods->GetPcbIsPool( $self->{"jobId"} );

	$self->{"surface"} = HegMethods->GetPcbSurface( $self->{"jobId"} );

	my %jobAtt = CamAttributes->GetJobAttr( $inCAM, $self->{"jobId"} );
	$self->{"jobAttributes"} = \%jobAtt;

	$self->{"costomerInfo"} = HegMethods->GetCustomerInfo( $self->{"jobId"} );

	$self->{"costomerNote"} = CustomerNote->new( $self->{"costomerInfo"}->{"reference_subjektu"} );

	$self->{"pressfitExist"} = PressfitOperation->ExistPressfitJob( $inCAM, $self->{"jobId"}, $self->{"step"}, 1 );

	$self->{"tolHoleExist"} = TolHoleOperation->ExistTolHoleJob( $inCAM, $self->{"jobId"}, $self->{"step"}, 1 );

	$self->{"pcbBaseInfo"} = HegMethods->GetBasePcbInfo( $self->{"jobId"} );

	$self->{"reorder"} = HegMethods->GetPcbOrderNumber( $self->{"jobId"} );

	$self->{"panelType"} = PanelDimension->GetPanelType( $inCAM, $self->{"jobId"} );

	$self->{"pcbSurface"} = HegMethods->GetPcbSurface( $self->{"jobId"} );

	$self->{"pcbThick"} = CamJob->GetFinalPcbThick( $inCAM, $self->{"jobId"} );

	$self->{"pcbIsFlex"} = JobHelper->GetIsFlex( $self->{"jobId"} );

	$self->{"init"} = 1;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId     = "d240127";
	my $stepName  = "o+1";
	my $layerName = "c";

	my $d = DefaultInfo->new( $inCAM, $jobId );
	$d->GetDefaultEtchType("c");
}

1;

