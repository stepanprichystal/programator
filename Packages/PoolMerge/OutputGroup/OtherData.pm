
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::MergeGroup::OtherData;
use base("Packages::ItemResult::ItemEventMngr");

#3th party library
use utf8;
use strict;
use warnings;
use DateTime;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Packages::Stackup::StackupDefault';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"poolInfo"} = shift;

	return $self;
}

# Set info about solder mask and silk screnn, based on layers
sub SetInfoHelios {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	# 1) Check if there is solder or silk non board layer

	my @layers = CamJob->GetAllLayers($inCAM);
	@layers = grep { $_->{"gROWname"} =~ /^[pm][cs]^$/ } @layers;

	foreach my $l (@layers) {

		if ( $_->{"gROWcontext"} ne "board" ) {

			$result = 0;
			$$mess .= "V metrixu je vrstva: " . $l->{"gROWname"} . ", ale není nastavená jako board. Nastva vrstvu jako board, nebo ji přejmenuj.";

		}
	}

	# 2) Set proper info to noris

	if ( CamHelper->LayerExists( $inCAM, "pc" ) ) {
		HegMethods->UpdateSilkScreen( $masterJob, "top", "B", 1 );
	}

	if ( CamHelper->LayerExists( $inCAM, "ps" ) ) {
		HegMethods->UpdateSilkScreen( $masterJob, "bot", "B", 1 );
	}
	if ( CamHelper->LayerExists( $inCAM, "mc" ) ) {
		HegMethods->UpdateSolderMask( $masterJob, "top", "Z", 1 );
	}

	if ( CamHelper->LayerExists( $inCAM, "ms" ) ) {
		HegMethods->UpdateSolderMask( $masterJob, "bot", "Z", 1 );
	}

	return $result;
}

sub SetConstructClass {
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
		CamAttributes->SetJobAttribute( $inCAM, $masterJob, $max );
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

