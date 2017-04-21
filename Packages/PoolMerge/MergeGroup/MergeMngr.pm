
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::MergeGroup::MergeMngr;
use base('Packages::PoolMerge::PoolMngrBase');

use Class::Interface;
&implements('Packages::PoolMerge::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Managers::AbstractQueue::Enums' => "EnumsAbstrQ";
use aliased 'Programs::PoolMerge::Enums'     => "EnumsPool";
use aliased 'Helpers::FileHelper';

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

	$self->{"copySteps"} = CopySteps->new( $inCAM, $poolInfo );
	$self->{"panelCreation"} = PanelCreation->new( $inCAM, $poolInfo );
	$self->{"panelCreation"}->{"onItemResult"}->Add( sub { $self->_OnPoolItemResult(@_) } );
	$self->{"pcbLabel"} = PcbLabel->new( $inCAM, $poolInfo );

	return $self;
}

sub Run {
	my $self = shift;

	my $masterJob = $self->GetValInfoFile("masterJob");

	# Let "pool merger" know, master job was chosen
	# Then "pool merger" open it
	if ( defined $masterJob ) {

		$self->_OnSetMasterJob($masterJob);

	}
	else {
		die "Master job is not defined";
	}

	# 2) Copy child step to master job
	my $copyStepsRes = $self->_GetNewItem("Mater job checks");

	$self->{"panelCreation"}->CopySteps($masterJob);

	# 3) Final check of step copy
	my $stepCopyRes = $self->_GetNewItem("Step copy check");
	my $mess        = "";

	unless ( $self->{"panelCreation"}->CopyStepFinalCheck( $masterJob, \$mess ) ) {

		$stepCopyRes->AddError($mess);
	}

	$self->_OnPoolItemResult($stepCopyRes);

	# 3) Check on empty layers of steps
	my $emptyLayersRes = $self->_GetNewItem("Step copy check");
	$mess = "";

	unless ( $self->{"panelCreation"}->EmptyLayers( $masterJob, \$mess ) ) {

		$emptyLayersRes->AddWarning($mess);
	}

	$self->_OnPoolItemResult($emptyLayersRes);

}

sub __OnStepCopyResult {
	my $self   = shift;
	my $result = shift;

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += scalar( $self->{"poolInfo"}->GetJobNames() ) - 1;    # copy all jobs to master (-1 master)
	$totalCnt += 1;                                                   # final control of copy step
	$totalCnt += 1;                                                   # check on empty layers
	$totalCnt += 1;                                                   # panel ceration
	$totalCnt += 1;                                                   # put labels check

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

