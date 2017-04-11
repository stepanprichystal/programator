
#-------------------------------------------------------------------------------------------#
# Description: Responsible for run task of all groups, which are passed to this class
# Object of this class is created in asynchronous thread
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::AbstractQueue::JobWorkerClass;
use base("Managers::AsyncJobMngr::WorkerClass");

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
use aliased 'Managers::AbstractQueue::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless($self);

	$self->{"pcbId"}     = undef;
	$self->{"taskId"}    = undef;
	$self->{"inCAM"}     = undef;
	$self->{"taskClass"} = undef;    # classes for task each group
	$self->{"data"}      = undef;    # task data

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"pcbId"}     = shift;
	$self->{"taskId"}    = shift;
	$self->{"inCAM"}     = shift;
	$self->{"taskClass"} = shift;    # classes for task each group
	$self->{"data"}      = shift;    # task data

	# Supress all toolkit exception/error windows
	$self->{"inCAM"}->SupressToolkitException(1);

	# Switch of displa actions in InCAM editor
	$self->{"inCAM"}->COM("disp_off");
}

# Method open and checkou job
sub _OpenJob {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};

	my $result = 1;

	# 1) open job

	$inCAM->HandleException(1);

	CamHelper->OpenJob( $self->{"inCAM"}, $self->{"pcbId"} );

	$inCAM->HandleException(0);

	my $err = $inCAM->GetExceptionError();

	if ($err) {
		$result = 0;
		$self->_TaskResultEvent( ResultEnums->ItemResult_Fail, $err );
	}

	# 2) Additional check, maximum number of terminal is exceded.
	# if set step fail, it means max number exceeded

	$inCAM->HandleException(1);

	CamHelper->SetStep( $self->{"inCAM"}, "panel" );

	$inCAM->HandleException(0);

	my $err3 = $inCAM->GetExceptionError();

	if ($err3) {
		$result = 0;
		$self->_TaskResultEvent( ResultEnums->ItemResult_Fail, "Maximum licence of InCAM is exceeded" );
	}

	# 3) check out job

	$inCAM->HandleException(1);

	CamJob->CheckOutJob( $self->{"inCAM"}, $self->{"pcbId"} );

	$inCAM->HandleException(0);

	my $err2 = $inCAM->GetExceptionError();

	if ($err2) {
		$result = 0;
		$self->_TaskResultEvent( ResultEnums->ItemResult_Fail, $err );
	}

	unless ($result) {

		return 0;
	}
	else {
		return 1;
	}
}

sub _CloseJob {
	my $self = shift;
	my $save = shift;
	
	unless($self->{"pcbId"}){
		return 0;
	}

	my $inCAM = $self->{"inCAM"};

	# START HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(1);

	if ($save) {
		CamJob->SaveJob( $self->{"inCAM"}, $self->{"pcbId"} );
	}

	CamJob->CheckInJob( $self->{"inCAM"}, $self->{"pcbId"} );
	CamJob->CloseJob( $self->{"inCAM"}, $self->{"pcbId"} );

	# STOP HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(0);

	my $err = $inCAM->GetExceptionError();

	if ($err) {

		$self->_TaskResultEvent( ResultEnums->ItemResult_Fail, $err );
		return 0;
	}
	else {
		return 1;
	}
}

# Check if stop variable is set, if so
# Close job, sleep until stop variable is set to 1
sub _CheckStopThread {
	my $self = shift;

	my $threadStoped = 0;

	if ( ${ $self->{"stopThread"} } ) {

		$threadStoped = 1;

		# 1) Close job
		$self->_CloseJob(1);

		# 2) Sleep until stop var is set to 0
		while (1) {

			sleep(1);
			if ( ${ $self->{"stopThread"} } == 0 ) {
				last;
			}
		}

		# 3) Open job again
		$self->_OpenJob();
	}

	return $threadStoped;
}

# Set stop variable to 1
sub _StopThread {
	my $self = shift;

	${ $self->{"stopThread"} } = 1;
}

# ====================================================================================
# Function, which sent messages to main thread about state of tasking
# ====================================================================================

sub _ItemResultEvent {
	my $self       = shift;
	my $taskClass  = shift;
	my $unitId     = shift;
	my $itemResult = shift;

	# Item result event

	my %data1 = ();
	$data1{"unitId"}   = $unitId;
	$data1{"itemId"}   = $itemResult->ItemId();
	$data1{"result"}   = $itemResult->Result();
	$data1{"errors"}   = $itemResult->GetErrorStr( Enums->ItemResult_DELIMITER );
	$data1{"warnings"} = $itemResult->GetWarningStr( Enums->ItemResult_DELIMITER );
	$data1{"group"}    = $itemResult->GetGroup();

	$self->_SendMessageEvt( Enums->EventType_ITEM_RESULT, \%data1 );

	# Progress value event

	my %data2 = ();
	$data2{"unitId"} = $unitId;
	$data2{"value"}  = $taskClass->GetProgressValue();

	print " ==========Job WorkerClass Progress, UnitId:" . $unitId . " - " . $taskClass->GetProgressValue() . "\n";

	$self->_SendProgressEvt( \%data2 );

}

sub _GroupResultEvent {
	my $self   = shift;
	my $unitId = shift;
	my $result = shift;
	my $error  = shift;

	# Item result event

	my %data1 = ();
	$data1{"unitId"} = $unitId;
	$data1{"result"} = $result;
	$data1{"errors"} = $error;

	$self->_SendMessageEvt( Enums->EventType_GROUP_RESULT, \%data1 );

}

sub _TaskResultEvent {
	my $self   = shift;
	my $result = shift;
	my $error  = shift;

	# Item result event

	my %data1 = ();
	$data1{"result"} = $result;
	$data1{"errors"} = $error;

	$self->_SendMessageEvt( Enums->EventType_TASK_RESULT, \%data1 );

}

sub _GroupTaskEvent {
	my $self   = shift;
	my $type   = shift;    #GROUP_TASK_<START/END>
	my $unitId = shift;

	my %data = ();
	$data{"unitId"} = $unitId;

	$self->_SendMessageEvt( $type, \%data );
}

# Take "data" (scalar variable) from item result and send
sub _SpecialEvent {
	my $self       = shift;
	my $unitId     = shift;
	my $itemResult = shift;
 

	my %data1 = ();
	$data1{"unitId"} = $unitId;
	$data1{"itemId"} = $itemResult->ItemId();
	$data1{"data"}   = $itemResult->GetData();

	$self->_SendMessageEvt( Enums->EventType_SPECIAL, \%data1 );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = Programs::AbstractQueue::AbstractQueueUtility->new();

	#$app->Test();

	#$app->MainLoop;

}

1;

