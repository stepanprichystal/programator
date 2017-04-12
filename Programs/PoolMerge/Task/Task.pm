
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

#local library
use aliased 'Programs::PoolMerge::UnitEnums';

use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::PoolMerge::Groups::MergeGroup::MergeUnit';
use aliased 'Programs::PoolMerge::Groups::RoutGroup::RoutUnit';
use aliased 'Programs::PoolMerge::Groups::OutputGroup::OutputUnit';

use aliased 'Connectors::HeliosConnector::HegMethods';
 
 
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
	
	$self->__InitUnits();

 
	return $self;
}

# ===================================================================
# Public method
# ===================================================================
 

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

	my $res = $self->{"toExportResultMngr"}->Succes();

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
	if ( $self->Result() eq EnumsGeneral->ResultType_FAIL ) {

		my $errorStr = "Can't sent \"to toExport\",  ";

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

	my @notExportUnits = ();
	if ( !$self->{"taskStatus"}->IsTaskOk( \@notExportUnits ) ) {

		my @notExportUnits = map { UnitEnums->GetTitle($_) } @notExportUnits;
		my $str = join( ", ", @notExportUnits );

		my $errorStr = "Can't sent \"to toExport\", because some groups haven't been processed succesfully. \n";
		$errorStr .= "Groups that need to be processed: <b> $str </b>\n";

		$self->{"canSentToExport"} = 0;

		my $item = $sentToExportMngr->GetNewItem( "Export status", EnumsGeneral->ResultType_FAIL );

		$item->AddError($errorStr);
		$sentToExportMngr->AddItem($item);
	}

}

sub SentToExport {
	my $self = shift;

	# set state HOTOVO-zadat

	eval {
		my $orderRef = HegMethods->GetPcbOrderNumber( $self->{"jobId"} );
		my $orderNum = $self->{"jobId"} . "-" . $orderRef;
		
		my $succ     = HegMethods->UpdatePcbOrderState( $orderNum, "HOTOVO-zadat");
		
	 
		$self->{"taskStatus"}->DeleteStatusFile();
		$self->{"sentToExport"} = 1;
	};

	if ( my $e = $@ ) {

		 # set status hotovo-yadat fail
		 my $sentToExportMngr = $self->{"toExportResultMngr"};
		 my $item = $sentToExportMngr->GetNewItem( "Set state HOTOVO-zadat", EnumsGeneral->ResultType_FAIL );

		$item->AddError("Set state HOTOVO-zadat failed, try it again. Detail: $e\n");
		$sentToExportMngr->AddItem($item);

	}

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

	my $unit;
	my $jobId = $self->{"jobId"};
	
	my $title = UnitEnums->GetTitle($unitId);

	if ( $unitId eq UnitEnums->UnitId_MERGE ) {

		$unit = MergeUnit->new($unitId, $jobId, $title);

	}
	elsif ( $unitId eq UnitEnums->UnitId_ROUT ) {

		$unit = RoutUnit->new($unitId, $jobId, $title);

	}elsif ( $unitId eq UnitEnums->UnitId_OUTPUT ) {

		$unit = OutputUnit->new($unitId, $jobId, $title);

	}
	
 

	return $unit;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

