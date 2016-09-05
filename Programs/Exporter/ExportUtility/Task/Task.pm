
#-------------------------------------------------------------------------------------------#
# Description: Prostrednik mezi formularem jednotky a buildere,
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Task::Task;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::UnitEnums';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifUnit';
use aliased 'Enums::EnumsGeneral';

#use aliased 'Programs::Exporter::ExportUtility::Groups::NCExport::NCUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::NCUnit';
use aliased 'Programs::Exporter::ExportUtility::Groups::NC2Unit';
use aliased 'Programs::Exporter::ExportUtility::Groups::NC3Unit';
use aliased 'Programs::Exporter::ExportUtility::Groups::NC4Unit';
use aliased 'Programs::Exporter::ExportUtility::Groups::NC5Unit';
use aliased 'Programs::Exporter::ExportUtility::Unit::Units';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::ExportStatus::ExportStatus';
use aliased 'Programs::Exporter::ExportUtility::ExportResultMngr';


#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	$self->{"taskId"} = shift;
	$self->{"jobId"}  = shift;

	$self->{"exportData"} = shift;

	$self->{"taskResultMngr"} = ExportResultMngr->new();

	$self->{"units"}        = Units->new();
	$self->{"exportStatus"} = ExportStatus->new( $self->{"jobId"} );
	
	$self->{"aborted"} = 0; # Tell if task was aborted bz user

	#$self->{"onCheckEvent"} = Event->new();

	$self->__InitUnit();
	$self->{"exportStatus"}->CreateStatusFile();

	return $self;    # Return the reference to the hash.
}

sub GetTaskId {
	my $self = shift;

	return $self->{"taskId"};
}

sub GetJobId {
	my $self = shift;

	return $self->{"jobId"};
}

# Init groups by exported data
sub __InitUnit {
	my $self = shift;

	my @allUnits = ();

	my $exportedData = $self->{"exportData"};

	my @keys = $exportedData->GetOrderedUnitKeys(1);

	my %unitsData = $exportedData->GetAllUnitData();

	# sort keys by nhash value "__UNITORDER__"
	#my @keys = sort { $unitsData{$b}->{"data"}->{"__UNITORDER__"} <=> $unitsData{$a}->{"data"}->{"__UNITORDER__"} } keys %unitsData;

	foreach my $key (@keys) {

		my $unit = $self->__GetUnitClass($key);

		push( @allUnits, $unit );

	}

	$self->{"units"}->Init( \@allUnits );

}

sub ProcessItemResult {
	my $self = shift;
	my $data = shift;

	my $unitId = $data->{"unitId"};

	my $unit = $self->__GetUnit($unitId);

	my $itemId       = $data->{"itemId"};
	my $itemResult   = $data->{"result"};
	my $itemErrors   = $data->{"errors"};
	my $itemWarnings = $data->{"warnings"};
	my $itemGroup    = $data->{"group"};

	unless ($unit) {

		print 1;

	}

	$unit->ProcessItemResult( $itemId, $itemResult, $itemGroup, $itemErrors, $itemWarnings );

	#$unit->RefreshGUI();
}

sub ProcessGroupResult {
	my $self = shift;
	my $data = shift;

	my $unitId = $data->{"unitId"};

	my $unit = $self->__GetUnit($unitId);

	my $groupResult   = $data->{"result"};
	my $groupErrors   = $data->{"errors"};
	my $groupWarnings = $data->{"warnings"};

	$unit->ProcessGroupResult( $groupResult, $groupErrors, $groupWarnings );

	#$unit->RefreshGUI();
}

sub ProcessGroupStart {
	my $self = shift;
	my $data = shift;

	my $unitId = $data->{"unitId"};

	my $unit = $self->__GetUnit($unitId);

	$unit->ProcessGroupStart();

	# call process group end
}

sub ProcessGroupEnd {
	my $self = shift;
	my $data = shift;

	my $unitId = $data->{"unitId"};

	my $unit = $self->__GetUnit($unitId);
 
	$unit->ProcessGroupEnd( );

	# call process group end
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
	my $self = shift;
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

	if (
		 $unitsResult          eq EnumsGeneral->ResultType_FAIL
		 || $taskResult        eq EnumsGeneral->ResultType_FAIL 
		 || $taskAbortedResult eq EnumsGeneral->ResultType_FAIL
	  )
	{

		$totalResult = EnumsGeneral->ResultType_FAIL;
	}

	return $totalResult;
}

sub GetAllUnits {
	my $self = shift;
	return @{ $self->{"units"}->{"units"} };
}

sub GetExportData {
	my $self = shift;
	return $self->{"exportData"};
}

sub __GetUnit {
	my $self   = shift;
	my $unitId = shift;

	return $self->{"units"}->GetUnitById($unitId);

}

sub __GetUnitClass {
	my $self   = shift;
	my $unitId = shift;

	my $unit;

	if ( $unitId eq UnitEnums->UnitId_NIF ) {

		$unit = NifUnit->new();

	}
	elsif ( $unitId eq UnitEnums->UnitId_NC ) {

		#$unit = NifUnit->new();
		$unit = NCUnit->new();

	}
	elsif ( $unitId eq UnitEnums->UnitId_NC2 ) {

		#$unit = NifUnit->new();
		$unit = NC2Unit->new();

	}
	elsif ( $unitId eq UnitEnums->UnitId_NC3 ) {

		#$unit = NifUnit->new();
		$unit = NC3Unit->new();

	}
	elsif ( $unitId eq UnitEnums->UnitId_NC4 ) {

		#$unit = NifUnit->new();
		$unit = NC4Unit->new();

	}
	elsif ( $unitId eq UnitEnums->UnitId_NC5 ) {

		#$unit = NifUnit->new();
		$unit = NC5Unit->new();

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

