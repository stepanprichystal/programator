
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

	my %unitsData = $self->{"data"}->GetAllUnitData();
	my @keys      = $self->{"data"}->GetOrderedUnitKeys();
	my $mode      = $self->{"data"}->GetTaskMode();

	# sort keys by nhash value "__UNITORDER__"

	foreach my $unitId (@keys) {

		#tell group export start

		my $taskData = $unitsData{$unitId};

		# Event when group export start
		$self->_GroupTaskEvent( EnumsAbstrQ->EventType_GROUP_START, $unitId );

		# DON'T USE TRY/CATCH (TINY LIBRARY), IF SO, NORRIS WRITTER DOESN'T WORK
		# catch all unexpected exception in thread
		eval {

			# Process group
			$self->__ProcessGroup( $unitId, $taskData );
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
		if ( $self->_CheckStopThread() ) {

			# sent message, thread is now continues..
			my $itemRes = ItemResult->new( Enums->EventItemType_CONTINUE );
			$self->_ItemSpecialEvent( $unitId, $itemRes );

		}

		# Event when group export end
		$self->_GroupTaskEvent( EnumsAbstrQ->EventType_GROUP_END, $unitId );
	}

	#close job

	if ( $mode eq EnumsJobMngr->TaskMode_ASYNC ) {

		$self->_CloseJob();
	}
}

sub __ProcessGroup {
	my $self     = shift;
	my $unitId   = shift;
	my $taskData = shift;    # export data for specific group

	my $inCAM = $self->{"inCAM"};

	# Get right export class and init
	my $taskClass = $self->{"taskClass"}->{$unitId};
	$taskClass->Init( $inCAM, $self->{"pcbId"}, $taskData );

	# Set handlers

	# catch item with results
	$taskClass->{"onItemResult"}->Add( sub { $self->_ItemResultEvent( $taskClass, $unitId, @_ ) } );

	# catch item with special importence
	# a) "stop" - task should be stopped, because of errors
	# b) "master" - pass master job id, which was choosen
	$taskClass->{"onStatusResult"}->Add( sub { $self->__ItemSpecialEvent( $taskClass, $unitId, @_ ) } );

	# Final export group
	$taskClass->Run();

}

sub __ItemSpecialEvent {
	my $self       = shift;
	my $taskClass  = shift;
	my $unitId     = shift;
	my $itemResult = shift;

	# 1) Handle special events

	if ( $itemResult->ItemId() eq Enums->EventItemType_STOP ) {

		$self->_StopThread();

	}
	elsif ( $itemResult->ItemId() eq Enums->EventItemType_MASTER ) {

		# save pcb id (important, because base class use it when export finish or for task stop/continue)
		$self->{"pcbId"} = $itemResult->{"masterJobId"};
	}

	# 2) send specia event to abstract queue form

	$self->_SpecialEvent( $unitId, $itemResult );

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

