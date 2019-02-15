
#-------------------------------------------------------------------------------------------#
# Description: Responsible for process of all groups, which are passed to this class
# Object of this class is created in asynchronous thread
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::PoolMerge::JobWorkerClass;
use base("Managers::AbstractQueue::AbstractQueue::JobWorkerClass");

#3th party library
use strict;
use warnings;
use Try::Tiny;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::ItemResult::Enums' => 'ResultEnums';
use aliased "Packages::ItemResult::ItemResult";
use aliased 'Managers::AbstractQueue::Enums' => "EnumsAbstrQ";
use aliased 'Managers::AsyncJobMngr::Enums'  => 'EnumsJobMngr';
use aliased 'Programs::PoolMerge::Enums';
use aliased 'Programs::PoolMerge::UnitEnums';
use aliased 'Packages::Exceptions::BaseException';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

sub RunTask {
	my $self = shift;
	
	$self->{"logger"}->debug("Thread start, pcb id:".${$self->{"pcbId"}});
 
#	use Time::HiRes qw (sleep);
#	sleep(1);
#
#	return 0;

	# Set property pcbid to undef, because this pcbid represent master job
	# But in this taime, we dont know master job
	${ $self->{"pcbId"} } = undef;

	eval {
		$self->__RunTask();

	};
	if ( my $e = $@ ) {

		my $baseE = BaseException->new("Pool merger thread (jobid: ".${$self->{"pcbId"}}.") was unexpectedly exited", $e);

		$self->_TaskResultEvent( ResultEnums->ItemResult_Fail, $baseE->Error() );
	}
	
	$self->{"logger"}->debug("Thread End, pcb id:".${$self->{"pcbId"}});

}

sub __RunTask {
	my $self = shift;

	my %workUnits = $self->_GetWorkUnits();
	my @keys      = $self->{"taskData"}->GetOrderedUnitKeys();
	my $mode      = $self->{"taskData"}->GetTaskMode();

	# 1) Init groups

	for ( my $i = 0 ; $i < scalar(@keys) ; $i++ ) {

		my $unitId   = $keys[$i];
		my $workUnit = $workUnits{$unitId};
		$self->__InitGroup($unitId);

	}

	# 2) Process groups

	for ( my $i = 0 ; $i < scalar(@keys) ; $i++ ) {
		
		$self->{"logger"}->debug("Thread group processing: $i/".scalar(@keys).", pcb id:".${$self->{"pcbId"}});

		my $taskStopped = 0;

		my $unitId = $keys[$i];

		# Event when group export start
		$self->_GroupTaskEvent( EnumsAbstrQ->EventType_GROUP_START, $unitId );

		# DON'T USE TRY/CATCH (TINY LIBRARY), IF SO, NORRIS WRITTER DOESN'T WORK
		# catch all unexpected exception in thread
		eval {

			# Process group
			$self->__ProcessGroup($unitId);

			if ( $self->__CheckStopThread($unitId) ) {
				$taskStopped = 1;
			}
		};
		if ( my $e = $@ ) {
 

			my $baseE = BaseException->new("Processing of group: ".UnitEnums->GetTitle($unitId)." was unexpectedly aborted", $e);

			$self->_GroupResultEvent( $unitId, ResultEnums->ItemResult_Fail, $baseE->Error() );
			last;

		}

		# check if thread should be stopped
		if ($taskStopped) {

			$taskStopped = 0;

			# sent message, thread is now continues..
			my $itemRes = ItemResult->new( EnumsAbstrQ->EventItemType_CONTINUE );
			$self->_SpecialEvent( $unitId, $itemRes );
			$i--;

		}
		else {

			# Event when group export end
			$self->_GroupTaskEvent( EnumsAbstrQ->EventType_GROUP_END, $unitId );

		}

	}

	#close job

	$self->_CloseJob(1);

}

sub __InitGroup {
	my $self   = shift;
	my $unitId = shift;

	my $inCAM = $self->{"inCAM"};

	# Get right export class and init
	my $workUnit = $self->{"workerUnits"}->{$unitId};

	$workUnit->Init( $inCAM, ${ $self->{"pcbId"} } );

	# Set handlers

	# catch item with results
	$workUnit->{"onItemResult"}->Add( sub { $self->_ItemResultEvent( $workUnit, $unitId, @_ ) } );

	# catch item with special importence
	# a) "stop" - task should be stopped, because of errors
	# b) "master" - pass master job id, which was choosen
	$workUnit->{"onStatusResult"}->Add( sub { $self->__ItemSpecialEvent( $workUnit, $unitId, @_ ) } );

}

sub __ProcessGroup {
	my $self   = shift;
	my $unitId = shift;

	my %workUnits = $self->_GetWorkUnits();

	# Get right export class and init
	my $workUnit = $workUnits{$unitId};

	# Final export group
	$workUnit->Run();
}

sub __ItemSpecialEvent {
	my $self       = shift;
	my $taskClass  = shift;
	my $unitId     = shift;
	my $itemResult = shift;

	# 1) Handle special events

	if ( $itemResult->ItemId() eq EnumsAbstrQ->EventItemType_STOP ) {

		$self->_StopThread();

	}
	elsif ( $itemResult->ItemId() eq Enums->EventItemType_MASTER ) {

		# save pcb id (important, because base class use it when export finish or for task stop/continue)
		${ $self->{"pcbId"} } = $itemResult->GetData();
		$self->_SpecialEvent( $unitId, $itemResult );

		unless ( $self->_OpenJob() ) {
			die "Unable to open master job " . ${ $self->{"pcbId"} } . "\n";
		}

	}

}

# Check if stop variable is set, if so
# Close job, sleep until stop variable is set to 1
sub __CheckStopThread {
	my $self   = shift;
	my $unitId = shift;

	my $threadStoped = 0;

	if ( ${ $self->{"stopThread"} } ) {

		$threadStoped = 1;

		# 1) Close job
		$self->_CloseJob(1);

		$self->__CloseChildJobs();

		# 2) Send message to gui, task is stoped

		$self->_SpecialEvent( $unitId, ItemResult->new( EnumsAbstrQ->EventItemType_STOP ) );

		# 2) Sleep until stop var is set to 0
		while (1) {

			sleep(1);
			if ( ${ $self->{"stopThread"} } == 0 ) {
				last;
			}
		}

		# 3) Open job again
		my $userName = undef;
		if ( CamJob->IsJobOpen( $self->{"inCAM"}, ${ $self->{"pcbId"} }, 1, \$userName ) ) {

			# stop task again and send error, mother is not able to open
			${ $self->{"stopThread"} } = 1;

			my $itemErr = ItemResult->new( EnumsAbstrQ->EventItemType_CONTINUEERR );
			$itemErr->SetData( "type=masterOpen;byUser=" . $userName );

			$self->_SpecialEvent( $unitId, $itemErr );
			$self->__CheckStopThread($unitId);

		}
		else {
			unless ( $self->_OpenJob() ) {
				die "Unable to open master job " . ${ $self->{"pcbId"} } . "\n";
			}
		}
		
		# 4) Reset counter of progress in current "work unit"
		my $workUnit = $self->{"workerUnits"}->{$unitId};
		$workUnit->ResetProgressCounter();
		
	}

	return $threadStoped;
}

sub __CloseChildJobs {
	my $self = shift;

	# 1) close child jobs if are open and master is already known
	if ( defined ${ $self->{"pcbId"} } ) {

		my $masterJob = ${ $self->{"pcbId"} };
  
		my @jobNames = $self->{"taskData"}->GetGroupData()->GetJobNames();
		@jobNames = grep { $_ !~ /^$masterJob$/i } @jobNames;

		foreach my $job (@jobNames) {

			CamJob->CloseJob($self->{"inCAM"}, $job);
		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = Programs::Exporter::PoolMerge->new();

	#$app->Test();

	#$app->MainLoop;

}

1;

