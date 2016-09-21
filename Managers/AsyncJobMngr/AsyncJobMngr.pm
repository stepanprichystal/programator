
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
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

#use aliased 'Programs::Exporter::ThreadBase';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self      = shift;
	my $runMode   = shift;
	my $parent    = shift;
	my $title     = shift;
	my $dimension = shift;

	# Get name of caller package
	my ( $packageFull, $filename, $line ) = caller;

	$self = {};

	unless ($parent) {
		$self = Wx::App->new( \&OnInit );
	}

	bless($self);

	#running mode: RUNMODE_WINDOW X RUNMODE_TRAY
	$self->{"runMode"}  = $runMode;
	$self->{"trayIcon"} = undef;

	my @jobs = ();
	$self->{"jobs"}       = \@jobs;
	$self->{"serverMngr"} = ServerMngr->new();
	$self->{"threadMngr"} = ThreadMngr->new();

	$self->{"settingsHelper"} = SettingsHelper->new( $self->{"serverMngr"}, $packageFull );

	#$self->{"threadBase"} = ThreadBase->new();

	# EVENTS

	#$self->{'onJobStartRun'}    = Event->new();
	#$self->{'onJobDoneEvt'}     = Event->new();

	$self->{'onJobStateChanged'} = Event->new();
	$self->{'onJobProgressEvt'}  = Event->new();
	$self->{'onJobMessageEvt'}   = Event->new();
	$self->{'onRunJobWorker'}    = Event->new();

	my $mainFrm = $self->__SetLayout( $parent, $title, $dimension );

	# TODO odkomentovat
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
	my $serverInfo = shift;    #unique task id
	                           #my %extraInfo = %{ shift(@_) } if ( $_[0] );

	my %jobInfo = (
					"jobGUID"    => $uniqueId,
					"pcbId"      => $pcbId,
					"state"      => Enums->JobState_WAITINGQUEUE,
					"port"       => -1,
					"serverInfo" => $serverInfo,
	);

	#add extra info
	#%jobInfo = ( %jobInfo, %extraInfo );

	push( @{ $self->{"jobs"} }, \%jobInfo );

	# TODO SMAZAT
	#$jobInfo{"port"}  = undef;
	#$jobInfo{"state"} = Enums->JobState_RUNNING;
	#$self->{"threadMngr"}->RunNewExport( $uniqueId, $jobInfo{"port"}, $pcbId );

	$self->{'onJobStateChanged'}->Do( $jobInfo{"jobGUID"}, $jobInfo{"state"} );

	return $jobInfo{"jobGUID"};

}

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
	my $self         = shift;
	my $value = shift;    # in second

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

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub _SetThreadWorker {
	my $self         = shift;
	my $workerMethod = shift;

	#add handler, when new thread start
	$self->{"threadMngr"}->{"onThreadWorker"}->Add($workerMethod);

}

sub __OnThreadWorkerHandler {
	my $self = shift;

	#my $THREAD_DONE_EVT : shared = Wx::NewEventType;
	#Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $THREAD_DONE_EVT, sub { $self->__ThreadDoneHandler(@_) } );

	#my $THREAD_PROGRESS_EVT : shared = Wx::NewEventType;
	#Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $THREAD_PROGRESS_EVT, sub { $self->__ThreadProgressHandler(@_) } );

	#my $THREAD_MESSAGE_EVT : shared = Wx::NewEventType;
	#Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $THREAD_MESSAGE_EVT, sub { $self->__ThreadMessageHandler(@_) } );

	#reise event
	my $onRunJobWorker = $self->{'onRunJobWorker'};

	if ( $onRunJobWorker->Handlers() ) {

		#$onRunJobWorker->Do(@_, \$THREAD_DONE_EVT, \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT);
		$onRunJobWorker->Do(@_);
	}

}

sub __CloseActiveJobs {
	my ( $self, $frame, $event ) = @_;

	my $jobsRef = $self->{"jobs"};

	#nastavime aby se pri ukonceni threadu se okamzite ukoncil i serever+incam
	$self->{"serverMngr"}->SetDestroyOnDemand(0);

	#first, close all running jobs
	for ( my $i = 0 ; $i < scalar( @{$jobsRef} ) ; $i++ ) {

		if ( ${$jobsRef}[$i]{"state"} eq Enums->JobState_RUNNING ) {

			$self->{"threadMngr"}->ExitThread( ${$jobsRef}[$i]{"jobGUID"} );
		}
	}

	#pokud jsou vsechny threads ukoncene, muzeme ukoncit program
	# jinak cekame ay se spusti pripadne joby, co jsou ve stavu WAITINGPORT
	if ( scalar( @{$jobsRef} ) == 0 ) {
		$self->{"timerCloseJobs"}->Stop();
		$frame->Destroy();
	}

	print "PRUCHOD\n";
}

sub OnClose {

	my ( $self, $mainFrm ) = @_;

	my $jobsRef    = $self->{"jobs"};
	my $str        = "";
	my $activeJobs = 0;

	$self->{"timerExport"}->Stop();

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
			#$self->{"timerFiles"}->Start(200);

		}

	}
	else {

		# ukoncime sechnz servery, ktere bezi a cekaji na vyuziti
		$self->{"serverMngr"}->SetDestroyOnDemand(0);
		$self->{"mainFrm"}->Destroy();
	}

}

sub _AbortJob {

	my $self    = shift;
	my $jobGUID = shift;
	my @j       = @{ $self->{"jobs"} };

	#my $i = ( grep { $j[$_]->{"jobGUID"} eq $jobGUID } 0 .. $#j )[0];
	my $i = ( grep { $j[$_]->{"jobGUID"} eq $jobGUID } 0 .. $#j )[0];

	unless ( defined $i ) {

		return 0;
	}

	if ( ${ $self->{"jobs"} }[$i]{"state"} eq Enums->JobState_RUNNING ) {

		$self->{"threadMngr"}->ExitThread( ${ $self->{"jobs"} }[$i]{"jobGUID"} );

		#$self->{"serverMngr"}->ReturnServerPort( ${ $self->{"jobs"} }[$i]{"port"} );

		#$self->__RemoveJob( ${ $self->{"jobs"} }[$i]{"jobGUID"} );

		$self->{'onJobStateChanged'}->Do( $jobGUID, Enums->JobState_ABORTING );

	}
	else {

		Helper->Print( "THREAD with job id: " . ${ $self->{"jobs"} }[$i]{"pcbId"} . " is starting, try abort later.......\n" );

	}

}

#sub OnExit {
#	my $self = shift;
#
#	print "onExitTTTTTTTTTTTTTTTT";
#
#	my $jobsRef    = $self->{"jobs"};
#	my $str        = "";
#	my $activeJobs = 0;
#
#	for ( my $i = 0 ; $i < scalar( @{$jobsRef} ) ; $i++ ) {
#
#		if ( ${$jobsRef}[$i]{"state"} eq Enums->JobState_RUNNING || ${$jobsRef}[$i]{"state"} eq Enums->JobState_WAITINGPORT ) {
#
#			$activeJobs = 1;
#
#		}
#		last;
#	}
#
#	if ($activeJobs) {
#
#		# test na u6ivatele
#
#		$self->{"timerFiles"}->Stop();
#
#		for ( my $i = 0 ; $i < scalar( @{$jobsRef} ) ; $i++ ) {
#
#			if ( ${$jobsRef}[$i]{"state"} eq Enums->JobState_RUNNING ) {
#
#				$self->{"serverMngr"}->DestroyServer( ${$jobsRef}[$i]{"port"} );
#
#			}
#
#			if ( ${$jobsRef}[$i]{"state"} eq Enums->JobState_WAITINGPORT ) {
#
#				while ( ${$jobsRef}[$i]{"state"} ne Enums->JobState_RUNNING ) {
#
#					print "%% -  " . ${$jobsRef}[$i]{"state"} . "port: " . ${$jobsRef}[$i]{"state"} . "\n";
#					sleep(1);
#				}
#				print "tadzzzyyyyyyyyyyy%% -  " . ${$jobsRef}[$i]{"state"} . "port: " . ${$jobsRef}[$i]{"state"} . "\n";
#				$self->{"serverMngr"}->DestroyServer( ${$jobsRef}[$i]{"port"} );
#			}
#
#		}
#	}
#
#	#	exit();
#}

sub _GetInfoJobs {
	my $self = shift;

	my $jobsRef = $self->{"jobs"};
	my $str     = "";

	for ( my $i = 0 ; $i < scalar( @{$jobsRef} ) ; $i++ ) {

		$str .= "pcbId: " . ${$jobsRef}[$i]{"pcbId"} . "\n";
		$str .= "- jobGUID: " . ${$jobsRef}[$i]{"jobGUID"} . "\n";
		$str .= "- state: " . ${$jobsRef}[$i]{"state"} . "\n";
		$str .= "- port: " . ${$jobsRef}[$i]{"port"} . "\n\n";

	}

	return $str;
}

sub Test {
	my $self = shift;

	my $pcbId = "F17116+3";

	my $jobGUID = $self->__NewJob($pcbId);

	if ( $self->{"serverMngr"}->IsPortAvailable() ) {

		$self->__SetJobState( $jobGUID, Enums->JobState_WAITINGPORT );
		$self->{"serverMngr"}->PrepareServerPort($jobGUID);

	}

}

sub __SetLayout {

	my $self      = shift;
	my $parent    = shift;
	my $title     = shift;
	my @dimension = @{ shift(@_) };

	#EVT_NOTEBOOK_PAGE_CHANGED( $self, $nb, $self->can( 'OnPageChanged' ) );

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,    # parent window
		-1,         # ID -1 means any
		$title,     # title

		[ -1, -1 ], # window position
		\@dimension,    # size   &Wx::wxSTAY_ON_TOP |
		&Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX | &Wx::wxMAXIMIZE_BOX | &Wx::wxCLOSE_BOX
	);

	if ( $self->{"runMode"} eq Enums->RUNMODE_TRAY ) {

		my $trayicon = MyTaskBarIcon->new( "Exporter", $mainFrm );
		$trayicon->AddMenuItem( "Exit Exporter", sub { $self->OnClose() } );
		$mainFrm->{'onClose'}->Add( sub { $mainFrm->Hide(); } );    #Set onClose handler

	}
	elsif ( $self->{"runMode"} eq Enums->RUNMODE_WINDOW ) {

		$mainFrm->{'onClose'}->Add( sub { $self->OnClose(@_) } );    #Set onClose handler
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

	#$self->{"threadMngr"}->Init( $self->{"mainFrm"}, \$THREAD_DONE_EVT );

	#	#reise event
	#	my $onSetLayout = $self->{'onSetLayout'};
	#
	#	if ($onSetLayout->Handlers() ) {
	#		$onSetLayout->Do();
	#	}

	return $mainFrm;
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

	my $timerExport = Wx::Timer->new( $self->{"mainFrm"}, -1, );
	Wx::Event::EVT_TIMER( $self->{"mainFrm"}, $timerExport, sub { __TakeFromQueueHandler( $self, @_ ) } );
	$timerExport->Start(1000);
	$self->{"timerExport"} = $timerExport;

	my $timerCloseOnDemand = Wx::Timer->new( $self->{"mainFrm"}, -1, );
	Wx::Event::EVT_TIMER( $self->{"mainFrm"}, $timerCloseOnDemand, sub { $self->{"serverMngr"}->DestroyServersOnDemand(@_) } );
	$timerCloseOnDemand->Start(2000);

	my $timerCloseJobs = Wx::Timer->new( $self->{"mainFrm"}, -1, );
	Wx::Event::EVT_TIMER( $self->{"mainFrm"}, $timerCloseJobs, sub { __CloseActiveJobs( $self, @_ ) } );
	$self->{"timerCloseJobs"} = $timerCloseJobs;

}

sub __PortReadyHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	my @j = @{ $self->{"jobs"} };
	my $i = ( grep { $j[$_]->{"jobGUID"} eq $d{"jobGUID"} } 0 .. $#j )[0];

	if ( defined $i ) {

		${ $self->{"jobs"} }[$i]{"port"}  = $d{"port"};
		${ $self->{"jobs"} }[$i]{"state"} = Enums->JobState_RUNNING;

		my $pcbId   = ${ $self->{"jobs"} }[$i]{"pcbId"};
		my $jobGUID = ${ $self->{"jobs"} }[$i]{"jobGUID"};

		$self->{'onJobStateChanged'}->Do( $jobGUID, Enums->JobState_RUNNING );

		$self->{"threadMngr"}->RunNewExport( $jobGUID, $d{"port"}, $pcbId );

	}

}

sub __ThreadDoneHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	my $jobGUID  = $d{"jobGUID"};
	my $exitType = $d{"exitType"};

	my $jobInfo = $self->__GetJobInfo( $d{"jobGUID"} );
	$self->{"serverMngr"}->ReturnServerPort( $jobInfo->{"port"} );
	$self->__RemoveJob( $d{"jobGUID"} );

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

	#print $event->etData;
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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = Programs::Exporter::AsyncJobMngr->new();

	#$app->Test();

	#$app->MainLoop;

}

1;

#my $app = MyApp2->new();

#my $worker = threads->create( \&work );
#print $worker->tid();

#
#sub work {
#	sleep(5);
#	print "METODA==========\n";
#
#	#!!! I would like send array OR hash insted of scalar here: my %result = ("key1" => 1, "key2" => 2 );
#	# !!! How to do that?
#
#}
#
#sub OnCreateThread {
#	my ( $self, $event ) = @_;
#	@_ = ();
#}

1;
