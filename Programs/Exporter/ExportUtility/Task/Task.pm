
#-------------------------------------------------------------------------------------------#
# Description: Represent one task, which are in the queue. Responsible for
# - Initialize units
# - Pass message to specific units
# - Responsible for updating ExportStauts
# - Responsible for sending pcb to produce
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Task::Task;
use base("Managers::AbstractQueue::Task::Task");

#3th party library
use strict;
use warnings;
use Sys::Hostname;
use Log::Log4perl qw(get_logger :levels);

#local library
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsIS';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Programs::Exporter::ExportUtility::Enums';
use aliased 'Managers::AbstractQueue::Unit::UnitBase';
use aliased 'Managers::AbstractQueue::TaskResultMngr';
use aliased 'Packages::Other::AppConf';
use aliased 'Programs::Services::LogService::Logger::DBLogger';
use aliased 'Enums::EnumsApp';
use aliased 'Managers::AsyncJobMngr::Helper' => "AsyncJobHelber";
use aliased 'Programs::Services::Helpers::AutoProcLog';

#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	# Managers, contains information about results of
	# whole task, groups, single items, etc
	$self->{"produceResultMngr"} = TaskResultMngr->new();

	# Tell if job can be send to produce,
	# based on Export results and StatusFile
	$self->{"canToProduce"} = undef;

	$self->{"sentToProduce"} = 0;    # Tell if task was sent to produce

	$self->__InitUnits();

	return $self;
}

# ===================================================================
# Public method
# ===================================================================

sub ProduceResultMngr {
	my $self = shift;

	return $self->{"produceResultMngr"};
}

# ===================================================================
# Public method - GET or SET state of this task
# ===================================================================

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

sub GetProduceErrorsCnt {
	my $self = shift;

	return $self->{"produceResultMngr"}->GetErrorsCnt();
}

sub GetProduceWarningsCnt {
	my $self = shift;

	return $self->{"produceResultMngr"}->GetWarningsCnt();
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

	return $self->{"taskData"}->GetToProduce();
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
	if ( !$self->{"taskStatus"}->IsTaskOk( \@notExportUnits ) ) {

		my @notExportUnits = map { UnitEnums->GetTitle($_) } @notExportUnits;
		my $str = join( ", ", @notExportUnits );

		my $errorStr = "Can't sent \"to produce\", because some groups haven't been exported succesfully. \n";
		$errorStr .= "Groups that need to be exported: <b> $str </b>\n";

		$self->{"canToProduce"} = 0;

		my $item = $toProduceMngr->GetNewItem( "Export status", EnumsGeneral->ResultType_FAIL );

		$item->AddError($errorStr);
		$toProduceMngr->AddItem($item);
	}

}

sub SentToProduce {
	my $self = shift;

	my $result = 1;

	# set state HOTOVO-zadat

	eval {

		my $taksData = $self->GetTaskData();

		foreach my $orderNum ( $taksData->GetOrders() ) {

			my $curStep = HegMethods->GetCurStepOfOrder($orderNum);

			#my $orderRef = HegMethods->GetPcbOrderNumber( $self->{"jobId"} );
			#my $orderNum = $self->{"jobId"} . "-" . $orderRef;

			if ( $curStep ne EnumsIS->CurStep_HOTOVOZADAT ) {

				my $succ = HegMethods->UpdatePcbOrderState( $orderNum, EnumsIS->CurStep_HOTOVOZADAT );
			}
		}
		
		# remove auto process log
		if ( AsyncJobHelber->ServerVersion() ) {
			AutoProcLog->Delete($self->GetJobId()); 
		}
		
		$self->{"taskStatus"}->DeleteStatusFile();
		$self->{"sentToProduce"} = 1;
	};

	if ( my $e = $@ ) {

		# set status hotovo-yadat fail
		my $toProduceMngr = $self->{"produceResultMngr"};
		my $item = $toProduceMngr->GetNewItem( "Set state HOTOVO-zadat", EnumsGeneral->ResultType_FAIL );

		$item->AddError("Set state HOTOVO-zadat failed, try it again. Detail: ".$@."\n");
		$toProduceMngr->AddItem($item);

		$result = 0;

	}

	return $result;

}

# Set error state to order + send log to db, if server version
sub SetErrorState {
	my $self = shift;

	my $result = 1;

	# Load errors

	my $produceMngr = $self->ProduceResultMngr();
	my $taskMngr    = $self->GetTaskResultMngr();
	my $groupMngr   = $self->GetGroupResultMngr();
	my $itemMngr    = $self->GetGroupItemResultMngr();

	my $str = "";
	$str .= $produceMngr->GetErrorsStr() . "\n";
	$str .= $taskMngr->GetErrorsStr() . "\n";
	$str .= $groupMngr->GetErrorsStr() . "\n";
	$str .= $itemMngr->GetErrorsStr() . "\n";

	# set state ExportUtility error, only if actual step si not Hotovo-zadat AND exportUtility error

	eval {

		my $taksData = $self->GetTaskData();

		# 1) Set cruurent step
		foreach my $orderNum ( $taksData->GetOrders() ) {

			my $curStep = HegMethods->GetCurStepOfOrder($orderNum);

			if ( $curStep ne EnumsIS->CurStep_HOTOVOZADAT && $curStep ne EnumsIS->CurStep_EXPORTERROR ) {

				my $succ = HegMethods->UpdatePcbOrderState( $orderNum, EnumsIS->CurStep_EXPORTERROR );
			}
		}

		# 2) store to log file
		get_logger("abstractQueue")->info( "Job: " . $self->GetJobId() . " finished with errors.\n $str" );

		# store to database if server version
		if ( AsyncJobHelber->ServerVersion() ) {

			$self->{"loggerDB"} = DBLogger->new( EnumsApp->App_EXPORTUTILITY );

			$self->{"loggerDB"}->Error( $self->GetJobId(),
									 "Error during export job id: \"" . $self->GetJobId() . "\" on server computer. See details on server. \n $str" );

			AutoProcLog->Create( EnumsApp->App_EXPORTUTILITY, $self->GetJobId(), "Job: " . $self->GetJobId() . " finished with errors.\n $str" );
 
		}
	};
	if ( my $e = $@ ) {

		print STDERR $e;

	}
}

#-------------------------------------------------------------------------------------------#
#  Private method
#-------------------------------------------------------------------------------------------#

sub __InitUnits {
	my $self = shift;

	my @keys     = $self->{"taskData"}->GetOrderedUnitKeys(1);
	my @allUnits = ();

	foreach my $key (@keys) {

		my $unit = $self->__GetUnitClass($key);
		push( @allUnits, $unit );
	}

	$self->{"units"}->SetUnits( \@allUnits );

}

# Return initialized "unit" object by unitId
sub __GetUnitClass {
	my $self   = shift;
	my $unitId = shift;

	my $jobId = $self->{"jobId"};

	my $title = UnitEnums->GetTitle($unitId);

	my $unit = UnitBase->new( $unitId, $jobId, $title );

	return $unit;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

