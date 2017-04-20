
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

	eval {
		$self->__RunTask();

	};
	if ( my $e = $@ ) {

		my $errStr = "";

		# get string error from exception
		if ( $e->can("Error") ) {

			$errStr .= $e->Error();
		}
		else {
			$errStr .= $e;
		}

		$self->_TaskResultEvent( ResultEnums->ItemResult_Fail, $errStr );
	}

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

		my $taskStopped = 0;

		my $unitId = $keys[$i];

		# Event when group export start
		$self->_GroupTaskEvent( EnumsAbstrQ->EventType_GROUP_START, $unitId );

		# DON'T USE TRY/CATCH (TINY LIBRARY), IF SO, NORRIS WRITTER DOESN'T WORK
		# catch all unexpected exception in thread
		eval {

			# Process group
			$self->__ProcessGroup($unitId);

			if ( $self->_CheckStopThread() ) {
				$taskStopped = 1;
			}
		};
		if ( my $e = $@ ) {

			my $errStr = "";

			# get string error from exception
			if ( $e->can("Error") ) {

				$errStr .= $e->Error();

			}
			else {

				$errStr .= $e;
			}

			$self->_GroupResultEvent( $unitId, ResultEnums->ItemResult_Fail, $errStr );

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

	if ( $mode eq EnumsJobMngr->TaskMode_ASYNC ) {

		$self->_CloseJob();
	}
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
		$self->_SpecialEvent( $unitId, $itemResult );

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

