
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for fsch layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::RoutGroup::Helper::RoutHelper;
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
use aliased 'Packages::Routing::RoutLayer::FlattenRout::FlattenPanel::FlattenPanel';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';

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

sub CreateFsch {
	my $self = shift;
	my $masterJob = shift;
	my $mess = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	
	my @excludeSteps = grep { $_ ne EnumsGeneral->Coupon_IMPEDANCE } JobHelper->GetCouponStepNames();
	my $flatten = FlattenPanel->new( $inCAM, $masterJob, "panel", "f", "fsch", 1, \@excludeSteps );

	$flatten->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	$result = $flatten->Run();
 
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

