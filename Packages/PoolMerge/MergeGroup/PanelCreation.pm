
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::MergeGroup::PanelCreation;
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
use aliased 'Packages::NifFile::NifFile';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::ProductionPanel::PanelDimension';
use aliased 'Packages::CAMJob::Panelization::SRStep';

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

 

# Decide which panel dimensions use, based on layer cnt and dimension from pool file
sub CreatePanel {
	my $self      = shift;
	my $masterJob = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my @orders = $self->{"poolInfo"}->GetOrdersInfo();

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $masterJob );

	# 1) Choose panel type  Enums::EnumsProducPanel::panelsize_XXX
	my $panelType = PanelDimension->GetPanelNameByArea( $masterJob, $self->{"poolInfo"}->GetPnlW(), $self->{"poolInfo"}->GetPnlH() );

	my $panelDims = PanelDimension->GetDimensionPanel( $inCAM, $panelType );

	# 2) Create new "panel" step
	my $newPnl = SRStep->new( $inCAM, $masterJob, "panel" );

	$newPnl->Create( $panelDims->{"PanelSizeX"}, $panelDims->{"PanelSizeY"}, $panelDims->{"BorderTop"},
					 $panelDims->{"BorderBot"},  $panelDims->{"BorderLeft"}, $panelDims->{"BorderRight"} );

	# 3) add step and repeat

	foreach my $orderInf (@orders) {

		foreach my $pos ( @{ $orderInf->{"pos"} } ) {

			$newPnl->AddSRStep( "panel", $orderInf->{"jobName"}, $pos->{"x"}, $pos->{"y"}, ( $pos->{"rotated"} ? 270 : 0 ) );
		}
	}

	# 4) add schema
	my $schema = undef;

	if ( $layerCnt <= 2 ) {

		$schema = "1a2v";
	}
	else {

		if ( $panelDims->{"PanelSizeY"} == 407 ) {
			$schema = '4v-407';
		}
		else {
			$schema = '4v-485';
		}
	}
	
	$newPnl->AddSchema($schema);
	
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

