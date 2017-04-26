
#-------------------------------------------------------------------------------------------#
# Description: Represent one task, which are in the queue. Responsible for
# - Initialize units
# - Pass message to specific units
# - Responsible for updating ExportStauts
# - Responsible for sending pcb to toExport
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::Task::Task;
use base("Managers::AbstractQueue::Task::Task");

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'Programs::PoolMerge::UnitEnums';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
#use aliased 'Programs::PoolMerge::Groups::MergeGroup::MergeUnit';
#use aliased 'Programs::PoolMerge::Groups::RoutGroup::RoutUnit';
#use aliased 'Programs::PoolMerge::Groups::OutputGroup::OutputUnit';
use aliased 'Managers::AbstractQueue::Unit::UnitBase';

#use aliased 'Connectors::HeliosConnector::HegMethods';
 
 
use aliased 'Managers::AbstractQueue::TaskResultMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
 
	my $self = $class->SUPER::new(@_);
	bless $self;

	# Managers, contains information about results of
	# whole task, groups, single items, etc
 	$self->{"toExportResultMngr"} = TaskResultMngr->new();
 
	# Tell if job can be send to toExport,
	# based on Export results and StatusFile
	$self->{"canSentToExport"} = undef;

	$self->{"sentToExport"} = 0;    # Tell if task was sent to toExport
	
	$self->{"masterJob"}  = undef; # Choosen master job of pool panel
	
	$self->__InitUnits();

 
	return $self;
}

# ===================================================================
# Public method
# ===================================================================
 
sub SetMasterJob {
	my $self = shift;
	my $masterJob = shift;

	$self->{"masterJob"} = $masterJob;
}

sub GetMasterJob {
	my $self = shift;

	return $self->{"masterJob"};
}

sub ToExportResultMngr {
	my $self = shift;

	return $self->{"toExportResultMngr"};
}
 

# ===================================================================
# Public method - GET or SET state of this task
# ===================================================================

  

# Return result, which tell if pcb can be send to toExport
sub ResultSentToExport {
	my $self = shift;

	my $notConsiderWarn = 1;
	my $res = $self->{"toExportResultMngr"}->Succes($notConsiderWarn);

	if ($res) {
		$res = EnumsGeneral->ResultType_OK;
	}
	else {
		$res = EnumsGeneral->ResultType_FAIL;
	}
	return $res;
}
 

sub GetToExportErrorsCnt {
	my $self = shift;

	return $self->{"toExportResultMngr"}->GetErrorsCnt();
}

sub GetToExportWarningsCnt {
	my $self = shift;

	return $self->{"toExportResultMngr"}->GetWarningsCnt();
}


# ===================================================================
# Method regardings "to toExport" issue
# ===================================================================

# Tell if job was sent to toExport
sub GetJobSentToExport {
	my $self = shift;

	return $self->{"sentToExport"};
}

# Tell if job was not aborted by user during processing
# If no, job can/hasn't be sent to toExport
sub GetJobCanSentToExport {
	my $self = shift;

	return $self->{"canSentToExport"};
}


# Test if job can be send to toExport
# Set results of this action to manager
sub SetSentToExportResult {
	my $self = shift;

	$self->{"canSentToExport"} = 1;

	my $sentToExportMngr = $self->{"toExportResultMngr"};

	$sentToExportMngr->Clear();

	# check if task process is succes
	my $warnNotConsider = 1;
	if ( $self->Result($warnNotConsider) eq EnumsGeneral->ResultType_FAIL ) {

		my $errorStr = "Can't sent \"to export\",  ";

		if ( $self->GetJobAborted() ) {

			$errorStr .= "because pool merging was aborted by user.";
			$self->{"canSentToExport"} = 0;

		}
		else {

			$errorStr .= "because pool merging was not succes.";
		}

		my $item = $sentToExportMngr->GetNewItem( "Sent to toExport", EnumsGeneral->ResultType_FAIL );

		$item->AddError($errorStr);
		$sentToExportMngr->AddItem($item);
	}
	
	
	
	if ( $self->Result() eq EnumsGeneral->ResultType_OK && $self->{"units"}->GetWarningsCnt() > 0 ) {
		
		my $errorStr = "Can't sent \"to export\" automatically, because poom merging contains some warnings.\n ";
		$errorStr .= "First check warnings, then send taks to export by button \"Export\" manually.";
 
		my $item = $sentToExportMngr->GetNewItem( "Sent to toExport", EnumsGeneral->ResultType_FAIL );

		$item->AddWarning($errorStr);
		$sentToExportMngr->AddItem($item);
	}

	my @notExportUnits = ();
	if ( !$self->{"taskStatus"}->IsTaskOk( \@notExportUnits ) ) {

		my @notExportUnits = map { UnitEnums->GetTitle($_) } @notExportUnits;
		my $str = join( ", ", @notExportUnits );

		my $errorStr = "Can't sent \"to export\", because some groups haven't been processed succesfully. \n";
		$errorStr .= "Groups that need to be processed: <b> $str </b>\n";

		$self->{"canSentToExport"} = 0;

		my $item = $sentToExportMngr->GetNewItem( "Export status", EnumsGeneral->ResultType_FAIL );

		$item->AddError($errorStr);
		$sentToExportMngr->AddItem($item);
	}
	
   
}

sub SentToExport {
	my $self = shift;

	# Move prepared export  file to user export file location c:/Export/Exportfiles/pcb

	eval {
		
		my $taskData = $self->GetTaskData();
		
		my $exportFile = EnumsPaths->Client_INCAMTMPOTHER . $taskData->GetInfoFileVal("exportFile");
		my $target = EnumsPaths->Client_EXPORTFILES.$self->GetMasterJob();
		
		if(-e $exportFile){
			move($exportFile, $target);
			$self->{"taskStatus"}->DeleteStatusFile();
			$self->{"sentToExport"} = 1;
			$taskData->DeleteInfoFile();
			# remove from queue
			 
		}else{
			
			#error
		}

	};

	if ( my $e = $@ ) {

		 # set status hotovo-yadat fail
		 my $sentToExportMngr = $self->{"toExportResultMngr"};
		 my $item = $sentToExportMngr->GetNewItem( "Sent to export", EnumsGeneral->ResultType_FAIL );

		$item->AddError("Error during sending task \"to export. Error when \" copy \"export file\" $e\n");
		$sentToExportMngr->AddItem($item);
	}

}


# ===================================================================
# Method , which procces messages from working thread
# ===================================================================
 
 sub ProcessGroupEnd {
	my $self = shift;
	my $data = shift;

	my $unitId = $data->{"unitId"};

	my $unit = $self->_GetUnit($unitId);

	$unit->ProcessGroupEnd();

	my $notConsiderWarn = 1;
	$self->{"taskStatus"}->UpdateStatusFile( $unitId, $unit->Result($notConsiderWarn) );
}
 
#-------------------------------------------------------------------------------------------#
#  Private method
#-------------------------------------------------------------------------------------------#
 
 sub __InitUnits {
	my $self = shift;
 
	my @keys = $self->{"taskData"}->GetOrderedUnitKeys(1);
	my @allUnits = ();

	foreach my $key (@keys) {

		my $unit = $self->__GetUnitClass($key);
		push( @allUnits, $unit );
	}

	$self->{"units"}->SetUnits(\@allUnits);

}
# Return initialized "unit" object by unitId
sub __GetUnitClass {
	my $self   = shift;
	my $unitId = shift;
 
	my $jobId = $self->{"jobId"};
	
	my $title = UnitEnums->GetTitle($unitId);
	
	my $unit = UnitBase->new($unitId, $jobId, $title);
  
	return $unit;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

