
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
use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Technology::EtchOperation';

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
	$self->{"pcbTypeHelios"} = undef;     # type by helios oboustranny, neplat etc..
	$self->{"finalPcbThick"} = undef;
	$self->{"allStepsNames"} = undef;     # all steps
	$self->{"allLayers"}     = undef;     # all layers
	$self->{"isPool"}        = undef;

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

sub GetLayerCnt {
	my $self = shift;

	return $self->{"layerCnt"};
}

sub GetEtchType {
	my $self      = shift;
	my $layerName = shift;

	my $etchType = EnumsGeneral->Etching_NO;

	if ( $self->{"layerCnt"} == 1 ) {

		$etchType = EnumsGeneral->Etching_TENTING;

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

		my $core  = $self->{"stackup"}->GetCoreByCopperLayer($layerName);
		my $press = undef;

		if ($core) {

			#$topCopperName = $core->GetTopCopperLayer()->GetCopperName();
			#$botCopperName = $core->GetBotCopperLayer()->GetCopperName();

			my $order = $core->GetCoreNumber();

			$stackupNCitem = $self->{"stackupNC"}->GetCore($order);

		}
		else {

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
		}

		# 2) Now decide, if there is blind drilling in stackupItem ( = pressInfo/coreInfo)

		if (    $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_bDrillTop )
			 || $stackupNCitem->ExistNCLayers( StackupEnums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_bDrillBot ) )
		{

			$etchType = EnumsGeneral->Etching_PATTERN;

		}
		else {

			$etchType = EnumsGeneral->Etching_TENTING;
		}

		# 3) Check on plated rout most outer layers

		if ( $layerName eq "c" || $layerName eq "s" ) {

			if ( $self->{"platedRoutExceed"} || $self->{"rsExist"} ) {
				$etchType = EnumsGeneral->Etching_PATTERN;
			}
		}

	}

	return $etchType;

}

sub GetSideByLayer {
	my $self      = shift;
	my $layerName = shift;

	my $side = "";

	my %pressInfo = $self->{"stackup"}->GetPressInfo();
	my $core      = $self->{"stackup"}->GetCoreByCopperLayer($layerName);
	my $press     = undef;

	if ($core) {

		my $topCopperName = $core->GetTopCopperLayer()->GetCopperName();
		my $botCopperName = $core->GetBotCopperLayer()->GetCopperName();

		if ( $layerName eq $topCopperName ) {

			$side = "top";
		}
		elsif ( $layerName eq $botCopperName ) {

			$side = "bot";
		}
	}
	else {

		# find, which press was layer pressed in
		foreach my $pNum ( keys %pressInfo ) {

			my $p = $pressInfo{$pNum};

			if ( $p->GetTopCopperLayer() eq $layerName ) {

				$side = "top";
				last;

			}
			elsif ( $p->GetBotCopperLayer() eq $layerName ) {

				$side = "bot";
				last;
			}
		}
	}

	return $side;
}

sub GetCompByLayer {
	my $self      = shift;
	my $layerName = shift;

	my $class   = $self->GetPcbClass();
	my $cuThick = $self->GetBaseCuThick($layerName);

	my $comp = EtchOperation->KompenzaceIncam( $cuThick, $class );

	return $comp;

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

	$self->{"pcbTypeHelios"} = HegMethods->GetTypeOfPcb( $self->{"jobId"} eq 'Neplatovany' );
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

			# set etching type
			my $etching = $self->GetEtchType( $l->{"gROWname"} );

			$l->{"etchingType"} = $etching;

			# Set polarity by etching type
			if ( $etching eq EnumsGeneral->Etching_PATTERN ) {
				$l->{"polarity"} = "positive";
			}
			elsif ( $etching eq EnumsGeneral->Etching_TENTING ) {
				$l->{"polarity"} = "negative";
			}

			# Edit polarity according InCAM matric polarity
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
	my $self      = shift;
	 
 	return $self->{"isPool"};
}

sub __InitDefault {
	my $self = shift;

	my @baseLayers = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"baseLayers"} = \@baseLayers;

	my @signalLayers = CamJob->GetSignalLayer( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"signalLayers"} = \@signalLayers;

	$self->{"pcbClass"} = CamJob->GetJobPcbClass( $self->{"inCAM"}, $self->{"jobId"} );

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
	$self->{"allStepsNames"} = undef;    #all steps

	my @allLayers = CamJob->GetAllLayers( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"allLayers"} = \@allLayers;

	$self->{"isPool"} = HegMethods->GetPcbIsPool( $self->{"jobId"} );

	#$self->{"finalPcbThick"} = JobHelper->GetFinalPcbThick($self->{"jobId"});

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

