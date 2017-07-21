
#-------------------------------------------------------------------------------------------#
# Description: Core of Abstract queue program. Manage whole process of tasking.
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Managers::AbstractQueue::AbstractQueue::AbstractQueue;

#3th party library
use threads;
use threads::shared;
use Wx;
use strict;
use warnings;
use File::Copy;
use Sys::Hostname;
use Log::Log4perl qw(get_logger :levels);

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';

#use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';
use aliased 'Managers::MessageMngr::MessageMngr';

use aliased 'Managers::AbstractQueue::Task::Task';
use aliased 'Managers::AbstractQueue::AbstractQueue::Forms::AbstractQueueForm';

use aliased 'Managers::AsyncJobMngr::Enums' => 'EnumsJobMngr';
use aliased 'Managers::AbstractQueue::AbstractQueue::JobWorkerClass';
use aliased 'Managers::AbstractQueue::Enums';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::Events::Event';
use aliased 'Packages::Other::AppConf';
use aliased 'Managers::AsyncJobMngr::Helper' => "AsyncJobHelber";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless($self);

	# Main application form
	$self->{"form"} = shift;

	# Number of second, job will be auto removed from queue,
	# or undef - not auto remove
	$self->{"autoRemove"} = shift;

	$self->{"version"} = $self->__GetVersion();

	$self->{"form"}->Init();
	$self->{"form"}->AddVersion( $self->{"version"} );

	$self->{"inCAM"} = undef;

	# Keep all references of used groups/units in form
	my @tasks = ();
	$self->{"tasks"} = \@tasks;

	# list of jobs, which are waiting on auto remove
	my @removeJobs = ();
	$self->{"removeJobs"} = \@removeJobs;

	# list of all timers
	my @timers = ();
	$self->{"timers"} = \@timers;

	#set base class handlers

	$self->__SetHandlersBase();

	# events

	$self->{'onSetNewTask'} = Event->new();
	
	get_logger("abstractQueue")->info( "App was launched \n" );

	return $self;
}

# ========================================================================================== #
#  PUBLIC HELPER METHOD
# ========================================================================================== #
sub Run {
	my $self = shift;

	$self->__RunTimersBase();

	if ( AppConf->GetValue("hideAfterStart") ) {

		$self->{"form"}->{"mainFrm"}->Hide();

	}
	else {
		$self->{"form"}->{"mainFrm"}->Show(1);
	}

	$self->{"form"}->MainLoop();

}

# Stop all timers
sub StopAllTimers {
	my $self = shift;

	foreach my $timer ( @{ $self->{"timers"} } ) {

		$timer->Stop();
	}
}

# ========================================================================================== #
#  BASE CLASS HANDLERS
# ========================================================================================== #

# First is called this function in base class, then is called handler in inherit class
sub __OnJobStateChangedBase {
	my $self            = shift;
	my $taskId          = shift;
	my $taskState       = shift;
	my $taskStateDetail = shift;

	my $task     = $self->_GetTaskById($taskId);
	my $taskData = $task->GetTaskData();

	my $status = "";

	if ( $taskState eq EnumsJobMngr->JobState_WAITINGQUEUE ) {

		$status = "Waiting in queue.";

	}
	elsif ( $taskState eq EnumsJobMngr->JobState_WAITINGPORT ) {

		$status = "Waiting on InCAM port.";
		$self->{"form"}->ActivateForm( 1, $taskData->GetFormPosition() );

	}
	elsif ( $taskState eq EnumsJobMngr->JobState_RUNNING ) {

		$status = "Running...";

	}
	elsif ( $taskState eq EnumsJobMngr->JobState_ABORTING ) {

		$status = "Aborting job...";

	}
	elsif ( $taskState eq EnumsJobMngr->JobState_DONE ) {

		# Refresh GUI - job queue

		#	 ExitType_SUCCES => 'Succes',
		#	ExitType_FAILED => 'Failed',
		#	ExitType_FORCE  => 'Force',

		my $aborted = 0;

		if ( $taskStateDetail eq EnumsJobMngr->ExitType_FORCE ) {
			$aborted = 1;

			$status = "Job task aborted by user.";

		}
		elsif ( $taskStateDetail eq EnumsJobMngr->ExitType_FORCERESTART ) {

			$self->__RestartTask($task);

			return;

		}
		else {

			$status = "Job task finished.";
		}

		$task->ProcessTaskDone($aborted);
		$self->{"form"}->SetJobItemResult($task);
		
		get_logger("abstractQueue")->info( "Job ".$task->GetJobId()." is done.\n" );


	}

	$self->{"form"}->SetJobItemStatus( $taskId, $status );

}

# Start when some items wass processed and contain value of progress
# First is called this function in base class, then is called handler in inherit class
sub __OnJobProgressEvtHandlerBase {
	my $self   = shift;
	my $taskId = shift;
	my $data   = shift;

	my $task = $self->_GetTaskById($taskId);

	$task->ProcessProgress($data);

	$self->{"form"}->SetJobItemProgress( $taskId, $task->GetProgress() );

	#my $task = $self->_GetTaskById($taskId);

	#$self->{"gauge"}->SetValue($value);

	#print "AbstractQueue utility:  job progress, job id: " . $jobGUID . " - value: " . $value . "\n";

}

# First is called this function in base class, then is called handler in inherit class
sub __OnJobMessageEvtHandlerBase {
	my $self     = shift;
	my $taskId   = shift;
	my $messType = shift;
	my $data     = shift;

	my $task = $self->_GetTaskById($taskId);

	#print "AbstractQueue utility::  task id: " . $taskId . " - messType: " . $messType. "\n";

	# CATCH GROUP ITEM MESSAGE

	if ( $messType eq Enums->EventType_ITEM_RESULT ) {

		# Update data model and refresh group

		$task->ProcessItemResult($data);

		# Refresh GUI - group table

		$self->{"form"}->RefreshGroupTable($task);

		# Refresh GUI - job queue

		$self->{"form"}->SetJobQueueErrorCnt($task);
		$self->{"form"}->SetJobQueueWarningCnt($task);

	}

	# CATCH GROUP MESSAGE

	if ( $messType eq Enums->EventType_GROUP_RESULT ) {

		# Update data model

		$task->ProcessGroupResult($data);

		# Refresh GUI - group table

		$self->{"form"}->RefreshGroupTable($task);

		# Refresh GUI - job queue
		$self->{"form"}->SetJobQueueErrorCnt($task);
		$self->{"form"}->SetJobQueueWarningCnt($task);

	}
	elsif ( $messType eq Enums->EventType_GROUP_START ) {

		# Update group form status

		$task->ProcessGroupStart($data);

	}
	elsif ( $messType eq Enums->EventType_GROUP_END ) {

		# Update group form status
		$task->ProcessGroupEnd($data);

	}

	# CATCH TASK MESSAGE

	if ( $messType eq Enums->EventType_TASK_RESULT ) {

		# Update data model
		$task->ProcessTaskResult($data);

		# Refresh GUI - job queue
		$self->{"form"}->SetJobQueueErrorCnt($task);
		$self->{"form"}->SetJobQueueWarningCnt($task);

	}

	# CATCH SPECIAL ITEM MESSAGE

	if ( $messType eq Enums->EventType_SPECIAL ) {

		if ( $data->{"itemId"} eq Enums->EventItemType_STOP ) {

			# 1) set status "paused", to actually processed unit
			$task->ProcessTaskStop($data);

		}
		elsif ( $data->{"itemId"} eq Enums->EventItemType_CONTINUE ) {

			# 1) remove all results from result managers (items, group, task managers)

			$task->ProcessTaskContinue($data);

			# Refresh GUI - group table

			$self->{"form"}->RefreshGroupTable($task);

		}

	}
}

# First is called this function in base class, then is called handler in inherit class
sub __OnRemoveJobClick {
	my $self   = shift;
	my $taskId = shift;

	my $task = $self->_GetTaskById($taskId);

	#if mode was synchrounous, we have to quit server script

	my $taskData = $task->GetTaskData();

	if ( $taskData->GetTaskMode() eq EnumsJobMngr->TaskMode_SYNC ) {

		my $port = $taskData->GetPort();

		my $inCAM = InCAM->new( "port" => $port );

		#$inCAM->ServerReady();

		my $pidServer = $inCAM->ServerReady();

		#if ok, make space for new client (child process)
		if ($pidServer) {

			$inCAM->CloseServer();
		}

		print STDERR "Close server, $port\n\n";

		$self->{"form"}->_DestroyExternalServer($port);

		# hide abstractQueue
		$self->{"form"}->ActivateForm(0);
	}

}

# First is called this function in base class, then is called handler in inherit class
sub __OnCloseAbstractQueueBase {
	my $self = shift;

	# All jobs should be DONE in this time

	# find if some jobs (in synchronous mode) are in queue
	# if so remove them in order do incam editor free
	foreach my $task ( @{ $self->{"tasks"} } ) {

		my $taskData = $task->GetTaskData();

		if ( $taskData->GetTaskMode() eq EnumsJobMngr->TaskMode_SYNC ) {

			$self->__OnRemoveJobClick( $task->GetTaskId() );
		}
	}

}

#update gui

# Helper  function, which run every 5 second
# Can be use e.g for refresh GUI etc..
sub __Timer5second {
	my $self = shift;
	$self->{"form"}->RefreshSettings();

	# if size of window was changed, do refresh
	# This is necessary , because there is problem with shrink of job queue and with group table

	my $mainSz = $self->{"form"}->{"mainFrm"}->GetSizer();
	my $newS   = $mainSz->GetSize();
	if ( defined $self->{"oldSize"} ) {

		my $mainSz = $self->{"form"}->{"mainFrm"}->GetSizer();
		my $newS   = $mainSz->GetSize();

		if ( $newS->GetWidth() < $self->{"oldSize"}->GetWidth() ) {
			$self->{"form"}->{"mainFrm"}->Refresh();

			#			foreach my $k (keys %{$self->{"form"}->{"notebook"}->{"pages"}}){
			#
			#				$self->{"form"}->{"notebook"}->{"pages"}->{$k}->GetPageContent()->Layout();
			#				$self->{"form"}->{"notebook"}->{"pages"}->{$k}->GetPageContent()->FitInside();
			#			}
		}
	}

	$self->{"oldSize"} = $newS;

}

sub __TimerCheckVersion {
	my $self = shift;

	#print STDERR "\nukonceni z timer check version\n";
	#die "check version";

	my $verison = $self->__GetVersion();

	if ( $verison == 0 || $self->{"version"} == 0 ) {
		return 0;
	}

	if ( $self->{"version"} < $verison ) {
		
		get_logger("abstractQueue")->info( "New version on server. Old = ".$self->{"version"}.", New = ".$verison."\n" );

		$self->{"timerVersion"}->Stop();
 
		# If runining on server, close directly
		if ( AsyncJobHelber->ServerVersion()) {

			$self->{"form"}->__OnClose(1);
		
		}else {
			
			# First ask user for close

			my $messMngr = $self->{"form"}->{"messageMngr"};

			my @mess1 = (
						  "Na serveru je nová verze programu \"" . AppConf->GetValue("appName") . "\". Jakmile to bude možné, ukonèi program.",
						  "Chceš program ukonèit nyní?"
			);
			my @btn = ( "Ano", "Ukonèím pozdìni" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess1, \@btn );

			# close abstractQueue
			if ( $messMngr->Result() == 0 ) {
				
				$self->{"form"}->__OnClose();
			}
		}

		# once to 5 minute
		$self->{"timerVersion"}->Start( 60000 * 5 );
		 
	}

}

# Automatically remove jobs if was succes
sub __AutoRemoveJobsHandler {
	my $self = shift;

	unless ( $self->{"autoRemove"} ) {
		return 0;
	}

	# 1) control list of jsob, which should be removed from queue
	for ( my $i = scalar( @{ $self->{"removeJobs"} } ) - 1 ; $i >= 0 ; $i-- ) {

		my $taskId = $self->{"removeJobs"}->[$i]->{"taskId"};
		my $time   = $self->{"removeJobs"}->[$i]->{"exportFinis"};

		my $jobItem = $self->{"form"}->{"jobQueue"}->GetItem($taskId);

		if ( defined $jobItem && ref($jobItem) ) {

			# if 10 passed, remove job
			if ( ( $time + $self->{"autoRemove"} ) < time() ) {
				$self->{"form"}->RemoveJobFromQueue($taskId);
				splice @{ $self->{"removeJobs"} }, $i, 1;

			}
			else {
				my $secLeft = ( $time + $self->{"autoRemove"} ) - time();
				$self->{"form"}->SetJobItemAutoRemove( $taskId, $secLeft );

			}
		}
		else {
			splice @{ $self->{"removeJobs"} }, $i, 1;
		}

	}

}

# ========================================================================================== #
#  PROTECTED HELPER METHOD
# ========================================================================================== #

sub _GetTaskById {
	my $self   = shift;
	my $taskId = shift;

	foreach my $task ( @{ $self->{"tasks"} } ) {

		if ( $task->GetTaskId() eq $taskId ) {

			return $task;
		}
	}
}

sub _AddNewJob {
	my $self = shift;
	my $task = shift;

	push( @{ $self->{"tasks"} }, $task );

	# prepare gui
	$self->{"form"}->AddNewTaskGUI($task);

	# Add new task to queue
	$self->{"form"}->AddNewTask($task);

}

# Add tesk on auto remove list
sub _AddJobToAutoRemove {
	my $self   = shift;
	my $taskId = shift;

	my %removeInf = ( "taskId" => $taskId, "exportFinis" => time() );
	push( @{ $self->{"removeJobs"} }, \%removeInf );
}

# Add timers to list of all timers
# When app fail, all timers are stopped
sub _AddTimers {
	my $self   = shift;
	my $timers = shift;

	push( @{ $self->{"timers"} }, $timers );
}

# ========================================================================================== #
#  PRIVATE HELPER METHOD
# ========================================================================================== #

sub __SetHandlersBase {
	my $self = shift;

	#Set base handler

	$self->{"form"}->{'onJobStateChanged'}->Add( sub { $self->__OnJobStateChangedBase(@_) } );
	$self->{"form"}->{'onJobProgressEvt'}->Add( sub  { $self->__OnJobProgressEvtHandlerBase(@_) } );
	$self->{"form"}->{'onJobMessageEvt'}->Add( sub   { $self->__OnJobMessageEvtHandlerBase(@_) } );

	$self->{"form"}->{'onJomMngrClose'}->Add( sub { $self->__OnCloseAbstractQueueBase(@_) } );

	$self->{"form"}->{'onRemoveJob'}->Add( sub { $self->__OnRemoveJobClick(@_) } );

}

# Times are in milisecond
sub __RunTimersBase {
	my $self = shift;

	my $formMainFrm = $self->{"form"}->{"mainFrm"};

	my $timer5sec = Wx::Timer->new( $formMainFrm, -1, );
	Wx::Event::EVT_TIMER( $formMainFrm, $timer5sec, sub { $self->__Timer5second(@_) } );
	$timer5sec->Start(1000);
	$self->_AddTimers($timer5sec);

	my $timerVersion = Wx::Timer->new( $formMainFrm, -1, );
	$self->{"timerVersion"} = $timerVersion;
	Wx::Event::EVT_TIMER( $formMainFrm, $timerVersion, sub { $self->__TimerCheckVersion(@_) } );
	$timerVersion->Start( 3 * 60000 );    # every 5 minutes
	$self->_AddTimers($timerVersion);

	my $timer1s = Wx::Timer->new( $formMainFrm, -1, );
	Wx::Event::EVT_TIMER( $formMainFrm, $timer1s, sub { $self->__AutoRemoveJobsHandler(@_) } );
	$timer1s->Start(1000);
	$self->_AddTimers($timer1s);

}

# Restart task
sub __RestartTask {
	my $self = shift;
	my $task = shift;

	my $taskId = $task->GetTaskId();

	# 1) job is properlz aborted + keep task
	my $taskData    = $task->GetTaskData();
	my $taskStrData = $task->GetTaskStrData();
	my $taskJobId   = $task->GetJobId();

	# 2) remove job from queue
	$self->{"form"}->RemoveJobFromQueue($taskId);

	# 3) start new same job
	my $newTask = 0;
	$self->{"onSetNewTask"}->Do( $taskJobId, $taskData, $taskStrData, \$newTask );

	if ( !defined $newTask || $newTask == 0 ) {
		die "new task was not init";
	}

	$self->_AddNewJob($newTask);

}

sub __GetVersion {
	my $self = shift;

	# Get path of version file
	my $className = ref $self->{"form"};
	my @arr = split( "::", $className );

	@arr = @arr[ 0 .. ( scalar(@arr) - 4 ) ];

	my $packagePath = join( "\\", @arr );

	my $verPath = GeneralHelper->Root() . "\\" . $packagePath . "\\Config\\Version.txt";

	my $str = FileHelper->ReadAsString($verPath);

	unless ( defined $str ) {
		return 0;
	}

	$str =~ s/\t\r\n\s//g;

	if ( defined $str && $str ne "" ) {
		return $str;
	}
	else {
		return 0;
	}
}

# necessery for running RunALone library

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Managers::AbstractQueue::AbstractQueue::AbstractQueue';
	use aliased 'Widgets::Forms::MyTaskBarIcon';

	my $abstractQueue = AbstractQueue->new( EnumsJobMngr->RUNMODE_WINDOW );

	#my $form = $abstractQueue->{"form"}->{"mainFrm"};

	#my $trayicon = MyTaskBarIcon->new( "AbstractQueue", $form);

	#$trayicon->AddMenuItem("Exit AbstractQueue", sub {  $abstractQueue->{"form"}->OnClose() });
	#$trayicon->AddMenuItem("Open", sub { print "Open"; });

	#	sub __OnLeftClick {
	#	my $self = shift;
	#
	#	print "left click\n";
	#
	#	}

	#$trayicon->IsOk() || die;

	#$app->Test();

}

1;
