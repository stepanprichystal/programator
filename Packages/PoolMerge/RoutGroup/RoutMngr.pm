
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::RoutGroup::RoutMngr;
use base('Packages::PoolMerge::PoolMngrBase');

use Class::Interface;
&implements('Packages::PoolMerge::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::PoolMerge::RoutGroup::Helper::RoutHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class    = shift;
	my $inCAM    = shift;
	my $poolInfo = shift;
	my $self     = $class->SUPER::new( $poolInfo->GetInfoFile(), @_ );
	bless $self;

	$self->{"inCAM"}    = $inCAM;
	$self->{"poolInfo"} = $poolInfo;
	
	$self->{"routHelper"} = RoutHelper->new( $inCAM, $poolInfo );
	$self->{"routHelper"}->{"onItemResult"}->Add( sub { $self->_OnPoolItemResult(@_) } );
 
	return $self;
}

sub Run {
	my $self = shift;

 	my $masterJob = $self->GetValInfoFile("masterJob");
 
 	# 1) Create fsch
 	
 	$self->{"routHelper"}->CreateFsch( $masterJob);

	 

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 7;    # crate fsch, 7 item results..
	return $totalCnt;

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

