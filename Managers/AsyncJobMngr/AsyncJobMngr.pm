
#-------------------------------------------------------------------------------------------#
# Description: Job manager provide szstem for running more then one InCAM asynchronously
# in own child thread. Is responsible for:
# Properly launching new threads, InCAM servers
# Properly Exiting after job done, exiting after Force exit by user
# Author:SPR
#-------------------------------------------------------------------------------------------#

our $stylePath = undef;    # global variable, which set path to configuration file

package Managers::AsyncJobMngr::AsyncJobMngr;
use base 'Wx::App';

#3th party library
use threads;
use threads::shared;
use Wx;
use strict;
use warnings;

#local library
use Widgets::Style;
use aliased 'Widgets::Forms::MyWxFrame';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Managers::AsyncJobMngr::ServerMngr::ServerMngr';
use aliased 'Managers::AsyncJobMngr::ThreadMngr::ThreadMngr';
use aliased 'Managers::AsyncJobMngr::Helper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Managers::AsyncJobMngr::Enums';
use aliased 'Widgets::Forms::MyTaskBarIcon';
use aliased 'Managers::AsyncJobMngr::SettingsHelper';
use aliased 'Managers::AbstractQueue::AppConf';

#use aliased 'Programs::AbstractQueue::ThreadBase';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $runMode = shift;
	my $parent  = shift;
	my $title   = shift;
	my $name    = shift;    # name which is used in tray menu, etc (Export, Pool export etc.. this is only arbitrary string)

	# Get name of caller package
	my ( $packageFull, $filename, $line ) = caller;

	my $self = {};

	unless ($parent) {
		$self = Wx::App->new( \&OnInit );
	}

	bless($self);

	$self->__SetConfPath($class);

	# PROPERTIES

	#running mode: RUNMODE_WINDOW X RUNMODE_TRAY
	$self->{"runMode"}  = $runMode;
	$self->{"trayIcon"} = undef;

	my @jobs = ();
	$self->{"jobs"}       = \@jobs;
	$self->{"serverMngr"} = ServerMngr->new($name);
	$self->{"threadMngr"} = ThreadMngr->new();

	$self->{"settingsHelper"} = SettingsHelper->new( $self->{"serverMngr"}, $packageFull );

	# EVENTS

	$self->{'onJobStateChanged'} = Event->new();
	$self->{'onJobProgressEvt'}  = Event->new();
	$self->{'onJobMessageEvt'}   = Event->new();
	$self->{'onRunJobWorker'}    = Event->new();

	$self->{'onJomMngrClose'} = Event->new();    # reise right imidiatelly before destroy this app

	my $mainFrm = $self->__SetLayout( $parent, $title, $name );

	$self->__RunTimers();

	return $self;
}

sub OnInit {
	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Protected  methods
#-------------------------------------------------------------------------------------------#

sub _AddJobToQueue {

	my $self       = shift;
	my $pcbId      = shift;
	my $uniqueId   = shift;    #unique task id
	my $jobStrData = shift;    # string data, job process is based on them
	my $serverInfo = shift;    #server info, if external incam server is already prepared
	

	# new job item
	my %jobInfo = (
					"jobGUID"    => $uniqueId,
					"pcbId"      => $pcbId,
					"state"      => Enums->JobState_WAITINGQUEUE,
					"port"       => -1,
					"serverInfo" => $serverInfo,
					"jobStrData" => $jobStrData
	);

	push( @{ $self->{"jobs"} }, \%jobInfo );

	# TODO SMAZAT
	#$jobInfo{"port"}  = undef;
	#$jobInfo{"state"} = Enums->JobState_RUNNING;
	#$self->{"threadMngr"}->RunNewtask( $uniqueId, $jobInfo{"port"}, $pcbId );

	$self->{'onJobStateChanged'}->Do( $jobInfo{"jobGUID"}, $jobInfo{"state"} );

	return $jobInfo{"jobGUID"};

}

# Remove job from list of jobs
sub _RemoveJobFromQueue {

	my ( $self, $jobGUID ) = @_;

	my @j = @{ $self->{"jobs"} };
	my $i = ( grep { $j[$_]->{"jobGUID"} eq $jobGUID } 0 .. $#j )[0];

	unless ( defined $i ) {

		return 0;
	}

	if ( ${ $self->{"jobs"} }[$i]{"state"} eq Enums->JobState_RUNNING ) {

		$self->{"threadMngr"}->ExitThread( ${ $self->{"jobs"} }[$i]{"jobGUID"} );

	}
	else {

		Helper->Print( "THREAD with job id: " . ${ $self->{"jobs"} }[$i]{"pcbId"} . " is starting, try abort later.......\n" );
	}

}

# Force abort job by user
sub _AbortJob {

	my $self    = shift;
	my $jobGUID = shift;
	my @j       = @{ $self->{"jobs"} };

	#my $i = ( grep { $j[$_]->{"jobGUID"} eq $jobGUID } 0 .. $#j )[0];
	my $i = ( grep { $j[$_]->{"jobGUID"} eq $jobGUID } 0 .. $#j )[0];

	unless ( defined $i ) {

		return 0;
	}

	my $job = ${ $self->{"jobs"} }[$i];

	if ( $job->{"state"} eq Enums->JobState_RUNNING || $job->{"state"} eq Enums->JobState_RESTARTING ) {

		# first exit running thread
		$self->{"threadMngr"}->ExitThread( $job->{"jobGUID"} );
		$self->{'onJobStateChanged'}->Do( $jobGUID, Enums->JobState_ABORTING );

	}
	elsif ( $job->{"state"} eq Enums->JobState_WAITINGQUEUE ) {

		# remove job from queue
		$self->__RemoveJob($jobGUID);
		$self->{'onJobStateChanged'}->Do( $jobGUID, Enums->JobState_DONE, Enums->ExitType_FORCE );

	}
	elsif ( $job->{"state"} eq Enums->JobState_WAITINGPORT ) {

		# can't abort
		Helper->Print( "THREAD with job id: " . $job->{"pcbId"} . " is starting, try abort later.......\n" );

	}
	elsif ( $job->{"state"} eq Enums->JobState_ABORTING ) {

		# can't abort
		Helper->Print( "THREAD with job id: " . $job->{"pcbId"} . " is already abortin, try abort later.......\n" );

	}

}

# Two type of restarting

# If job is not DONE do Force restart by user. How it works:
# 1) set job stat - restarting
# 2) do standard abort
# 3) then after abort, end event is catched and job exit type is changed from exit FORCE to FORCERESTART

# If job is already DONE, only send message gob state change to ExitType_FORCERESTART
sub _RestartJob {
	my $self    = shift;
	my $jobGUID = shift;

	my $jobInf = $self->__GetJobInfo($jobGUID);

	if ( $jobInf->{"state"} ne Enums->JobState_DONE ) {

		# 1)  set job stat - restarting
		$self->__SetJobState( $jobGUID, Enums->JobState_RESTARTING );

		# 2) do standard abort
		$self->_AbortJob($jobGUID);
	}
	else {
		#reise event
		$self->{'onJobStateChanged'}->Do( $jobGUID, Enums->JobState_DONE, Enums->ExitType_FORCERESTART );
	}
}

# Continue paused job, set special variable which thread periodically read for STOP/CONTINUE
sub _ContinueJob {
	my $self    = shift;
	my $jobGUID = shift;

	$self->{"threadMngr"}->ContinueThread($jobGUID);

}

sub _SetMaxServerCount {
	my $self     = shift;
	my $maxCount = shift;

	$self->{"settingsHelper"}->SetMaxServerCount($maxCount);
}

sub _SetDestroyDelay {
	my $self         = shift;
	my $destroyDelay = shift;    # in second

	$self->{"settingsHelper"}->SetDestroyDelay($destroyDelay);
}

sub _SetDestroyOnDemand {
	my $self  = shift;
	my $value = shift;           # in second

	$self->{"settingsHelper"}->SetDestroyOnDemand($value);
}

sub _GetInfoServers {
	my $self = shift;

	return $self->{"serverMngr"}->GetInfoServers();
}

sub _GetServerSettings {
	my $self = shift;

	return $self->{"serverMngr"}->GetServerSettings();
}

sub _GetServerStat {
	my $self = shift;

	return $self->{"serverMngr"}->GetServerStat();
}

sub _DestroyExternalServer {
	my $self = shift;
	my $port = shift;

	if ( defined $port ) {

		$self->{"serverMngr"}->DestroyExternalServer($port);
	}

}

# Set reference on working function
# This working function will be called, after job will be taken from queue
# and its port will be prepared
sub _SetThreadWorker {
	my $self         = shift;
	my $workerMethod = shift;

	#add handler, when new thread start
	$self->{"threadMngr"}->{"onThreadWorker"}->Add($workerMethod);

	$self->{"threadMngr"}->InitThreadPool();

}

#-------------------------------------------------------------------------------------------#
#  Handlers, proccessing events from ThreadMngr, ServerMngr
#-------------------------------------------------------------------------------------------#

# Run, when InCam server is ready and new job could process working funcction
sub __PortReadyHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	my @j = @{ $self->{"jobs"} };
	my $i = ( grep { $j[$_]->{"jobGUID"} eq $d{"jobGUID"} } 0 .. $#j )[0];

	if ( defined $i ) {

		${ $self->{"jobs"} }[$i]{"port"}  = $d{"port"};
		${ $self->{"jobs"} }[$i]{"state"} = Enums->JobState_RUNNING;

		#${ $self->{"jobs"} }[$i]{"port"}  = $d{"port"};#

		my $pcbId          = ${ $self->{"jobs"} }[$i]{"pcbId"};
		my $jobGUID        = ${ $self->{"jobs"} }[$i]{"jobGUID"};
		my $externalServer = ${ $self->{"jobs"} }[$i]{"serverInfo"} ? 1 : 0;

		$self->{'onJobStateChanged'}->Do( $jobGUID, Enums->JobState_RUNNING );

		$self->{"threadMngr"}->RunNewtask( $jobGUID, ${ $self->{"jobs"}}[$i]->{"jobStrData"}, $d{"port"}, $pcbId, $d{"pidInCAM"}, $externalServer )
		  ;

	}

}

# Run after job finish its working mehod
sub __ThreadDoneHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	my $jobGUID  = $d{"jobGUID"};
	my $exitType = $d{"exitType"};

	my $jobInfo = $self->__GetJobInfo( $d{"jobGUID"} );
	$self->{"serverMngr"}->ReturnServerPort( $jobInfo->{"port"} );

	#$self->__RemoveJob( $d{"jobGUID"} );

	# Send message, thread exited FORCE or FORCERESTART or SUCCES
	# do difference between exit FORCE - by aborting bz user and exit FORCE because of restart
	if ( $exitType eq Enums->ExitType_FORCE && $jobInfo->{"state"} eq Enums->JobState_RESTARTING ) {
		$exitType = Enums->ExitType_FORCERESTART;
	}

	# Set new job state DONE
	$self->__SetJobState( $jobGUID, Enums->JobState_DONE );

	#reise event
	$self->{'onJobStateChanged'}->Do( $jobGUID, Enums->JobState_DONE, $exitType );
}

sub __ThreadProgressHandler {
	my ( $self, $frame, $event ) = @_;

	my %d       = %{ $event->GetData };
	my $jobGUID = $d{"taskId"};
	my $data    = $d{"data"};

	#reise event
	my $onJobProgressEvt = $self->{'onJobProgressEvt'};

	if ( $onJobProgressEvt->Handlers() ) {
		$onJobProgressEvt->Do( $jobGUID, $data );
	}
}

sub __ThreadMessageHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	my $jobGUID  = $d{"taskId"};
	my $messType = $d{"messType"};
	my $data     = $d{"data"};

	#reise event
	my $onJobMessageEvt = $self->{'onJobMessageEvt'};

	if ( $onJobMessageEvt->Handlers() ) {
		$onJobMessageEvt->Do( $jobGUID, $messType, $data );
	}
}

sub __OnThreadWorkerHandler {
	my $self = shift;

	#reise event
	my $onRunJobWorker = $self->{'onRunJobWorker'};

	if ( $onRunJobWorker->Handlers() ) {

		$onRunJobWorker->Do(@_);
	}

}

#-------------------------------------------------------------------------------------------#
#  Handlers, other
#-------------------------------------------------------------------------------------------#

# In specific periods, try to take obs from queue
# and test, if there are free ports/servers
sub __TakeFromQueueHandler {
	my ( $self, $frame, $event ) = @_;

	my $jobsRef = $self->{"jobs"};

	#try process waiting jobs

	for ( my $i = 0 ; $i < scalar( @{$jobsRef} ) ; $i++ ) {

		my $jobGUID = ${$jobsRef}[$i]{"jobGUID"};

		if ( ${$jobsRef}[$i]{"state"} eq Enums->JobState_WAITINGQUEUE ) {

			# if job with externally prepared server
			if ( ${$jobsRef}[$i]{"serverInfo"} ) {

				if ( $self->{"serverMngr"}->IsFreePortAvailable() ) {

					$self->__SetJobState( $jobGUID, Enums->JobState_WAITINGPORT );

					$self->{'onJobStateChanged'}->Do( $jobGUID, Enums->JobState_WAITINGPORT );
					$self->{"serverMngr"}->PrepareExternalServerPort( $jobGUID, ${$jobsRef}[$i]{"serverInfo"} );

				}

			}
			else {

				if ( $self->{"serverMngr"}->IsPortAvailable() ) {

					$self->__SetJobState( $jobGUID, Enums->JobState_WAITINGPORT );

					$self->{'onJobStateChanged'}->Do( $jobGUID, Enums->JobState_WAITINGPORT );
					$self->{"serverMngr"}->PrepareServerPort($jobGUID);

				}
			}

		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self   = shift;
	my $parent = shift;
	my $title  = shift;
	my $name   = shift;

	my @dimension = ( AppConf->GetValue("windowWidth"), AppConf->GetValue("windowHeight") );

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,    # parent window
		-1,         # ID -1 means any
		$title,     # title

		[ -1, -1 ], # window position
		\@dimension,    # size   &Wx::wxSTAY_ON_TOP |
		&Wx::wxSTAY_ON_TOP | &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX | &Wx::wxMAXIMIZE_BOX | &Wx::wxCLOSE_BOX
	);

	if ( $self->{"runMode"} eq Enums->RUNMODE_TRAY ) {

		my $trayicon = MyTaskBarIcon->new( $name, $mainFrm );
		$trayicon->AddMenuItem( "Exit " . $name, sub { $self->__OnClose() } );
		$mainFrm->{'onClose'}->Add( sub { $mainFrm->Hide(); } );    #Set onClose handler

	}
	elsif ( $self->{"runMode"} eq Enums->RUNMODE_WINDOW ) {

		$mainFrm->{'onClose'}->Add( sub { $self->__OnClose(@_) } );    #Set onClose handler
	}

	$self->{"mainFrm"} = $mainFrm;

	#EVENTS

	my $THREAD_DONE_EVT : shared = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $THREAD_DONE_EVT, sub { $self->__ThreadDoneHandler(@_) } );

	my $THREAD_PROGRESS_EVT : shared = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $THREAD_PROGRESS_EVT, sub { $self->__ThreadProgressHandler(@_) } );

	my $THREAD_MESSAGE_EVT : shared = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $THREAD_MESSAGE_EVT, sub { $self->__ThreadMessageHandler(@_) } );

	my $PORT_READY_EVT : shared = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $PORT_READY_EVT, sub { $self->__PortReadyHandler(@_) } );

	$self->{"serverMngr"}->Init( $self->{"mainFrm"}, \$PORT_READY_EVT );
	$self->{"threadMngr"}->Init( $self->{"mainFrm"}, \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT, \$THREAD_DONE_EVT );

	return $mainFrm;
}

sub __CloseActiveJobs {
	my ( $self, $frame, $event ) = @_;

	my $jobsRef = $self->{"jobs"};

	# Set when closing mngr, all active servers was closed too
	$self->{"serverMngr"}->SetDestroyOnDemand(0);

	# first, close all running jobs
	for ( my $i = 0 ; $i < scalar( @{$jobsRef} ) ; $i++ ) {

		if ( ${$jobsRef}[$i]{"state"} eq Enums->JobState_RUNNING ) {

			$self->{"threadMngr"}->ExitThread( ${$jobsRef}[$i]{"jobGUID"} );
		}
	}

	# pokud jsou vsechny threads ukoncene, muzeme ukoncit program
	# jinak cekame ay se spusti pripadne joby, co jsou ve stavu WAITINGPORT
	if ( scalar( @{$jobsRef} ) == 0 ) {
		$self->{"timerCloseJobs"}->Stop();

		print STDERR "Destroying main frame 1\n\n";

		$self->{'onJomMngrClose'}->Do();

		$frame->Destroy();
		$self->ExitMainLoop();    # this line is necessery to console window was exited too
	}
}

# Function responsible for properly close threads and servers
sub __OnClose {

	my ( $self, $mainFrm ) = @_;

	my $jobsRef    = $self->{"jobs"};
	my $str        = "";
	my $activeJobs = 0;

	# Stop timers - we don't want take another jobs from queue
	$self->{"timertask"}->Stop();

	my @jobsName = ();

	#search active jobs
	for ( my $i = 0 ; $i < scalar( @{$jobsRef} ) ; $i++ ) {

		if ( ${$jobsRef}[$i]{"state"} eq Enums->JobState_RUNNING || ${$jobsRef}[$i]{"state"} eq Enums->JobState_WAITINGPORT ) {
			$activeJobs = 1;

			push( @jobsName, ${$jobsRef}[$i]{"pcbId"} );
		}

	}

	if ($activeJobs) {

		#ask if exit

		my $messMngr = MessageMngr->new();

		my @btns = ( "Cancel", "Abort jobs" );
		my @mess = ( "Some jobs are still active ?\n\n", "Jobs name :  " . join( ', ', @jobsName ) );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess, \@btns );

		my $test = $messMngr->Result();

		if ( $messMngr->Result() == 1 ) {

			#cancel active jobs asyn
			$self->{"timerCloseJobs"}->Start(1000);

		}
		else {

			#Cancel,  thus continue in work..
			$self->{"timertask"}->Start(1000);
		}

	}
	else {

		# Close or servers, which are waiting or running
		$self->{"serverMngr"}->SetDestroyOnDemand(0);

		$self->{'onJomMngrClose'}->Do();

		$self->{"mainFrm"}->Destroy();
		$self->ExitMainLoop();    # this line is necessery to console window was exited too

	}

}

sub __OnClick {

	my ( $self, $button ) = @_;
	$self->{"mainFrm"}->Close();
	print "\nClick\n";
}

sub __RemoveJob {
	my $self    = shift;
	my $jobGUID = shift;

	my @j = @{ $self->{"jobs"} };
	my $idx = ( grep { $j[$_]->{"jobGUID"} eq $jobGUID } 0 .. $#j )[0];

	if ( defined $idx ) {

		splice @{ $self->{"jobs"} }, $idx, 1;
	}

}

# Times are in milisecond
sub __RunTimers {
	my $self = shift;

	my $timertask = Wx::Timer->new( $self->{"mainFrm"}, -1, );
	Wx::Event::EVT_TIMER( $self->{"mainFrm"}, $timertask, sub { __TakeFromQueueHandler( $self, @_ ) } );
	$timertask->Start(1000);
	$self->{"timertask"} = $timertask;

	my $timerCloseOnDemand = Wx::Timer->new( $self->{"mainFrm"}, -1, );
	Wx::Event::EVT_TIMER( $self->{"mainFrm"}, $timerCloseOnDemand, sub { $self->{"serverMngr"}->DestroyServersOnDemand(@_) } );
	$timerCloseOnDemand->Start(2000);

	my $timerCloseJobs = Wx::Timer->new( $self->{"mainFrm"}, -1, );
	Wx::Event::EVT_TIMER( $self->{"mainFrm"}, $timerCloseJobs, sub { __CloseActiveJobs( $self, @_ ) } );
	$self->{"timerCloseJobs"} = $timerCloseJobs;

}

sub __SetJobState {
	my ( $self, $jobGUID, $newState ) = @_;

	my @j = @{ $self->{"jobs"} };
	my $idx = ( grep { $j[$_]->{"jobGUID"} eq $jobGUID } 0 .. $#j )[0];

	if ( defined $idx ) {

		${ $self->{"jobs"} }[$idx]{"state"} = $newState;

		return 1;
	}
	else {
		return 0;
	}
}

sub __GetJobInfo {
	my ( $self, $jobGUID ) = @_;

	my @j = @{ $self->{"jobs"} };
	my $idx = ( grep { $j[$_]->{"jobGUID"} eq $jobGUID } 0 .. $#j )[0];

	if ( defined $idx ) {

		return ${ $self->{"jobs"} }[$idx];

	}
	else {
		return 0;
	}
}

# Set path (global variable) to app configuration file
sub __SetConfPath {
	my $self   = shift;
	my $caller = shift;

	# Set path of style configuration file
	#my $className = ref $self;
	my @arr = split( "::", $caller );
	@arr = @arr[ 0 .. ( scalar(@arr) - 4 ) ];
	my $packagePath = join( "\\", @arr );

	$main::stylePath = GeneralHelper->Root() . "\\" . $packagePath . "\\Config\\Config.txt";

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = Programs::AbstractQueue::AsyncJobMngr->new();

	#$app->Test();

	#$app->MainLoop;

}

1;

