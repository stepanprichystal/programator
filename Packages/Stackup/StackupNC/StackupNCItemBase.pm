
#-------------------------------------------------------------------------------------------#
# Description: Base class, keep information about TOP/BOT copper for pressing and cores
# Provide methods for getting information about NC operation on this copper sides
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupNC::StackupNCItemBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamRouting';
use aliased 'CamHelpers::CamToolDepth';
use aliased 'Packages::Stackup::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"stackupNC"} = shift;

	$self->{"topSignalLayer"} = shift;

	$self->{"botSignalLayer"} = shift;

	$self->{"inCAM"} = $self->{"stackupNC"}->{"inCAM"};
	$self->{"jobId"} = $self->{"stackupNC"}->{"jobId"};

	$self->{"ncLayers"} = $self->{"stackupNC"}->{"ncLayers"};

	return $self;
}

# Return <StackupNCSignal> object, it is TOP copper of press/core
sub GetTopSigLayer {
	my $self = shift;
	return $self->{"topSignalLayer"};
}

# Return <StackupNCSignal> object, it is BOT copper of press/core
sub GetBotSigLayer {
	my $self = shift;
	return $self->{"botSignalLayer"};
}

## Return number of signal layer, which create this stackup info
#sub GetSignalLayerCnt {
#	my $self = shift;
#
#	my $cnt = $self->GetBotSigLayer->GetNumber() - $self->GetTopSigLayer->GetNumber() +1 ;
#
#	return $cnt;
#}

# Return if exist NC layer of given side TOP/BOT
sub ExistNCLayers {
	my $self        = shift;
	my $NCStartSide = shift;    # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide   = shift;    # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType = shift;    # Type of Enums::LayerType_xxx

	my @drillLayers = $self->GetNCLayers( $NCStartSide, $NCEndSide, $NClayerType );

	if ( scalar(@drillLayers) > 0 ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Return NC layers which go through package create by stackup NC item
# Restriction on NC layers can be applied (NC start side, NC end side, NC layer type)
sub GetNCLayers {
	my $self        = shift;
	my $NCStartSide = shift;    # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide   = shift;    # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType = shift;    # Type of Enums::LayerType_xxx

	my @ncLayers    = @{ $self->{"ncLayers"} };
	my @drillLayers = ();

	unless ( scalar(@ncLayers) ) {

		return @drillLayers;
	}

	@drillLayers = @ncLayers;

	if ( defined $NClayerType ) {
		@drillLayers = grep { $_->{"type"} eq $NClayerType } @drillLayers;
	}

	# Filter NC layers by start signal layer
	if ( defined $NCStartSide ) {
		my $startLayer = $NCStartSide eq Enums->SignalLayer_TOP ? $self->{"topSignalLayer"} : $self->{"botSignalLayer"};
		if ($startLayer) {
			@drillLayers = grep { $_->{"NCSigStart"} eq $startLayer->GetName() } @drillLayers;
		}
	}

	# Filter NC layers by end signal layer
	if ( defined $NCEndSide ) {
		my $endLayer = $NCEndSide eq Enums->SignalLayer_TOP ? $self->{"topSignalLayer"} : $self->{"botSignalLayer"};
		if ($endLayer) {
			@drillLayers = grep { $_->{"NCSigEnd"} eq $endLayer->GetName() } @drillLayers;
		}
	}

	return @drillLayers;
}

# Return minimal hole for given side and type of NC layers
sub GetMinHoleTool {
	my $self        = shift;
	my $NCStartSide = shift;    # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide   = shift;    # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType = shift;    # Type of Enums::LayerType_xxx

	my @layers = $self->GetNCLayers( $NCStartSide, $NCEndSide, $NClayerType );

	my $minTool = CamDrilling->GetMinHoleToolByLayers( $self->{"inCAM"}, $self->{"jobId"}, "panel", \@layers );

	return $minTool;

}

# Return minimal slot hole for given side and type of NC layers
sub GetMinSlot {
	my $self        = shift;
	my $NCStartSide = shift;    # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide   = shift;    # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType = shift;    # Type of Enums::LayerType_xxx

	my @layers = $self->GetNCLayers( $NCStartSide, $NCEndSide, $NClayerType );

	my $minTool = CamRouting->GetMinSlotToolByLayers( $self->{"inCAM"}, $self->{"jobId"}, "panel", \@layers );

	if ( defined $minTool ) {
		$minTool = sprintf "%0.2f", ( $minTool / 1000 );
	}
	else {
		$minTool = "";
	}

	return $minTool;

}

# Return minimal aspect ratio based on stackup thickness, by minimal hole.
sub GetMaxAspectRatio {
	my $self        = shift;
	my $NCStartSide = shift;    # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide   = shift;    # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType = shift;    # Type of Enums::LayerType_xxx

	my $minHole = $self->GetMinHoleTool( $NCStartSide, $NCEndSide, $NClayerType );

	# thick of pcb after this pressing in µm
	my $fromLayer = $NCStartSide eq Enums->SignalLayer_TOP ? $self->{"topSignalLayer"} : $self->{"botSignalLayer"};
	my $finalThick = $self->{"stackupNC"}->GetThickByCuLayer( $fromLayer->GetName() ) * 1000;

	my $aspectRatio = 0;

	if ( defined $minHole && $minHole > 0 ) {
		$aspectRatio = sprintf "%0.2f", ( $finalThick / $minHole );
	}
	else {
		$aspectRatio = "";
	}

	return $aspectRatio;

}

# Return minimal aspect ratio based on stackup thickness, by minimal hole.
sub GetMaxBlindAspectRatio {
	my $self        = shift;
	my $NCStartSide = shift;    # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide   = shift;    # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType = shift;    # type of Enums::LayerType_xxx

	my @layers = $self->GetNCLayers( $NCStartSide, $NCEndSide, $NClayerType );
	my $maxAR;

	foreach my $layer (@layers) {

		my $tmp = CamToolDepth->GetMaxAspectRatioByLayer( $self->{"inCAM"}, $self->{"jobId"}, "panel", $layer->{"gROWname"} );

		if ( !defined $maxAR || $tmp > $maxAR ) {
			$maxAR = $tmp;
		}
	}

	if ( defined $maxAR && $maxAR > 0 ) {
		$maxAR = sprintf "%0.2f", ($maxAR);
	}
	else {
		$maxAR = "";
	}

	return $maxAR;

}

#Assume, only one layer can have more then one stages
# Thus we take layer with max cnt of stages
sub GetStageCnt {
	my $self        = shift;
	my $NCStartSide = shift;    # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide   = shift;    # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType = shift;    # type of Enums::LayerType_xxx

	my @layers = $self->GetNCLayers( $NCStartSide, $NCEndSide, $NClayerType );

	my $max = 0;
	foreach my $layer (@layers) {

		my $cnt = CamDrilling->GetStagesCnt( $self->{"jobId"}, "panel", $layer->{"gROWname"}, $self->{"inCAM"} );

		if ( $cnt > $max ) {
			$max = $cnt;
		}
	}

	return $max;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

