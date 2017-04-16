
#-------------------------------------------------------------------------------------------#
# Description: Represent one task, which are in the queue. Responsible for
# - Initialize units
# - Pass message to specific units
# - Responsible for updating TaskStauts
# - Responsible for sending pcb to produce
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::Task::Task;

#3th party library
use strict;
use warnings;

#local library
 

use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';

#use aliased 'Managers::AbstractQueue::AbstractQueue::Groups::NC2Unit';
#use aliased 'Managers::AbstractQueue::AbstractQueue::Groups::NC3Unit';
#use aliased 'Managers::AbstractQueue::AbstractQueue::Groups::NC4Unit';
#use aliased 'Managers::AbstractQueue::AbstractQueue::Groups::NC5Unit';
use aliased 'Managers::AbstractQueue::Unit::Units';
use aliased 'Managers::AbstractQueue::TaskResultMngr';
#use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;    # job id, which is processed

	$self->{"taskData"} = shift;    # prepared task data, necessary for task processing
	
	$self->{"taskStrData"} = shift;    # task data serialized in string

	$self->{"taskStatus"} = shift;  # Class responsible for updating StatusFile in job archive
	
	# Object, which keep all units objects
	$self->{"units"} = Units->new( $self->{"jobId"} );

	$self->{"taskId"} = GeneralHelper->GetGUID();    # unique id per each task


	# Managers, contains information about results of
	# whole task, groups, single items, etc

	$self->{"taskResultMngr"} = TaskResultMngr->new();

	$self->{"groupResultMngr"} = TaskResultMngr->new();

	$self->{"itemResultMngr"} = TaskResultMngr->new();

	$self->{"aborted"} = 0;    # Tell if task was aborted by user
 
	my @mandatoryUnits = $self->{"taskData"}->GetMandatoryUnits();
	$self->{"taskStatus"}->CreateStatusFile( \@mandatoryUnits );
 
	return $self;
}

# ===================================================================
# Public method
# ===================================================================

sub GetTaskId {
	my $self = shift;

	return $self->{"taskId"};
}

sub GetJobId {
	my $self = shift;

	return $self->{"jobId"};
}

sub GetAllUnits {
	my $self = shift;
	return $self->{"units"}->GetUnits();
}

sub GetTaskData {
	my $self = shift;
	return $self->{"taskData"};
}

sub GetTaskStrData {
	my $self = shift;
	return $self->{"taskStrData"};
}

sub GetTaskResultMngr {
	my $self = shift;

	return $self->{"taskResultMngr"};
}

sub GetGroupResultMngr {
	my $self = shift;
	return $self->{"groupResultMngr"};
}

sub GetGroupItemResultMngr {
	my $self = shift;

	return $self->{"itemResultMngr"};
}

# ===================================================================
# Public method - GET or SET state of this task
# ===================================================================

sub GetJobAborted {
	my $self = shift;

	return $self->{"aborted"};
}

# Return task Result of whole task
sub Result {
	my $self = shift;

	my $totalResult = EnumsGeneral->ResultType_OK;

	# result from all units
	my $unitsResult = $self->{"units"}->Result();

	# result - test if user abort job
	my $taskAbortedResult = EnumsGeneral->ResultType_OK;

	if ( $self->{"aborted"} ) {
		$taskAbortedResult = EnumsGeneral->ResultType_FAIL;
	}

	# result for task
	my $taskResult = $self->{"taskResultMngr"}->Succes();

	if ($taskResult) {
		$taskResult = EnumsGeneral->ResultType_OK;
	}
	else {
		$taskResult = EnumsGeneral->ResultType_FAIL;
	}

	if (    $unitsResult eq EnumsGeneral->ResultType_FAIL
		 || $taskResult eq EnumsGeneral->ResultType_FAIL
		 || $taskAbortedResult eq EnumsGeneral->ResultType_FAIL )
	{

		$totalResult = EnumsGeneral->ResultType_FAIL;
	}

	return $totalResult;
}

sub GetProgress {
	my $self = shift;

	my $totalProgress = $self->{"units"}->GetProgress();

	print " =========================== Total progress per task: $totalProgress \n";

	return $totalProgress;
}

sub GetErrorsCnt {
	my $self = shift;

	my $taskErrCnt  = $self->{"taskResultMngr"}->GetErrorsCnt();
	my $unitsErrCnt = $self->{"units"}->GetErrorsCnt();

	return $taskErrCnt + $unitsErrCnt;
}

sub GetWarningsCnt {
	my $self = shift;

	my $taskWarnCnt  = $self->{"taskResultMngr"}->GetWarningsCnt();
	my $unitsWarnCnt = $self->{"units"}->GetWarningsCnt();

	return $taskWarnCnt + $unitsWarnCnt;
}

# ===================================================================
# Method regardings "to produce" issue
# ===================================================================

# ===================================================================
# Method , which procces messages from working thread
# ===================================================================

sub ProcessItemResult {
	my $self = shift;
	my $data = shift;

	$self->{"units"}->ProcessItemResult($data);

	# Fill/update items result manager
	my @allItems = $self->{"units"}->GetGroupItemResultMngr()->GetAllItems();

	# update "task" item result manager, when item finish
	$self->{"itemResultMngr"}->Clear();
	$self->{"itemResultMngr"}->AddItems( \@allItems );
}

sub ProcessGroupResult {
	my $self = shift;
	my $data = shift;

	$self->{"units"}->ProcessGroupResult($data);

	my @allItems = $self->{"units"}->GetGroupResultMngr()->GetAllItems();

	# update "task" group result manager, when group finish
	$self->{"groupResultMngr"}->Clear();
	$self->{"groupResultMngr"}->AddItems( \@allItems );

}

sub ProcessGroupStart {
	my $self = shift;
	my $data = shift;

	my $unitId = $data->{"unitId"};

	my $unit = $self->_GetUnit($unitId);

	$unit->ProcessGroupStart();
}

sub ProcessGroupEnd {
	my $self = shift;
	my $data = shift;

	my $unitId = $data->{"unitId"};

	my $unit = $self->_GetUnit($unitId);

	$unit->ProcessGroupEnd();

	$self->{"taskStatus"}->UpdateStatusFile( $unitId, $unit->Result() );
}

sub ProcessTaskResult {
	my $self = shift;
	my $data = shift;

	my $result     = $data->{"result"};
	my $errorsStr  = $data->{"errors"};
	my $warningStr = $data->{"warnings"};
	my $id         = $self->{"jobId"};

	$self->{"taskResultMngr"}->CreateTaskItem( $id, $result, undef, $errorsStr, $warningStr );

}

sub ProcessTaskDone {
	my $self    = shift;
	my $aborted = shift;

	$self->{"aborted"} = $aborted;

}

sub ProcessProgress {
	my $self = shift;
	my $data = shift;

	my $unitId   = $data->{"unitId"};
	my $progress = $data->{"value"};

	my $unit = $self->_GetUnit($unitId);

	$unit->ProcessProgress($progress);

}


sub ProcessTaskContinue {
	my $self = shift;
	my $data = shift;

	my $unitId   = $data->{"unitId"};
	 
	my $unit = $self->_GetUnit($unitId);

	$unit->ProcessTaskContinue($unitId);
}
#-------------------------------------------------------------------------------------------#
#  Protected method
#-------------------------------------------------------------------------------------------#

sub _GetUnit {
	my $self   = shift;
	my $unitId = shift;

	return $self->{"units"}->GetUnitById($unitId);

}

#-------------------------------------------------------------------------------------------#
#  Private method
#-------------------------------------------------------------------------------------------#


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

