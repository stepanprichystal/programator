
#-------------------------------------------------------------------------------------------#
# Description: Represent one task, which are in the queue. Responsible for
# - Initialize units
# - Pass message to specific units
# - Responsible for updating ExportStauts
# - Responsible for sending pcb to produce
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Task::Task;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::UnitEnums';

use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::NCExport::NCUnit';

#use aliased 'Programs::Exporter::ExportUtility::Groups::NC2Unit';
#use aliased 'Programs::Exporter::ExportUtility::Groups::NC3Unit';
#use aliased 'Programs::Exporter::ExportUtility::Groups::NC4Unit';
#use aliased 'Programs::Exporter::ExportUtility::Groups::NC5Unit';
use aliased 'Programs::Exporter::ExportUtility::Unit::Units';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::ExportStatus::ExportStatus';
use aliased 'Programs::Exporter::ExportUtility::ExportResultMngr';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"taskId"} = shift;    # unique task Id

	$self->{"jobId"} = shift;     # job id, which is processed

	$self->{"exportData"} = shift;    # exported data, from ExportChecker program

	# Managers, contains information about results of
	# whole task, groups, single items, etc

	$self->{"produceResultMngr"} = ExportResultMngr->new();

	$self->{"taskResultMngr"} = ExportResultMngr->new();

	$self->{"groupResultMngr"} = ExportResultMngr->new();

	$self->{"itemResultMngr"} = ExportResultMngr->new();

	# Object, which keep all units objects
	$self->{"units"} = Units->new( $self->{"jobId"} );

	# Class responsible for updating StatusFile in job archive
	$self->{"exportStatus"} = ExportStatus->new( $self->{"jobId"} );

	$self->{"aborted"} = 0;    # Tell if task was aborted by user

	# Tell if job can be send to produce,
	# based on Export results and StatusFile
	$self->{"canToProduce"} = undef;

	$self->{"sentToProduce"} = 0;    # Tell if task was sent to produce

	$self->__InitUnit();

	my @defaultUnits = $self->{"exportData"}->GetDefaultUnits();
	$self->{"exportStatus"}->CreateStatusFile( \@defaultUnits );

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
	return @{ $self->{"units"}->{"units"} };
}

sub GetExportData {
	my $self = shift;
	return $self->{"exportData"};
}

sub ProduceResultMngr {
	my $self = shift;

	return $self->{"produceResultMngr"};
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

# Return export Result of whole task
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

# Return result, which tell if pcb can be send to produce
sub ResultToProduce {
	my $self = shift;

	my $res = $self->{"produceResultMngr"}->Succes();

	if ($res) {
		$res = EnumsGeneral->ResultType_OK;
	}
	else {
		$res = EnumsGeneral->ResultType_FAIL;
	}
	return $res;
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

sub GetProduceErrorsCnt {
	my $self = shift;

	return $self->{"produceResultMngr"}->GetErrorsCnt();
}

sub GetProduceWarningsCnt {
	my $self = shift;

	return $self->{"produceResultMngr"}->GetWarningsCnt();
}

# ===================================================================
# Method regardings "to produce" issue
# ===================================================================

# Tell if job was sent to produce
sub GetJobSentToProduce {
	my $self = shift;

	return $self->{"sentToProduce"};
}

# Tell if job was not aborted by user during export
# If no, job can/hasn't be sent to produce
sub GetJobCanToProduce {
	my $self = shift;

	return $self->{"canToProduce"};
}

# Tell if user checked in export, job should be sent
# to product automatically
sub GetJobShouldToProduce {
	my $self = shift;

	return $self->{"exportData"}->GetToProduce();
}

# Test if job can be send to produce
# Set results of this action to manager
sub SetToProduceResult {
	my $self = shift;

	$self->{"canToProduce"} = 1;

	my $toProduceMngr = $self->{"produceResultMngr"};

	$toProduceMngr->Clear();

	# check if export is succes
	if ( $self->Result() eq EnumsGeneral->ResultType_FAIL ) {

		my $errorStr = "Can't sent \"to produce\",  ";

		if ( $self->GetJobAborted() ) {

			$errorStr .= "because export was aborted by user.";
			$self->{"canToProduce"} = 0;

		}
		else {

			$errorStr .= "because export was not succes.";
		}

		my $item = $toProduceMngr->GetNewItem( "Sent to produce", EnumsGeneral->ResultType_FAIL );

		$item->AddError($errorStr);
		$toProduceMngr->AddItem($item);
	}

	my @notExportUnits = ();
	if ( !$self->{"exportStatus"}->IsExportOk( \@notExportUnits ) ) {

		my @notExportUnits = map { UnitEnums->GetTitle($_) } @notExportUnits;
		my $str = join( ", ", @notExportUnits );

		my $errorStr = "Can't sent \"to produce\", because some groups wern't exported succesfully in past. \n";
		$errorStr .= "Groups that need to be exported: <b> $str </b>\n";

		$self->{"canToProduce"} = 0;

		my $item = $toProduceMngr->GetNewItem( "Export status", EnumsGeneral->ResultType_FAIL );

		$item->AddError($errorStr);
		$toProduceMngr->AddItem($item);
	}

}

sub SentToProduce {
	my $self = shift;

	# set state HOTOVO-zadat

	eval {
		my $orderRef = HegMethods->GetPcbOrderNumber( $self->{"jobId"} );
		my $orderNum = $self->{"jobId"} . "-" . $orderRef;
		
		my $succ     = HegMethods->UpdatePcbOrderState( $orderNum, "HOTOVO-zadat" );
		
		
		$self->{"exportStatus"}->DeleteStatusFile();
		$self->{"sentToProduce"} = 1;
	};

	if ( my $e = $@ ) {

		open my $OUT, ">", 'c:\Export\test\err' or die $!;
		print $OUT "err";
		close($OUT);

	}

}

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

	my $unit = $self->__GetUnit($unitId);

	$unit->ProcessGroupStart();
}

sub ProcessGroupEnd {
	my $self = shift;
	my $data = shift;

	my $unitId = $data->{"unitId"};

	my $unit = $self->__GetUnit($unitId);

	$unit->ProcessGroupEnd();

	$self->{"exportStatus"}->UpdateStatusFile( $unitId, $unit->Result() );
}

sub ProcessTaskResult {
	my $self = shift;
	my $data = shift;

	my $result     = $data->{"result"};
	my $errorsStr  = $data->{"errors"};
	my $warningStr = $data->{"warnings"};
	my $id         = $self->{"jobId"};

	$self->{"taskResultMngr"}->CreateExportItem( $id, $result, undef, $errorsStr, $warningStr );

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

	my $unit = $self->__GetUnit($unitId);

	$unit->ProcessProgress($progress);

}

#-------------------------------------------------------------------------------------------#
#  Private method
#-------------------------------------------------------------------------------------------#
# Init groups by exported data
sub __InitUnit {
	my $self = shift;

	my @keys = $self->{"exportData"}->GetOrderedUnitKeys(1);

	$self->{"units"}->Init( \@keys );

}

sub __GetUnit {
	my $self   = shift;
	my $unitId = shift;

	return $self->{"units"}->GetUnitById($unitId);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

