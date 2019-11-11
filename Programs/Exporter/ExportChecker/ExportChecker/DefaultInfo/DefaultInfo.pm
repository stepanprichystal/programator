
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
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = "panel";

	# Defaul values
	$self->{"layerCnt"}      = undef;
	$self->{"stackup"}       = undef;
	$self->{"stackupNC"}     = undef;
	$self->{"pattern"}       = undef;
	$self->{"tenting"}       = undef;
	$self->{"baseLayers"}    = undef;
	$self->{"signalLayers"}  = undef;
	$self->{"scoreChecker"}  = undef;
	$self->{"materialKind"}  = undef;
	$self->{"pcbTypeHelios"} = undef;    # type by helios oboustranny, neplat etc..
	$self->{"finalPcbThick"} = undef;
	$self->{"allStepsNames"} = undef;    # all steps
	$self->{"allLayers"}     = undef;    # all layers
	$self->{"isPool"}        = undef;
	$self->{"surface"}       = undef;
	$self->{"jobAttributes"} = undef;    # all job attributes
	$self->{"costomerInfo"}  = undef;    # info about customer, name, reference, ...
	$self->{"costomerNote"}  = undef;    # notes about customer, like export paste, info to pdf, ..
	$self->{"pressfitExist"} = undef;    # if pressfit exist in job
	$self->{"tolHoleExist"}  = undef;    # if tolerance hole exist in job
	$self->{"pcbBaseInfo"}   = undef;    # contain base info about pcb from IS
	$self->{"reorder"}       = undef;    # indicate id in time in export exist reorder
	$self->{"panelType"}     = undef;    # return type of panel from Enums::EnumsProducPanel
	$self->{"pcbSurface"}    = undef;    # surface from IS
	$self->{"pcbThick"}      = undef;    # total thick of pcb
	$self->{"pcbClass"}      = undef;    # pcb class of outer layer
	$self->{"pcbClassInner"} = undef;    # pcb class of inner layer
	$self->{"pcbIsFlex"}     = undef;    # pcb is flex

	$self->__InitDefault();

	return $self;
}

sub GetBoardBaseLayers {
	my $self = shift;

	return @{ $self->{"baseLayers"} };
}

sub GetSignalLayers {
	my $self = shift;

	return @{ $self->{"signalLayers"} };
}

sub GetPcbClass {
	my $self = shift;

	return $self->{"pcbClass"};
}

sub GetPcbClassInner {
	my $self = shift;

	# take class from "outer" if not defined
	if ( !defined $self->{"pcbClassInner"} || $self->{"pcbClassInner"} == 0 ) {
		return $self->GetPcbClass();
	}

	return $self->{"pcbClassInner"};
}

sub GetLayerCnt {
	my $self = shift;

	return $self->{"layerCnt"};
}

# Return if Cu layer has orientation TOP/BOT
# Orientation is based on view pcb from top
sub GetSideByLayer {
	my $self      = shift;
	my $layerName = shift;

	my $side = StackupOperation->GetSideByLayer( $self->{"jobId"}, $layerName, $self->{"stackup"} );

	return $side;
}

sub GetCompBySigLayer {
	my $self      = shift;
	my $layerName = shift;
	my $plated    = shift;    # EnumsGeneral->Technology_xxx.

	die "Attr \"plated\" has to be specified" unless ( defined $plated );

	my $class = undef;        # Signal layer construction class

	if ( $layerName =~ /^v\d+(outer)?$/ ) {
		$class = $self->GetPcbClassInner();
	}
	else {
		$class = $self->GetPcbClass();
	}

	my $layerNameCu = $layerName;

	if ( $layerName =~ m/^v(\d+)outer$/ ) {

		$layerNameCu = $1 == 1 ? "c" : "s";
	}

	my $cuThick = $self->GetBaseCuThick($layerNameCu);

	return EtchOperation->GetCompensation( $cuThick, $class, $plated );
}

sub GetScoreChecker {
	my $self = shift;

	my $res = 0;

	if ( $self->{"scoreChecker"} ) {

		return $self->{"scoreChecker"};
	}

}

sub GetTypeOfPcb {
	my $self = shift;

	$self->{"pcbTypeHelios"} = HegMethods->GetTypeOfPcb( $self->{"jobId"} );
	return $self->{"pcbTypeHelios"};
}

sub GetMaterialKind {
	my $self = shift;

	$self->{"materialKind"} = HegMethods->GetMaterialKind( $self->{"jobId"} );
	return $self->{"materialKind"};
}

sub GetBaseCuThick {
	my $self      = shift;
	my $layerName = shift;

	my $cuThick;
	if ( HegMethods->GetBasePcbInfo( $self->{"jobId"} )->{"pocet_vrstev"} > 2 ) {

		$self->{"stackup"} = Stackup->new( $self->{"inCAM"}, $self->{"jobId"} );

		my $cuLayer = $self->{"stackup"}->GetCuLayer($layerName);
		$cuThick = $cuLayer->GetThick();
	}
	else {

		$cuThick = HegMethods->GetOuterCuThick( $self->{"jobId"}, $layerName );
	}

	return $cuThick;
}

## Set polarity, mirro, compensation for board layers
## this is used for OPFX export, tif file export
#sub SetDefaultLayersSettings {
#	my $self   = shift;
#	my $layers = shift;
#
#	# Set polarity of layers
#	foreach my $l ( @{$layers} ) {
#
#		if ( $l->{"gROWlayer_type"} eq "silk_screen" ) {
#
#			$l->{"polarity"} = "negative";
#
#		}
#		elsif ( $l->{"gROWlayer_type"} eq "solder_mask" ) {
#
#			$l->{"polarity"} = "positive";
#
#		}
#		elsif (    $l->{"gROWlayer_type"} eq "signal"
#				|| $l->{"gROWlayer_type"} eq "power_ground"
#				|| $l->{"gROWlayer_type"} eq "mixed"
#				|| $l->{"gROWname"} =~ /^v\d+(outer)?$/i )
#		{
#
#			# 1) set etching type
#			my $etching = $self->GetDefaultEtchType( $l->{"gROWname"} );
#
#			$l->{"etchingType"} = $etching;
#
#			# 2) Set polarity by etching type
#			if ( $etching eq EnumsGeneral->Etching_PATTERN ) {
#				$l->{"polarity"} = "positive";
#			}
#			elsif ( $etching eq EnumsGeneral->Etching_TENTING || $etching eq EnumsGeneral->Etching_ONLY ) {
#				$l->{"polarity"} = "negative";
#			}
#
#			# 3) Exception for layer c, s and Galvanic gold. Polarity always postitive
#			if ( $l->{"gROWname"} eq "c" || $l->{"gROWname"} eq "s" ) {
#
#				if ( $self->{"surface"} =~ /g/i ) {
#					$l->{"polarity"} = "positive";
#				}
#			}
#
#			# 4) Edit polarity according InCAM matrix polarity
#			# if polarity negative, switch polarity
#			if ( $l->{"gROWpolarity"} eq "negative" ) {
#
#				if ( $l->{"polarity"} eq "negative" ) {
#					$l->{"polarity"} = "positive";
#
#				}
#				elsif ( $l->{"polarity"} eq "positive" ) {
#					$l->{"polarity"} = "negative";
#				}
#
#			}
#
#		}
#		else {
#
#			$l->{"polarity"} = "positive";
#
#		}
#	}
#
#	# Set mirror of layers
#	foreach my $l ( @{$layers} ) {
#
#		# whatever with "c" is mirrored
#		if ( $l->{"gROWname"} =~ /^[pm]*c2?$/i ) {
#
#			$l->{"mirror"} = 1;
#
#		}
#
#		# whatever with "s" is not mirrored
#		elsif ( $l->{"gROWname"} =~ /^[pm]*s2?$/i ) {
#
#			$l->{"mirror"} = 0;
#
#		}
#
#		# inner layers decide by stackup
#		elsif ( $l->{"gROWname"} =~ /^v\d+(outer)?$/i ) {
#
#			my $side = $self->GetSideByLayer( $l->{"gROWname"} );
#
#			if ( $side eq "top" ) {
#
#				$l->{"mirror"} = 1;
#
#			}
#			else {
#
#				$l->{"mirror"} = 0;
#			}
#		}
#
#		# if layer end with c, mirror
#		elsif ( $l->{"gROWname"} =~ /c$/i ) {
#
#			$l->{"mirror"} = 1;
#
#		}    # if layer end with s, mirror
#		elsif ( $l->{"gROWname"} =~ /s$/i ) {
#
#			$l->{"mirror"} = 0;
#
#		}
#	}
#
#	# Set compensation of signal layer
#	foreach my $l ( @{$layers} ) {
#
#		if (    $l->{"gROWlayer_type"} eq "signal"
#			 || $l->{"gROWlayer_type"} eq "power_ground"
#			 || $l->{"gROWlayer_type"} eq "mixed"
#			 || $l->{"gROWname"} =~ /^v\d+(outer)?$/i )
#		{
#
#			$l->{"comp"} = $self->GetDefaultCompByLayer( $l->{"gROWname"} );
#
#			# If layer is negative, set negative compensation
#			if ( defined $l->{"comp"} && $l->{"gROWpolarity"} eq "negative" ) {
#				$l->{"comp"} = -$l->{"comp"};
#			}
#
#			unless ( defined $l->{"comp"} ) {
#				$l->{"comp"} = "NaN";
#			}
#
#		}
#		else {
#
#			$l->{"comp"} = 0;
#
#		}
#	}
#
#}

## Set polarity, mirro, compensation for board layers
## this is used for OPFX export, tif file export
#sub GetDefaultNonSignalLSett {
#	my $self   = shift;
#	my $layers = shift;
#
#	# Set polarity of layers
#	foreach my $l ( @{$layers} ) {
#
#		if ( $l->{"gROWlayer_type"} eq "silk_screen" ) {
#
#			$l->{"polarity"} = "negative";
#
#		}
#		elsif ( $l->{"gROWlayer_type"} eq "solder_mask" ) {
#
#			$l->{"polarity"} = "positive";
#
#		}
#		elsif (    $l->{"gROWlayer_type"} eq "signal"
#				|| $l->{"gROWlayer_type"} eq "power_ground"
#				|| $l->{"gROWlayer_type"} eq "mixed"
#				|| $l->{"gROWname"} =~ /^v\d+(outer)?$/i )
#		{
#
#			# 1) set etching type
#			my $etching = $self->GetDefaultEtchType( $l->{"gROWname"} );
#
#			$l->{"etchingType"} = $etching;
#
#			# 2) Set polarity by etching type
#			if ( $etching eq EnumsGeneral->Etching_PATTERN ) {
#				$l->{"polarity"} = "positive";
#			}
#			elsif ( $etching eq EnumsGeneral->Etching_TENTING || $etching eq EnumsGeneral->Etching_ONLY ) {
#				$l->{"polarity"} = "negative";
#			}
#
#			# 3) Exception for layer c, s and Galvanic gold. Polarity always postitive
#			if ( $l->{"gROWname"} eq "c" || $l->{"gROWname"} eq "s" ) {
#
#				if ( $self->{"surface"} =~ /g/i ) {
#					$l->{"polarity"} = "positive";
#				}
#			}
#
#			# 4) Edit polarity according InCAM matrix polarity
#			# if polarity negative, switch polarity
#			if ( $l->{"gROWpolarity"} eq "negative" ) {
#
#				if ( $l->{"polarity"} eq "negative" ) {
#					$l->{"polarity"} = "positive";
#
#				}
#				elsif ( $l->{"polarity"} eq "positive" ) {
#					$l->{"polarity"} = "negative";
#				}
#
#			}
#
#		}
#		else {
#
#			$l->{"polarity"} = "positive";
#
#		}
#	}
#
#	# Set mirror of layers
#	foreach my $l ( @{$layers} ) {
#
#		# whatever with "c" is mirrored
#		if ( $l->{"gROWname"} =~ /^[pm]*c2?$/i ) {
#
#			$l->{"mirror"} = 1;
#
#		}
#
#		# whatever with "s" is not mirrored
#		elsif ( $l->{"gROWname"} =~ /^[pm]*s2?$/i ) {
#
#			$l->{"mirror"} = 0;
#
#		}
#
#		# inner layers decide by stackup
#		elsif ( $l->{"gROWname"} =~ /^v\d+(outer)?$/i ) {
#
#			my $side = $self->GetSideByLayer( $l->{"gROWname"} );
#
#			if ( $side eq "top" ) {
#
#				$l->{"mirror"} = 1;
#
#			}
#			else {
#
#				$l->{"mirror"} = 0;
#			}
#		}
#
#		# if layer end with c, mirror
#		elsif ( $l->{"gROWname"} =~ /c$/i ) {
#
#			$l->{"mirror"} = 1;
#
#		}    # if layer end with s, mirror
#		elsif ( $l->{"gROWname"} =~ /s$/i ) {
#
#			$l->{"mirror"} = 0;
#
#		}
#	}
#
#	# Set compensation of signal layer
#	foreach my $l ( @{$layers} ) {
#
#		if (    $l->{"gROWlayer_type"} eq "signal"
#			 || $l->{"gROWlayer_type"} eq "power_ground"
#			 || $l->{"gROWlayer_type"} eq "mixed"
#			 || $l->{"gROWname"} =~ /^v\d+(outer)?$/i )
#		{
#
#			$l->{"comp"} = $self->GetDefaultCompByLayer( $l->{"gROWname"} );
#
#		}
#		else {
#
#			$l->{"comp"} = 0;
#
#		}
#	}
#
#}

# Set polarity, mirro, compensation for board layers
# this is used for OPFX export, tif file export
sub GetDefSignalLSett {
	my $self = shift;
	my $l    = shift;

	my $etching = $self->__GetDefaultEtchType( $l->{"gROWname"} );
	my $plt = $etching eq EnumsGeneral->Etching_ONLY ? 0 : 1;

	my %lSett = $self->GetSignalLSett( $l, $plt, $etching );

	return %lSett;

}

# Set polarity, mirro, compensation for board layers
# this is used for OPFX export, tif file export
sub GetSignalLSett {
	my $self = shift;
	my $l    = shift;
	my $plt  = shift;    # Is layer plated

	# EnumsGeneral->Etching_PATTERN
	# EnumsGeneral->Etching_TENTING
	my $etchType = shift;

	die "Signal layer si not allowed"
	  if (    $l->{"gROWlayer_type"} ne "signal"
		   && $l->{"gROWlayer_type"} ne "power_ground"
		   && $l->{"gROWlayer_type"} eq "mixed" );

	my %lSett = ();

	# 1) Set etching type

	$lSett{"etchingType"} = $etchType;

	# 2) Set compensation

	my $class = undef;    # Signal layer construction class

	if ( $l->{"gROWname"} =~ /^v\d+(outer)?$/ ) {
		$class = $self->GetPcbClassInner();
	}
	else {
		$class = $self->GetPcbClass();
	}

	my $layerNameCu = $l->{"gROWname"};

	# if fake outer layer, take cu from c or s signal layer
	if ( $layerNameCu =~ m/^v(\d+)outer$/ ) {
		$layerNameCu = $1 == 1 ? "c" : "s";
	}

	my $cuThick = $self->GetBaseCuThick($layerNameCu);

	if ( $self->GetTypeOfPcb() eq 'Neplatovany' ) {

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
	}

	# 3) Set polarity by etching type
	if ( $etchType eq EnumsGeneral->Etching_PATTERN ) {
		$lSett{"polarity"} = "positive";
	}
	elsif ( $etchType eq EnumsGeneral->Etching_TENTING || $etchType eq EnumsGeneral->Etching_ONLY ) {
		$lSett{"polarity"} = "negative";
	}

	# 4) Exception for layer c, s and Galvanic gold. Polarity always postitive
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

	# 5) Set mirror
	if ( $l->{"gROWname"} =~ /^c$/i ) {
		$lSett{"mirror"} = 1;
	}
	elsif ( $l->{"gROWname"} =~ /^s$/i ) {
		$lSett{"mirror"} = 0;
	}

	elsif ( $l->{"gROWname"} =~ /^v\d+(outer)?$/i ) {

		my $side = $self->GetSideByLayer( $l->{"gROWname"} );

		if ( $side eq "top" ) {

			$lSett{"mirror"} = 1;

		}
		else {

			$lSett{"mirror"} = 0;
		}
	}

	# 6) Set Shrink
	$lSett{"shrinkX"} = 0;
	$lSett{"shrinkY"} = 0;

	die "Etching type is not defined for layer:" . $self->{"gROWname"} if ( !defined $lSett{"etchingType"} );
	die "Compensation is not defined for layer:" . $self->{"gROWname"} if ( !defined $lSett{"comp"} );
	die "Polarity is not defined for layer:" . $self->{"gROWname"}     if ( !defined $lSett{"polarity"} );
	die "Mirror is not defined for layer:" . $self->{"gROWname"}       if ( !defined $lSett{"mirror"} );
	die "Shrink X is not defined for layer:" . $self->{"gROWname"}     if ( !defined $lSett{"shrinkX"} );
	die "Shrink Y is not defined for layer:" . $self->{"gROWname"}     if ( !defined $lSett{"shrinkY"} );

	return %lSett;
}

# Set polarity, mirro, compensation for board layers
# this is used for OPFX export, tif file export
sub GetNonSignalLSett {
	my $self = shift;
	my $l    = shift;

	die "Signal layer si not allowed"
	  if (    $l->{"gROWlayer_type"} eq "signal"
		   || $l->{"gROWlayer_type"} eq "power_ground"
		   || $l->{"gROWlayer_type"} eq "mixed" );

	my %lSett = ();

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

	# whatever with "c" is mirrored
	if ( $l->{"gROWname"} =~ /^[pm]*c2?(flex)?$/i ) {

		$lSett{"mirror"} = 1;

	}

	# whatever with "s" is not mirrored
	elsif ( $l->{"gROWname"} =~ /^[pm]*s2?(flex)?$/i ) {

		$lSett{"mirror"} = 0;

	}

	# 3) Set compensation

	$lSett{"comp"} = 0;

	# 6) Set Shrink
	$lSett{"shrinkX"} = 0;
	$lSett{"shrinkY"} = 0;

	die "Polarity is not defined for layer:" . $self->{"gROWname"}     if ( !defined $lSett{"polarity"} );
	die "Mirror is not defined for layer:" . $self->{"gROWname"}       if ( !defined $lSett{"mirror"} );
	die "Compensation is not defined for layer:" . $self->{"gROWname"} if ( !defined $lSett{"comp"} );
	die "Shrink X is not defined for layer:" . $self->{"gROWname"}     if ( !defined $lSett{"shrinkX"} );
	die "Shrink Y is not defined for layer:" . $self->{"gROWname"}     if ( !defined $lSett{"shrinkY"} );

	return %lSett;
}

sub GetStackup {
	my $self = shift;

	return $self->{"stackup"};
}

# Return if step exist Doesn't load from income for each request
sub StepExist {
	my $self     = shift;
	my $stepName = shift;

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
	my @l         = grep { $_->{"gROWname"} eq $layerName } @{ $self->{"allLayers"} };

	if ( scalar(@l) ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub IsPool {
	my $self = shift;

	return $self->{"isPool"};
}

sub GetJobAttrByName {
	my $self = shift;
	my $attr = shift;

	return $self->{"jobAttributes"}->{$attr};
}

sub GetCustomerNote {
	my $self = shift;

	return $self->{"costomerNote"};
}

sub GetCustomerISInfo {
	my $self = shift;

	return $self->{"costomerInfo"};
}

sub GetPressfitExist {
	my $self = shift;

	return $self->{"pressfitExist"};
}

sub GetToleranceHoleExist {
	my $self = shift;

	return $self->{"tolHoleExist"};
}

sub GetPcbBaseInfo {
	my $self = shift;
	my $key  = shift;

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

	return $self->{"panelType"};
}

# Return pcb surface from IS
sub GetPcbSurface {
	my $self = shift;

	return $self->{"pcbSurface"};
}

# Return total pcb thick from stackup if multiaayer, else from IS (in µm)
sub GetPcbThick {
	my $self = shift;

	return $self->{"pcbThick"};
}

# Return 1 if PCB is flex
sub GetIsFlex {
	my $self = shift;

	return $self->{"pcbIsFlex"};
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __InitDefault {
	my $self = shift;

	my @baseLayers = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"baseLayers"} = \@baseLayers;

	my @signalLayers = CamJob->GetSignalLayer( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"signalLayers"} = \@signalLayers;

	$self->{"pcbClass"} = CamJob->GetJobPcbClass( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"pcbClassInner"} = CamJob->GetJobPcbClassInner( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"platedRoutExceed"} = PlatedRoutArea->PlatedAreaExceed( $self->{"inCAM"}, $self->{'jobId'}, "panel" );

	$self->{"rsExist"} = CamDrilling->NCLayerExists( $self->{"inCAM"}, $self->{'jobId'}, EnumsGeneral->LAYERTYPE_nplt_rsMill );

	if ( $self->{"layerCnt"} > 2 ) {

		$self->{"stackup"} = Stackup->new( $self->{"inCAM"}, $self->{'jobId'} );
		$self->{"stackupNC"} = StackupNC->new( $self->{'jobId'}, $self->{"inCAM"} );
	}

	if ( CamHelper->LayerExists( $self->{"inCAM"}, $self->{"jobId"}, "score" ) ) {

		$self->{"scoreChecker"} = ScoreChecker->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, "score", 1 );
		$self->{"scoreChecker"}->Init();
	}

	my @allSteps = CamStep->GetAllStepNames( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"allStepsNames"} = \@allSteps;    #all steps

	my @allLayers = CamJob->GetAllLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"allLayers"} = \@allLayers;

	$self->{"isPool"} = HegMethods->GetPcbIsPool( $self->{"jobId"} );

	$self->{"surface"} = HegMethods->GetPcbSurface( $self->{"jobId"} );

	my %jobAtt = CamAttributes->GetJobAttr( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"jobAttributes"} = \%jobAtt;

	$self->{"costomerInfo"} = HegMethods->GetCustomerInfo( $self->{"jobId"} );

	$self->{"costomerNote"} = CustomerNote->new( $self->{"costomerInfo"}->{"reference_subjektu"} );

	$self->{"pressfitExist"} = PressfitOperation->ExistPressfitJob( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, 1 );

	$self->{"tolHoleExist"} = TolHoleOperation->ExistTolHoleJob( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, 1 );

	$self->{"pcbBaseInfo"} = HegMethods->GetBasePcbInfo( $self->{"jobId"} );

	$self->{"reorder"} = HegMethods->GetPcbOrderNumber( $self->{"jobId"} );

	$self->{"panelType"} = PanelDimension->GetPanelType( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"pcbSurface"} = HegMethods->GetPcbSurface( $self->{"jobId"} );

	$self->{"pcbThick"} = CamJob->GetFinalPcbThick( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"pcbIsFlex"} = JobHelper->GetIsFlex( $self->{"jobId"} );

}

sub __GetDefaultEtchType {
	my $self      = shift;
	my $layerName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $platedNC = 0;

	# Default type of plating is Etching only
	my $etchType = EnumsGeneral->Etching_ONLY;

	if ( $self->{"layerCnt"} <= 2 ) {

		my @platedNC = CamDrilling->GetPltNCLayers( $inCAM, $jobId );
		@platedNC = grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_fDrill } @platedNC;

		if ( scalar(@platedNC) ) {

			if ( $self->{"platedRoutExceed"} || $self->{"rsExist"} || $self->{"pcbIsFlex"} || CamDrilling->GetViaFillExists($inCAM, $jobId) ) {
				$etchType = EnumsGeneral->Etching_PATTERN;
			}
			else {
				$etchType = EnumsGeneral->Etching_TENTING;
			}
		}
	}
	elsif ( $self->{"layerCnt"} > 2 ) {

		my $pressCnt   = $self->{"stackup"}->GetPressCount();
		my %pressInfo  = $self->{"stackup"}->GetPressProducts();
		my $lamination = $self->{"stackup"}->GetSequentialLam();

		my $stackupNCitem = undef;

		# 1) We need to get top and bot layer, which will be pressed, etched etd together
		my $core = $self->{"stackup"}->GetCoreByCuLayer($layerName);

		# a) create  stackup item contains one core
		if ($core) {

			my $order = $core->GetCoreNumber();

			$stackupNCitem = $self->{"stackupNC"}->GetCore($order);

		}

		# b) create stackup item, which conatin > 2 signal layer (pressing)
		# (sometimes ona layer is exposed twise in production
		# E.g. when 4vv stackup is make from 2 cores)

		my $press = undef;

		# find, which press was layer pressed in
		foreach my $pNum ( keys %pressInfo ) {

			my $p = $pressInfo{$pNum};

			if ( $p->GetTopCopperLayer() eq $layerName || $p->GetBotCopperLayer() eq $layerName ) {
				$press = $p;

				my $order = $press->GetPressOrder();
				$stackupNCitem = $self->{"stackupNC"}->GetPress($order);

				last;
			}

		}

		# 2) Now decide, if there is blind/burried drilling in stackupItem ( = pressInfo/coreInfo)

		# core can have different etching
		if ( $core && !$press ) {

			# if core contain core(burried) drilling -> tenting

			if ( $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_cDrill ) ) {

				$etchType = EnumsGeneral->Etching_TENTING;
			}

			if ( $stackupNCitem->GetTopSigLayer()->GetName() eq $layerName ) {
				if ( $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_bDrillTop ) ) {

					# if top core layer contains a blind drill top -> pattern (e.g. when 4vv stackup is make from 2 cores)

					$etchType = EnumsGeneral->Etching_PATTERN;

				}
				elsif (    $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_nDrill )
						|| $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_nFillDrill )
						|| $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop )
						|| $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_bMillTop ) )
				{

					# if top core layer contains any other plated drill/rout

					$etchType = EnumsGeneral->Etching_TENTING;
				}
			}

			if ( $stackupNCitem->GetBotSigLayer()->GetName() eq $layerName ) {
				if ( $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_bDrillBot ) ) {

					# if bot core layer contains a blind drill bot -> pattern (e.g. when 4vv stackup is make from 2 cores)

					$etchType = EnumsGeneral->Etching_PATTERN;
				}
				elsif (    $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot )
						|| $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_bMillBot ) )
				{

					# if bot core layer contains any other plated drill/rout

					$etchType = EnumsGeneral->Etching_TENTING;
				}
			}

		}
		elsif ($press) {

			# if press, when both side of stackup item has to have same etching type

			if (    $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_bDrillTop )
				 || $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_bDrillBot ) )
			{
				$etchType = EnumsGeneral->Etching_PATTERN;
			}
			elsif (    $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_nDrill )
					|| $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_nFillDrill )
					|| $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop )
					|| $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_bMillTop )
					|| $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot )
					|| $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_bMillBot )
					|| $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_bMillBot ) )
			{

				$etchType = EnumsGeneral->Etching_TENTING;
			}
		}

		# 3) Check on plated rout most outer layers (only when surface is not hard galvanic gold)

		if ( $layerName eq "c" || $layerName eq "s" ) {

			if ( $self->{"surface"} !~ /g/i ) {

				if ( $self->{"platedRoutExceed"} || $self->{"rsExist"} || CamDrilling->GetViaFillExists($inCAM, $jobId) ) {
					$etchType = EnumsGeneral->Etching_PATTERN;
				}
			}
		}
	}

	return $etchType;
}

sub __GetCompByLayer {
	my $self      = shift;
	my $layerName = shift;
	my $plated    = shift;
	my $etchType  = shift;    # EnumsGeneral->Technology_xxx. Only signal layers depends on this attr

	my $class = undef;        # Signal layer construction class

	if ( $layerName =~ /^v\d+(outer)?$/ ) {
		$class = $self->GetPcbClassInner();
	}
	else {
		$class = $self->GetPcbClass();
	}

	my $layerNameCu = $layerName;

	if ( $layerName =~ m/^v(\d+)outer$/ ) {

		$layerNameCu = $1 == 1 ? "c" : "s";
	}

	my $cuThick = $self->GetBaseCuThick($layerNameCu);

	my $comp = 0;

	# when neplat, there is layer "c" but return 0 comp
	if ( $self->GetTypeOfPcb() eq 'Neplatovany' ) {
		return 0;
	}

	return EtchOperation->GetCompensation( $cuThick, $class, $plated, $etchType );

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

