#-------------------------------------------------------------------------------------------#
# Description: Notify manager for pool merger
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::PoolMerge::NotifyMngr;
use base("Managers::AbstractQueue::NotifyMngr::NotifyMngr");

#3th party library
use strict;
use warnings;

#local library
use aliased 'Managers::AsyncJobMngr::Enums' => 'EnumsJobMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Widgets::Forms::ResultIndicator::ResultIndicator';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub JobStateChanged {
	my $self            = shift;
	my $task            = shift;
	my $taskState       = shift;
	my $taskStateDetail = shift;

	# show only if form is in tray or if is iconized
	my $parentFrm = $self->{"abstractQueue"}->{"mainFrm"};

	if ( $parentFrm->IsShown() && !$parentFrm->IsIconized() ) {
		return 0;
	}

	my $taskId  = $task->GetTaskId();
	my $jobId   = $task->GetJobId();
	my $message = "";

	my $taskMode = $task->GetTaskData()->GetTaskMode();

	if ( $taskState eq EnumsJobMngr->JobState_WAITINGQUEUE ) {

		$message = "Was added to queue ...";

		if ( $taskMode eq EnumsJobMngr->TaskMode_ASYNC ) {

			$self->_ShowStandardMessNotify( $taskId, $jobId, $message, 1, 3 );
		}
	}
	elsif ( $taskState eq EnumsJobMngr->JobState_RUNNING ) {

		$message = "Start running ...";

		$self->_ShowStandardMessNotify( $taskId, $jobId, $message, 1, 3 );

	}
	elsif ( $taskState eq EnumsJobMngr->JobState_DONE ) {

		my $totalResult          = 1;
		my $toExportResultStatus = EnumsGeneral->ResultType_NA;

		if ( $task->Result() ne EnumsGeneral->ResultType_OK ) {

			$totalResult = 0;
		}

		if ( !$task->GetJobCanSentToExport() ) {

			$toExportResultStatus = EnumsGeneral->ResultType_FAIL;
			$totalResult          = 0;
		}
		else {

			$toExportResultStatus = EnumsGeneral->ResultType_OK;
		}

		$message = "Pool merging done";

		$self->_ShowStandardResNotify(
									   $taskId, $jobId, $message, 1,
									   ( $totalResult ? 3 : 300 ), $task->Result(), $toExportResultStatus, "Merging result:",
									   "Send to export:"
		);
	}

}

sub JobPaused {
	my $self = shift;
	my $task = shift;

	# show only if form is in tray or if is iconized
	my $parentFrm = $self->{"abstractQueue"}->{"mainFrm"};

	if ( $parentFrm->IsShown() && !$parentFrm->IsIconized() ) {
		return 0;
	}

	my $taskId = $task->GetTaskId();
	my $jobId  = $task->GetJobId();

	$self->_ShowStandardMessNotify( $taskId, $jobId, "Merging is PAUSED", 0, undef );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';

	#my $id

	#my $form = StorageMngr->new();

}

1;

