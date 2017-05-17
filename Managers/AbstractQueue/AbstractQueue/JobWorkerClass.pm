
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
use aliased 'CamHelpers::CamStep';
use aliased 'Packages::ItemResult::Enums' => 'ResultEnums';
use aliased 'Managers::AbstractQueue::Enums';
 
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless($self);

	$self->{"pcbId"}       = undef;
	$self->{"taskId"}      = undef;
	$self->{"inCAM"}       = undef;
	$self->{"unitBuilder"} = undef;    # classes for task each group

	my %workerUnits = ();
	$self->{"workerUnits"} = \%workerUnits;
	$self->{"taskData"}    = undef;           # prepared task data
	
	

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"pcbId"}       = shift;
	$self->{"taskId"}      = shift;
	$self->{"unitBuilder"} = shift;           # builder generate JobWorker units with data, based on unit string data
	$self->{"inCAM"}       = shift;
	my $threadOrder = shift;

	# Supress all toolkit exception/error windows
	$self->{"inCAM"}->SupressToolkitException(1);
	$self->{"logger"}->debug( "Thread order $threadOrder SUPRESS worker, pcbid: " . ${ $self->{"pcbId"} } . "" );
	
	# only for testing purpose, try if server is ready for sure
	unless($self->{"inCAM"}->ServerReady()){
		
		$self->{"logger"}->error("Thread order $threadOrder, server is not ready, pcbid: " . ${ $self->{"pcbId"} } . "");	
		die "Error when conenction to inCAM server, send log to spr";
	}
	

	# Switch of displa actions in InCAM editor

	$self->{"inCAM"}->COM("disp_off");
	$self->{"logger"}->debug( "Thread order $threadOrder DISPOFF worker, pcbid: " . ${ $self->{"pcbId"} } . "" );
	
	my %units = $self->{"unitBuilder"}->GetUnits();
	$self->{"workerUnits"} = \%units;

	$self->{"taskData"} = $self->{"unitBuilder"}->GetTaskData();

	$self->{"logger"}->debug( "Thread order BUILDER get task data, pcbid: " . ${ $self->{"pcbId"} } . "" );

}

sub _GetWorkUnits {
	my $self = shift;

	return %{ $self->{"workerUnits"} };
}

# Method open and checkou job
sub _OpenJob {
	my $self = shift;
	my $step = shift;

	#return 0;
	my $inCAM = $self->{"inCAM"};

	unless ( ${ $self->{"pcbId"} } ) {
		return 0;
	}

	if ( CamJob->IsJobOpen( $self->{"inCAM"}, ${ $self->{"pcbId"} } ) ) {
		return 0;
	}

	my $result = 1;

	# 1) open job

	$inCAM->HandleException(1);

	CamHelper->OpenJob( $self->{"inCAM"}, ${ $self->{"pcbId"} } );

	$inCAM->HandleException(0);

	my $err = $inCAM->GetExceptionError();

	if ($err) {
		$result = 0;
		$self->_TaskResultEvent( ResultEnums->ItemResult_Fail, $err );
	}

	# 2) Additional check, maximum number of terminal is exceded.
	# if set step fail, it means max number exceeded

	$inCAM->HandleException(1);

	unless ($result) {
		return 0;
	}

	# choose step if not defined
	if ( !defined $step ) {

		my @names = CamStep->GetAllStepNames( $inCAM, ${ $self->{"pcbId"} } );
		$step = $names[0];
	}

	CamHelper->SetStep( $self->{"inCAM"}, $step );

	$inCAM->HandleException(0);

	my $err3 = $inCAM->GetExceptionError();

	if ($err3) {
		$result = 0;
		$self->_TaskResultEvent( ResultEnums->ItemResult_Fail, "Maximum licence of InCAM is exceeded" );
	}

	unless ($result) {
		return 0;
	}

	# 3) check out job

	$inCAM->HandleException(1);

	CamJob->CheckOutJob( $self->{"inCAM"}, ${ $self->{"pcbId"} } );

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

	#return 0;
	my $inCAM = $self->{"inCAM"};

	unless ( ${ $self->{"pcbId"} } ) {
		return 0;
	}

	unless ( CamJob->IsJobOpen( $self->{"inCAM"}, ${ $self->{"pcbId"} } ) ) {
		return 0;
	}

	# START HANDLE EXCEPTION IN INCAM
	$inCAM->HandleException(1);

	if ($save) {
		CamJob->SaveJob( $self->{"inCAM"}, ${ $self->{"pcbId"} } );
	}

	CamJob->CheckInJob( $self->{"inCAM"}, ${ $self->{"pcbId"} } );
	CamJob->CloseJob( $self->{"inCAM"}, ${ $self->{"pcbId"} } );

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

	#print " ==========Job WorkerClass Progress, UnitId:" . $unitId . " - " . $taskClass->GetProgressValue() . "\n";

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


	$self->{"logger"}->debug("Thread group, type: $type.". "Pcb id:".${$self->{"pcbId"}});

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

