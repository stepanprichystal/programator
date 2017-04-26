
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::OutputGroup::Helper::OtherSettings;

#3th party library
use utf8;
use strict;
use warnings;
use DateTime;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased "CamHelpers::CamLayer";
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Packages::Stackup::StackupDefault';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"poolInfo"} = shift;

	return $self;
}

# Set info about solder mask and silk screnn, based on layers
sub SetJobHeliosAttributes {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	# 1) Check if there is solder or silk non board layer

	my @layers = CamJob->GetAllLayers( $inCAM, $masterJob );
	@layers = grep { $_->{"gROWname"} =~ /^[pm][cs]$/ } @layers;

	foreach my $l (@layers) {

		if ( $l->{"gROWcontext"} ne "board" ) {

			$result = 0;
			$$mess .= "V metrixu je vrstva: " . $l->{"gROWname"} . ", ale není nastavená jako board. Nastva vrstvu jako board, nebo ji přejmenuj.";

		}
	}

	# 2) Set proper info to noris
	my %silk   = HegMethods->GetSilkScreenColor($masterJob);
	my %solder = HegMethods->GetSolderMaskColor($masterJob);

	if ( CamHelper->LayerExists( $inCAM, $masterJob, "pc" ) ) {

		if ( $silk{"top"} ne "B" ) {
			HegMethods->UpdateSilkScreen( $masterJob, "top", "B", 1 );
		}
	}
	if ( CamHelper->LayerExists( $inCAM, $masterJob, "ps" ) ) {
		if ( $silk{"bot"} ne "B" ) {
			HegMethods->UpdateSilkScreen( $masterJob, "bot", "B", 1 );
		}
	}
	if ( CamHelper->LayerExists( $inCAM, $masterJob, "mc" ) ) {
		if ( $solder{"top"} ne "Z" ) {
			HegMethods->UpdateSolderMask( $masterJob, "top", "Z", 1 );
		}
	}
	if ( CamHelper->LayerExists( $inCAM, $masterJob, "ms" ) ) {
		if ( $solder{"bot"} ne "Z" ) {
			HegMethods->UpdateSolderMask( $masterJob, "bot", "Z", 1 );
		}
	}

	return $result;
}

sub SetJobAttributes {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	# 1) set pcb class
	unless ( $self->__SetPcbClass( $masterJob, $mess ) ) {
		$result = 0;
	}

	#2) set layer side, and mirror attribute
	unless ( $self->__SetLayerAtt( $masterJob, $mess ) ) {
		$result = 0;
	}

	return $result;
}

sub JobCleanup {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	# 1) remove unused symbosl from job
	$inCAM->COM( 'delete_unused_sym', "job" => $masterJob );

	# 2) remove layers which contain "+"
	CamLayer->RemoveTempLayerPlus( $inCAM, $masterJob );

	return $result;
}

sub __SetPcbClass {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	# 1) Go through all jobs and take highest constr class
	my @jobNames = $self->{"poolInfo"}->GetJobNames();

	my $max = undef;
	foreach my $jobName (@jobNames) {

		my $constClass = CamAttributes->GetJobAttrByName( $inCAM, $jobName, 'pcb_class' );

		if ( !defined $constClass || $constClass < 3 ) {
			$result = 0;
			$$mess .= "Missing construction class in pcb \"$jobName\". Minimal class is \"class 3\"";
			last;
		}

		if ( !defined $max || $max < $constClass ) {
			$max = $constClass;
		}
	}

	if ( defined $max ) {
		CamAttributes->SetJobAttribute( $inCAM, $masterJob, "pcb_class", $max );
	}

	return $result;
}

sub __SetLayerAtt {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my @signal = CamJob->GetSignalLayer( $inCAM, $masterJob );
 
	foreach my $s (@signal) {
		if ( $s->{"gROWname"} =~ /^c$/ ) {
			$s->{"side"} = "top";
		}

		if ( $s->{"gROWname"} =~ /^s$/ ) {
			$s->{"side"} = "bot";
		}
		if ( $s->{"gROWname"} =~ /^v(\d+)$/ ) {
			if ( $1 % 2 == 0 ) {
				$s->{"side"} = "top";
			}
			else {
				$s->{"side"} = "bot";
			}
		}
	}

	foreach my $layer (@signal) {

		# 1) set layer side attribute

		CamAttributes->SetLayerAttribute( $inCAM, "layer_side", $layer->{"side"}, $masterJob, "panel", $layer->{"gROWname"} );

		# 2) set cdr mirror attribute
		my $mirror = $layer->{"side"} eq "top" ? "no" : "yes";
		CamAttributes->SetLayerAttribute( $inCAM, ".cdr_mirror", $mirror, $masterJob, "panel", $layer->{"gROWname"} );

	}

	return $result;
}

# Set info about solder mask and silk screnn, based on layers
sub CreateDefaultStackup {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	# Get info in order to create default stackup
	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $masterJob );
	my $constClass  = CamAttributes->GetJobAttrByName( $inCAM, $masterJob, 'pcb_class' );
	my $cuThickness = HegMethods->GetOuterCuThick($masterJob);
	my $pcbThick    = 0.7;                                                                  # aproximate thickness of core

	unless ( defined $cuThickness ) {
		$result = 0;
		$$mess .= "Copper thicknes is not set in Helios, job \"$masterJob\"";
		return $result;
	}

	my @innerCuUsage = ();
	my @layers       = CamJob->GetSignalLayers($inCAM);
	@layers = grep { $_->{"gROWname"} =~ /^v\d+$/ } @layers;
	@layers = sort { $a->{"gROWname"} cmp $b->{"gROWname"} } @layers;

	foreach my $l (@layers) {

		my $area = undef;
		my ($num) = $l->{"gROWname"} =~ m/^v(\d+)$/;

		if ( $num % 2 == 0 ) {

			$area = CamHelpers->CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, $masterJob, "panel", $l->{"gROWname"}, undef );
		}
		else {
			$area = CamHelpers->CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, $masterJob, "panel", undef, $l->{"gROWname"} );
		}

		if ($area) {

			push( @innerCuUsage, $area );
		}
		else {
			$result = 0;
			$$mess .= "Error when computing  Copper area for layer: " . $l->{"gROWname"};
		}

	}

	StackupDefault->CreateStackup( $masterJob, $layerCnt, \@innerCuUsage, $cuThickness, $constClass );

	return $result;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::AOIExport::AOIMngr';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobName   = "f13610";
	#	my $stepName  = "panel";
	#	my $layerName = "c";
	#
	#	my $mngr = AOIMngr->new( $inCAM, $jobName, $stepName, $layerName );
	#	$mngr->Run();
}

1;

