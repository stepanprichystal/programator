
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
use aliased 'Packages::Technology::DataComp::SigLayerComp';
use aliased 'Packages::Technology::DataComp::NCLayerComp';
use aliased 'Packages::CAMJob::Technology::LayerSettings';

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
	$self->{"sigLayerComp"}    = undef;    # calculating signal layer compensation
	$self->{"NCLayerComp"}     = undef;    # calculating signal layer compensation
	$self->{"profLim"}         = undef;    # panel profile limits
	$self->{"layerSettings"}   = undef;    # Heklper class with default signal, nc and nonstignal settings

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

	return $self->{"layerSettings"}->GetDefSignalLSett($l);

}

# Set polarity, mirro, compensation for board layers
# this is used for OPFX export, tif file export
sub GetSignalLSett {
	my $self = shift;
	my $l    = shift;
	my $plt  = shift;    # Is layer plated

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"layerSettings"}->GetSignalLSett( $l, $plt );
}

# Set polarity, mirro, compensation for board layers
# this is used for OPFX export, tif file export
sub GetNonSignalLSett {
	my $self = shift;
	my $l    = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"layerSettings"}->GetNonSignalLSett($l);
}

# Set stretch X and Y for NC layers
sub GetNCLSett {
	my $self = shift;
	my $l    = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"layerSettings"}->GetNCLSett($l);

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

# Return panel profile limits
# - xMin
# - xMax
# - yMin
# - yMax
sub GetProfileLimits {
	my $self = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return %{ $self->{"profLim"} };
}

# Return default type of technology
sub GetDefaultTechType {
	my $self      = shift;
	my $layerName = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"layerSettings"}->GetDefaultTechType($layerName);

}

sub GetDefaultEtchType {
	my $self      = shift;
	my $layerName = shift;

	die "DefaultInfo object is not inited" unless ( $self->{"init"} );

	return $self->{"layerSettings"}->GetDefaultEtchType($layerName);

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
	CamDrilling->AddNCLayerType( \@NCLayers );
	CamDrilling->AddLayerStartStop( $inCAM, $self->{"jobId"}, \@NCLayers );
	$self->{"NCLayers"} = \@NCLayers;

	$self->{"pcbClass"} = CamJob->GetJobPcbClass( $inCAM, $self->{"jobId"} );

	$self->{"pcbClassInner"} = CamJob->GetJobPcbClassInner( $inCAM, $self->{"jobId"} );

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $inCAM, $self->{"jobId"} );

	$self->{"platedRoutExceed"} = PlatedRoutArea->PlatedAreaExceed( $inCAM, $self->{'jobId'}, $self->{"step"} );

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

	$self->{"sigLayerComp"} = SigLayerComp->new( $inCAM, $self->{"jobId"} );

	$self->{"NCLayerComp"} = NCLayerComp->new( $inCAM, $self->{"jobId"} );

	my %lim = CamJob->GetProfileLimits2( $inCAM, $self->{"jobId"}, $self->{"step"} );
	$self->{"profLim"} = \%lim;

	$self->{"layerSettings"} = LayerSettings->new( $self->{"jobId"}, $self->{"step"} );
	$self->{"layerSettings"}->Init(
									$inCAM,                      $self->{"pcbType"},  $self->{"pcbIsFlex"},    $self->{"pcbClass"},
									$self->{"pcbClassInner"},    $self->{"layerCnt"}, $self->{"sigLayerComp"}, $self->{"NCLayers"},
									$self->{"platedRoutExceed"}, $self->{"surface"},  $self->{"stackupNC"}
	);

	$self->{"init"} = 1;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#	use aliased 'Programs::Exporter::ExportChecker::ExportChecker::DefaultInfo::DefaultInfo';
#	use aliased 'Packages::InCAM::InCAM';
#
#	my $inCAM = InCAM->new();
#
#	my $jobId     = "d266089";
#	my $stepName  = "o+1";
#	my $layerName = "c";
#
#	my $d = DefaultInfo->new($jobId);
#	$d->Init($inCAM);
#	my $tech = $d->GetDefaultTechType("s");
#
#	print $tech;

}

1;

