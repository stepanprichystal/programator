
#-------------------------------------------------------------------------------------------#
# Description: Create panel
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::MergeGroup::Helper::PanelCreation;
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
use aliased 'Packages::NifFile::NifFile';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::ProductionPanel::PanelDimension';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'Enums::EnumsProducPanel';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"poolInfo"} = shift;

	$self->{"newPnl"}    = undef;
	$self->{"panelType"} = undef;
	$self->{"panelDims"} = undef;

	return $self;
}

# Decide which panel dimensions use, based on layer cnt and dimension from pool file
sub CreatePanel {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	# 1) Choose panel type  Enums::EnumsProducPanel::panelsize_XXX
	my $panelType = PanelDimension->GetPanelTypeByActiveArea( $inCAM, $masterJob, $self->{"poolInfo"}->GetPnlW(), $self->{"poolInfo"}->GetPnlH() );

	#die "Panel type was found" unless ( defined $panelType );

	my %panelDims = PanelDimension->GetDimensionPanel( $inCAM, $panelType );

	$self->{"panelType"} = $panelType;
	$self->{"panelDims"} = \%panelDims;

	if ( !defined $panelDims{"PanelSizeX"} || !defined $panelDims{"PanelSizeY"} ) {

		my $dim = $self->{"poolInfo"}->GetPnlW() . "x" . $self->{"poolInfo"}->GetPnlH();
		$$mess .= "Wrong format of panel dimension in \"xml pool file\". Check if this is proper dimension ($dim) for this type of pcb.";

		return 0;

	}

	# 2) Create new "panel" step
	$self->{"newPnl"} = SRStep->new( $inCAM, $masterJob, "panel" );
	$self->{"newPnl"}->Create( $panelDims{"PanelSizeX"}, $panelDims{"PanelSizeY"}, $panelDims{"BorderTop"},
							   $panelDims{"BorderBot"},  $panelDims{"BorderLeft"}, $panelDims{"BorderRight"} );

	# 3) add step and repeat
	my @orders = $self->{"poolInfo"}->GetOrdersInfo();

	foreach my $orderInf (@orders) {

		my $stepName = $orderInf->{"jobName"};

		if ( $stepName =~ /^$masterJob$/i ) {
			$stepName = "o+1";
		}

		foreach my $pos ( @{ $orderInf->{"pos"} } ) {

			$self->{"newPnl"}->AddSRStep( $stepName, $pos->{"x"} + $panelDims{"BorderLeft"}, $pos->{"y"} + $panelDims{"BorderBot"},
										  ( $pos->{"rotated"} ? 270 : 0 ) );
		}
	}

	return $result;

}

# Add panel schema to panel
sub AddPanelSchema {
	my $self      = shift;
	my $masterJob = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $masterJob );

	# 4) add schema
	my $schema = undef;

	if ( $layerCnt <= 2 ) {

		$schema = "rigid_2v";
	}
	else {

		if ( $self->{"panelType"} eq EnumsProducPanel->SIZE_MULTILAYER_SMALL ) {
			$schema = 'rigid_vv_407';
		}
		elsif ( $self->{"panelType"} eq EnumsProducPanel->SIZE_MULTILAYER_BIG ) {
			$schema = 'rigid_vv_485';

		}
		elsif ( $self->{"panelType"} eq EnumsProducPanel->SIZE_MULTILAYER_538 ) {
			$schema = 'rigid_vv_538';
		}
	}

	$self->{"newPnl"}->AddSchema($schema);

	return $result;
}

# Set layer attributes
sub SetLayerAtt {
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

