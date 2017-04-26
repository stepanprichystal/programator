
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
use aliased 'Packages::PoolMerge::MergeGroup::Helper::PanelCreation';
use aliased 'Packages::PoolMerge::MergeGroup::Helper::CopySteps';
use aliased 'Packages::PoolMerge::MergeGroup::Helper::PutLabels';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class    = shift;
	my $inCAM    = shift;
	my $poolInfo = shift;
	my $self     = $class->SUPER::new( $poolInfo->GetInfoFile(), @_ );
	bless $self;

	$self->{"setDefautState"} = 1;

	$self->{"inCAM"}    = $inCAM;
	$self->{"poolInfo"} = $poolInfo;

	$self->{"copySteps"} = CopySteps->new( $inCAM, $poolInfo );
	$self->{"copySteps"}->{"onItemResult"}->Add( sub { $self->_OnPoolItemResult(@_) } );
	$self->{"panelCreation"} = PanelCreation->new( $inCAM, $poolInfo );
	$self->{"putLabels"} = PutLabels->new( $inCAM, $poolInfo );

	return $self;
}

sub Run {
	my $self = shift;

	my $masterJob = $self->GetValInfoFile("masterJob");




	# 1) set state "slouceno"
	my $stateRes = $self->_GetNewItem("Set state \"slouceno\"");
	my $mess = "";

	unless ( $self->{"copySteps"}->SetNewJobsState( "slouceno", \$mess ) ) {

		$stateRes->AddError($mess);
	}

	$self->_OnPoolItemResult($stateRes);
	

	# 2) Copy child step to master job

	$self->{"copySteps"}->CopySteps($masterJob);

	# 3) Final check of step copy
	my $stepCopyCheckRes = $self->_GetNewItem("Step copy check");
	$mess             = "";

	unless ( $self->{"copySteps"}->CopyStepFinalCheck( $masterJob, \$mess ) ) {

		$stepCopyCheckRes->AddError($mess);
	}

	$self->_OnPoolItemResult($stepCopyCheckRes);

	# 3) Check on empty layers of steps
	my $emptyLayersRes = $self->_GetNewItem("Empty layers");
	$mess = "";

	unless ( $self->{"copySteps"}->EmptyLayers( $masterJob, \$mess ) ) {

		$emptyLayersRes->AddWarning($mess);
	}

	$self->_OnPoolItemResult($emptyLayersRes);

	# 3) Check on empty layers of steps
	my $createPanelRes = $self->_GetNewItem("Create panel");
	$mess = "";

	unless ( $self->{"panelCreation"}->CreatePanel( $masterJob, \$mess ) ) {

		$createPanelRes->AddError($mess);
	}

	$self->_OnPoolItemResult($createPanelRes);

	# 3) Check on empty layers of steps
	my $addLabelsRes = $self->_GetNewItem("Add labels");
	$mess = "";

	unless ( $self->{"putLabels"}->AddLabels( $masterJob, \$mess ) ) {

		$addLabelsRes->AddError($mess);
	}

	$self->_OnPoolItemResult($addLabelsRes);

}

sub __OnStepCopyResult {
	my $self   = shift;
	my $result = shift;

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += scalar( $self->{"poolInfo"}->GetJobNames() ) - 1;    # copy all jobs to master (-1 master)
	$totalCnt += 5;                                                   # other checks and etc..

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

