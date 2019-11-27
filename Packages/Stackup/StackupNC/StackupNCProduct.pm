
#-------------------------------------------------------------------------------------------#
# Description: Base class, keep information about TOP/BOT copper for pressing and cores
# Provide methods for getting information about NC operation on this copper sides
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupNC::StackupNCProduct;

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

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"IProduct"} = shift;
	$self->{"ncLayers"} = shift;

	return $self;
}

# Return top copper name
sub GetTopCopperLayer {
	my $self = shift;

	return $self->{"IProduct"}->GetTopCopperLayer();
}

# Return bot copper name
sub GetBotCopperLayer {
	my $self = shift;

	return $self->{"IProduct"}->GetBotCopperLayer();
}


# Return top copper number
sub GetTopCopperNum {
	my $self = shift;

	return $self->{"IProduct"}->GetTopCopperNum();
}

# Return bot copper number
sub GetBotCopperNum {
	my $self = shift;

	return $self->{"IProduct"}->GetBotCopperNum();
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
	my $self          = shift;
	my $NCStartSide   = shift;         # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide     = shift;         # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType   = shift;         # Type of Enums::LayerType_xxx
	my $onlyProductNC = shift // 0;    # Only NC layer which start/end at product outer copper layer are considered

	my @drillLayers = $self->GetNCLayers( $NCStartSide, $NCEndSide, $NClayerType, $onlyProductNC );

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
	my $self          = shift;
	my $NCStartSide   = shift;         # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide     = shift;         # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType   = shift;         # Type of Enums::LayerType_xxx
	my $onlyProductNC = shift // 0;    # Only NC layer which start/end at product outer copper layer are considered

	my @ncLayers = $onlyProductNC ? $self->{"IProduct"}->GetPltNCLayers() : @{ $self->{"ncLayers"} };
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
		my $startLayer = $NCStartSide eq Enums->SignalLayer_TOP ? $self->GetTopCopperLayer() : $self->GetBotCopperLayer();
		if ($startLayer) {
			@drillLayers = grep { $_->{"NCSigStart"} eq $startLayer } @drillLayers;
		}
	}

	# Filter NC layers by end signal layer
	if ( defined $NCEndSide ) {
		my $endLayer = $NCEndSide eq Enums->SignalLayer_TOP ? $self->GetTopCopperLayer() : $self->GetBotCopperLayer();
		if ($endLayer) {
			@drillLayers = grep { $_->{"NCSigEnd"} eq $endLayer } @drillLayers;
		}
	}

	return @drillLayers;
}

# Return minimal hole for given side and type of NC layers
sub GetMinHoleTool {
	my $self          = shift;
	my $NCStartSide   = shift;         # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide     = shift;         # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType   = shift;         # Type of Enums::LayerType_xxx
	my $onlyProductNC = shift // 0;    # Only NC layer which start/end at product outer copper layer are considered

	my @layers = $self->GetNCLayers( $NCStartSide, $NCEndSide, $NClayerType, $onlyProductNC );

	my $minTool = CamDrilling->GetMinHoleToolByLayers( $self->{"inCAM"}, $self->{"jobId"}, "panel", \@layers );

	return $minTool;

}

# Return minimal slot hole for given side and type of NC layers
sub GetMinSlot {
	my $self          = shift;
	my $NCStartSide   = shift;         # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide     = shift;         # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType   = shift;         # Type of Enums::LayerType_xxx
	my $onlyProductNC = shift // 0;    # Only NC layer which start/end at product outer copper layer are considered

	my @layers = $self->GetNCLayers( $NCStartSide, $NCEndSide, $NClayerType, $onlyProductNC );

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
	my $self          = shift;
	my $NCStartSide   = shift;         # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide     = shift;         # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType   = shift;         # Type of Enums::LayerType_xxx
	my $onlyProductNC = shift // 0;    # Only NC layer which start/end at product outer copper layer are considered

	my $minHole = $self->GetMinHoleTool( $NCStartSide, $NCEndSide, $NClayerType, $onlyProductNC );

	# thick of pcb after this pressing in µm
	my $fromLayer = $NCStartSide eq Enums->SignalLayer_TOP ? $self->GetTopCopperLayer() : $self->GetBotCopperLayer;

	my $finalThick = $self->{"IProduct"}->GetThick($fromLayer);

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
	my $self          = shift;
	my $NCStartSide   = shift;         # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide     = shift;         # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType   = shift;         # type of Enums::LayerType_xxx
	my $onlyProductNC = shift // 0;    # Only NC layer which start/end at product outer copper layer are considered

	my @layers = $self->GetNCLayers( $NCStartSide, $NCEndSide, $NClayerType, $onlyProductNC );
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
	my $self          = shift;
	my $NCStartSide   = shift;         # Restriction for NC layers specify start side of NC layers. Type of Enums::SignalLayer_xxx
	my $NCEndSide     = shift;         # Restriction for NC layers specify end side of NC layers. Type of Enums::SignalLayer_xxx
	my $NClayerType   = shift;         # type of Enums::LayerType_xxx
	my $onlyProductNC = shift // 0;    # Only NC layer which start/end at product outer copper layer are considered

	my @layers = $self->GetNCLayers( $NCStartSide, $NCEndSide, $NClayerType, $onlyProductNC );

	my $max = 0;
	foreach my $layer (@layers) {

		my $cnt = CamDrilling->GetStagesCnt( $self->{"jobId"}, "panel", $layer->{"gROWname"}, $self->{"inCAM"} );

		if ( $cnt > $max ) {
			$max = $cnt;
		}
	}

	return $max;

}

sub GetIProduct {
	my $self = shift;

	return $self->{"IProduct"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

