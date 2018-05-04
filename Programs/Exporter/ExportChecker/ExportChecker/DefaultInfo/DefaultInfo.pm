
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
	$self->{"pcbBaseInfo"}   = undef;    # contain base info about pcb from IS
	$self->{"reorder"}       = undef;    # indicate id in time in export exist reorder
	$self->{"panelType"}     = undef;    # return type of panel from Enums::EnumsProducPanel
	$self->{"pcbSurface"}    = undef;    # surface from IS
	$self->{"pcbThick"}      = undef;    # total thick of pcb
	$self->{"pcbClass"}      = undef;    # pcb class of outer layer
	$self->{"pcbClassInner"} = undef;    # pcb class of inner layer

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
	if(!defined $self->{"pcbClassInner"} || $self->{"pcbClassInner"} == 0 ){
		return $self->GetPcbClass();
	}

	return $self->{"pcbClassInner"};
}

sub GetLayerCnt {
	my $self = shift;

	return $self->{"layerCnt"};
}

sub GetEtchType {
	my $self      = shift;
	my $layerName = shift;

	my $etchType = EnumsGeneral->Etching_NO;

	if ( $self->{"layerCnt"} <= 1 ) {

		$etchType = EnumsGeneral->Etching_NO;

	}
	elsif ( $self->{"layerCnt"} == 2 ) {

		if ( $self->{"platedRoutExceed"} || $self->{"rsExist"} ) {
			$etchType = EnumsGeneral->Etching_PATTERN;
		}
		else {
			$etchType = EnumsGeneral->Etching_TENTING;
		}
	}
	elsif ( $self->{"layerCnt"} > 2 ) {

		my $pressCnt   = $self->{"stackup"}->GetPressCount();
		my %pressInfo  = $self->{"stackup"}->GetPressInfo();
		my $lamination = $self->{"stackup"}->ProgressLamination();

		my $stackupNCitem = undef;

		# 1) We need to get top and bot layer, which will be pressed, etched etd together
		#my $topCopperName = undef;
		#my $botCopperName = undef;

		my $core = $self->{"stackup"}->GetCoreByCopperLayer($layerName);

		# a) create  stackup item contains one core
		if ($core) {

			#$topCopperName = $core->GetTopCopperLayer()->GetCopperName();
			#$botCopperName = $core->GetBotCopperLayer()->GetCopperName();

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

				#$topCopperName = p->GetTopCopperLayer();
				#$botCopperName = $p->GetBotCopperLayer();
				last;
			}

		}

		# 2) Now decide, if there is blind drilling in stackupItem ( = pressInfo/coreInfo)

		# core can have different etching
		if ( $core && !$press ) {

			# if core contain core drilling -> tenting

			if ( $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_cDrill ) ) {

				$etchType = EnumsGeneral->Etching_TENTING;
			}

			# if top layer of core contain blind drill top -> pattern (e.g. when 4vv stackup is make from 2 cores)

			if ( $stackupNCitem->GetTopSigLayer()->GetName() eq $layerName ) {
				if ( $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_bDrillTop ) ) {
					$etchType = EnumsGeneral->Etching_PATTERN;
				}
				else {
					$etchType = EnumsGeneral->Etching_TENTING;
				}
			}

			# if bot layer of core contain blind drill bot -> pattern (e.g. when 4vv stackup is make from 2 cores)
			if ( $stackupNCitem->GetBotSigLayer()->GetName() eq $layerName ) {
				if ( $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_bDrillBot ) ) {
					$etchType = EnumsGeneral->Etching_PATTERN;
				}
				else {
					$etchType = EnumsGeneral->Etching_TENTING;
				}
			}

		}
		elsif ($press) {

			# if press, when both side of stackup item has to have same etching type

			if (    $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_bDrillTop )
				 || $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_bDrillBot ) )
			{
				$etchType = EnumsGeneral->Etching_PATTERN;
			}
			else {
				$etchType = EnumsGeneral->Etching_TENTING;
			}
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

# Return if Cu layer has orientation TOP/BOT
# Orientation is based on view pcb from top
sub GetSideByLayer {
	my $self      = shift;
	my $layerName = shift;

	my $side = StackupOperation->GetSideByLayer( $self->{"jobId"}, $layerName, $self->{"stackup"} );

	return $side;
}

sub GetCompByLayer {
	my $self      = shift;
	my $layerName = shift;

	# Detect if it is inner layer
	my $inner = $layerName =~ /^v\d+$/ ? 1 : 0;

	my $class   = undef;
	
	if($inner){
		$class = $self->GetPcbClassInner();
	}else{
		$class = $self->GetPcbClass();
	}
	
	my $cuThick = $self->GetBaseCuThick($layerName);

	my $comp = 0;

	# when neplat, there is layer "c" but return 0 comp
	if ( $self->GetTypeOfPcb() eq 'Neplatovany' ) {
		return 0;
	}

	
	
	return EtchOperation->GetCompensation( $cuThick, $class, $inner );

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

	if ( HegMethods->GetTypeOfPcb( $self->{"jobId"} ) eq 'Vicevrstvy' ) {

		$self->{"stackup"} = Stackup->new( $self->{"jobId"} );

		my $cuLayer = $self->{"stackup"}->GetCuLayer($layerName);
		$cuThick = $cuLayer->GetThick();
	}
	else {

		$cuThick = HegMethods->GetOuterCuThick( $self->{"jobId"}, $layerName );
	}

	return $cuThick;
}

# Set polarity, mirro, compensation for board layers
# this is used for OPFX export, tif file export
sub SetDefaultLayersSettings {
	my $self   = shift;
	my $layers = shift;

	# Set polarity of layers
	foreach my $l ( @{$layers} ) {

		if ( $l->{"gROWlayer_type"} eq "silk_screen" ) {

			$l->{"polarity"} = "negative";

		}
		elsif ( $l->{"gROWlayer_type"} eq "solder_mask" ) {

			$l->{"polarity"} = "positive";

		}
		elsif ( $l->{"gROWlayer_type"} eq "signal" || $l->{"gROWlayer_type"} eq "power_ground" || $l->{"gROWlayer_type"} eq "mixed" ) {

			# 1) set etching type
			my $etching = $self->GetEtchType( $l->{"gROWname"} );

			$l->{"etchingType"} = $etching;

			# 2) Set polarity by etching type
			if ( $etching eq EnumsGeneral->Etching_PATTERN ) {
				$l->{"polarity"} = "positive";
			}
			elsif ( $etching eq EnumsGeneral->Etching_TENTING || $etching eq EnumsGeneral->Etching_NO ) {
				$l->{"polarity"} = "negative";
			}

			# 3) Exception for layer c, s and Galvanic gold. Polarity always postitive
			if ( $l->{"gROWname"} eq "c" || $l->{"gROWname"} eq "s" ) {

				if ( $self->{"surface"} =~ /g/i ) {
					$l->{"polarity"} = "positive";
				}
			}

			# 4) Edit polarity according InCAM matrix polarity
			# if polarity negative, switch polarity
			if ( $l->{"gROWpolarity"} eq "negative" ) {

				if ( $l->{"polarity"} eq "negative" ) {
					$l->{"polarity"} = "positive";

				}
				elsif ( $l->{"polarity"} eq "positive" ) {
					$l->{"polarity"} = "negative";
				}

			}

		}
		else {

			$l->{"polarity"} = "positive";

		}
	}

	# Set mirror of layers
	foreach my $l ( @{$layers} ) {

		# whatever with "c" is mirrored
		if ( $l->{"gROWname"} =~ /^[pm]*c$/i ) {

			$l->{"mirror"} = 1;

		}

		# whatever with "s" is not mirrored
		elsif ( $l->{"gROWname"} =~ /^[pm]*s$/i ) {

			$l->{"mirror"} = 0;

		}

		# inner layers decide by stackup
		elsif ( $l->{"gROWname"} =~ /^v\d+$/i ) {

			my $side = $self->GetSideByLayer( $l->{"gROWname"} );

			if ( $side eq "top" ) {

				$l->{"mirror"} = 1;

			}
			else {

				$l->{"mirror"} = 0;
			}
		}

		# if layer end with c, mirror
		elsif ( $l->{"gROWname"} =~ /c$/i ) {

			$l->{"mirror"} = 1;

		}    # if layer end with s, mirror
		elsif ( $l->{"gROWname"} =~ /s$/i ) {

			$l->{"mirror"} = 0;

		}
	}

	# Set compensation of signal layer
	foreach my $l ( @{$layers} ) {

		if ( $l->{"gROWlayer_type"} eq "signal" || $l->{"gROWlayer_type"} eq "power_ground" || $l->{"gROWlayer_type"} eq "mixed" ) {

			$l->{"comp"} = $self->GetCompByLayer( $l->{"gROWname"} );

			# If layer is negative, set negative compensation
			if ( defined $l->{"comp"} && $l->{"gROWpolarity"} eq "negative" ) {
				$l->{"comp"} = -$l->{"comp"};
			}
			
			unless(defined $l->{"comp"}){
				$l->{"comp"} = "NaN";
			}

		}
		else {

			$l->{"comp"} = 0;

		}
	}

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

sub GetPressfitExist {
	my $self = shift;

	return $self->{"pressfitExist"};
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

		$self->{"stackup"} = Stackup->new( $self->{'jobId'} );
		$self->{"stackupNC"} = StackupNC->new( $self->{"inCAM"}, $self->{"stackup"} );
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

	$self->{"pcbBaseInfo"} = HegMethods->GetBasePcbInfo( $self->{"jobId"} );

	$self->{"reorder"} = HegMethods->GetPcbOrderNumber( $self->{"jobId"} );

	$self->{"panelType"} = PanelDimension->GetPanelType( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"pcbSurface"} = HegMethods->GetPcbSurface( $self->{"jobId"} );

	$self->{"pcbThick"} = JobHelper->GetFinalPcbThick( $self->{"jobId"} );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';

	#my $id

	#my $form = StorageMngr->new();

}

1;

