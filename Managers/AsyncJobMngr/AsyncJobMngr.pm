
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
use aliased 'Managers::AsyncJobMngr::ServerMngr';
use aliased 'Managers::AsyncJobMngr::ThreadMngr';
use aliased 'Managers::AsyncJobMngr::Helper';
use aliased 'Managers::MessageMngr::MessageMngr';
#use aliased 'Programs::Exporter::ThreadBase';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

use constant {
			   JOB_RUNNING      => "running",
			   JOB_WAITINGQUEUE => "waitingQueue",
			   JOB_WAITINGPORT  => "waitingPort",
			   JOB_STOPPED      => "stopped"
};

sub new {
	my $self   = shift;
	my $parent = shift;
	my $title = shift;
	my $dimension = shift;
	
	$self = {};

	unless ($parent) {
		$self = Wx::App->new( \&OnInit );
	}

	bless($self);
	
	#running mode
	$self->{"runMode"} = shift;
	

	my @jobs = ();
	$self->{"jobs"}       = \@jobs;
	$self->{"serverMngr"} = ServerMngr->new();
	$self->{"threadMngr"} = ThreadMngr->new();

	#$self->{"threadBase"} = ThreadBase->new();

	#add handler, when new thread start
	$self->{"threadMngr"}->{"onThreadWorker"}->Add( sub    { $self->__OnThreadWorkerHandler(@_) } );

	#class events

	$self->{'onJobStartRun'} = Event->new();
	$self->{'onJobDoneEvt'}     = Event->new();
	$self->{'onJobProgressEvt'} = Event->new();
	$self->{'onJobMessageEvt'}  = Event->new();
	$self->{'onRunJobWorker'} = Event->new();

	my $mainFrm = $self->__SetLayout($parent, $title, $dimension);

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

	my $self      = shift;
	my $pcbId     = shift;
	my $uniqueId    = shift; #unique task id
	my %extraInfo = %{ shift(@_) } if ( $_[0] );

	my %jobInfo = (
					"jobGUID" => $uniqueId,
					"pcbId"   => $pcbId,
					"state"   => JOB_WAITINGQUEUE,
					"port"    => -1,
					"data"    => undef
	);

	#add extra info
	%jobInfo = ( %jobInfo, %extraInfo );

	push( @{ $self->{"jobs"} }, \%jobInfo );

	return $jobInfo{"jobGUID"};

}

sub _RemoveJobFromQueue {

	my ( $self, $jobGUID ) = @_;

	my @j = @{ $self->{"jobs"} };
	my $i = ( grep { $j[$_]->{"jobGUID"} eq $jobGUID } 0 .. $#j )[0];

	unless ( defined $i ) {

		return 0;
	}

	if ( ${ $self->{"jobs"} }[$i]{"state"} eq JOB_RUNNING ) {

		$self->{"threadMngr"}->ExitThread( ${ $self->{"jobs"} }[$i]{"jobGUID"} );

	}
	else {

		Helper->Print( "THREAD with job id: " . ${ $self->{"jobs"} }[$i]{"pcbId"} . " is starting, try abort later.......\n" );
	}

}

sub _SetMaxServerCount {
	my $self     = shift;
	my $maxCount = shift;

	return $self->{"serverMngr"}->SetMaxServerCount($maxCount);
}

sub _GetInfoServers {
	my $self = shift;

	return $self->{"serverMngr"}->GetInfoServers();
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

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

		if ( ${$jobsRef}[$i]{"state"} eq JOB_RUNNING ) {

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

		if ( ${$jobsRef}[$i]{"state"} eq JOB_RUNNING || ${$jobsRef}[$i]{"state"} eq JOB_WAITINGPORT ) {
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

		$mainFrm->Destroy;
	}

}

sub _AbortJob {

	my $self    = shift;
	my $jobGUID = shift;
	my @j       = @{ $self->{"jobs"} };

	#my $i = ( grep { $j[$_]->{"jobGUID"} eq $jobGUID } 0 .. $#j )[0];
	my $i = ( grep { $j[$_]->{"pcbId"} eq $jobGUID } 0 .. $#j )[0];

	unless ( defined $i ) {

		return 0;
	}

	if ( ${ $self->{"jobs"} }[$i]{"state"} eq JOB_RUNNING ) {

		$self->{"threadMngr"}->ExitThread( ${ $self->{"jobs"} }[$i]{"jobGUID"} );

		#$self->{"serverMngr"}->ReturnServerPort( ${ $self->{"jobs"} }[$i]{"port"} );

		#$self->__RemoveJob( ${ $self->{"jobs"} }[$i]{"jobGUID"} );

	}
	else {

		Helper->Print( "THREAD with job id: " . ${ $self->{"jobs"} }[$i]{"pcbId"} . " is starting, try abort later.......\n" );
	}

}

sub OnExit {
	my $self = shift;

	print "onExitTTTTTTTTTTTTTTTT";

	my $jobsRef    = $self->{"jobs"};
	my $str        = "";
	my $activeJobs = 0;

	for ( my $i = 0 ; $i < scalar( @{$jobsRef} ) ; $i++ ) {

		if ( ${$jobsRef}[$i]{"state"} eq JOB_RUNNING || ${$jobsRef}[$i]{"state"} eq JOB_WAITINGPORT ) {

			$activeJobs = 1;

		}
		last;
	}

	if ($activeJobs) {

		# test na u6ivatele

		$self->{"timerFiles"}->Stop();

		for ( my $i = 0 ; $i < scalar( @{$jobsRef} ) ; $i++ ) {

			if ( ${$jobsRef}[$i]{"state"} eq JOB_RUNNING ) {

				$self->{"serverMngr"}->DestroyServer( ${$jobsRef}[$i]{"port"} );

			}

			if ( ${$jobsRef}[$i]{"state"} eq JOB_WAITINGPORT ) {

				while ( ${$jobsRef}[$i]{"state"} ne JOB_RUNNING ) {

					print "%% -  " . ${$jobsRef}[$i]{"state"} . "port: " . ${$jobsRef}[$i]{"state"} . "\n";
					sleep(1);
				}
				print "tadzzzyyyyyyyyyyy%% -  " . ${$jobsRef}[$i]{"state"} . "port: " . ${$jobsRef}[$i]{"state"} . "\n";
				$self->{"serverMngr"}->DestroyServer( ${$jobsRef}[$i]{"port"} );
			}

		}
	}

	#	exit();
}

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

		$self->__SetJobState( $jobGUID, JOB_WAITINGPORT );
		$self->{"serverMngr"}->PrepareServerPort($jobGUID);

	}

}

sub __SetLayout {

	my $self   = shift;
	my $parent = shift;
	my $title = shift;
	my @dimension = @{shift(@_)};

	#EVT_NOTEBOOK_PAGE_CHANGED( $self, $nb, $self->can( 'OnPageChanged' ) );

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,                   # parent window
		-1,                        # ID -1 means any
		$title,                # title
		&Wx::wxDefaultPosition,    # window position
		\@dimension              # size
		                           #&Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	);

	$self->{"mainFrm"} = $mainFrm;

	#EVENTS

	$mainFrm->{'onClose'}->Add( sub { $self->OnClose(@_) } );    #Set onClose handler

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

sub __RunTimers {
	my $self = shift;

	#$timerFiles->Start(1000);
	my $timerExport = Wx::Timer->new( $self->{"mainFrm"}, -1, );
	Wx::Event::EVT_TIMER( $self->{"mainFrm"}, $timerExport, sub { __TakeFromQueueHandler( $self, @_ ) } );
	$timerExport->Start(1000);
	$self->{"timerExport"} = $timerExport;

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
		${ $self->{"jobs"} }[$i]{"state"} = JOB_RUNNING;

		my $pcbId   = ${ $self->{"jobs"} }[$i]{"pcbId"};
		my $jobGUID = ${ $self->{"jobs"} }[$i]{"jobGUID"};

		$self->{"threadMngr"}->RunNewExport( $jobGUID, $d{"port"}, $pcbId );

		#raise onJobStarRun event
		my $ononJobStartRun = $self->{'onJobStartRun'};
		if ( $ononJobStartRun->Handlers() ) {
			$ononJobStartRun->Do($jobGUID);
		}
	}

}

sub __ThreadDoneHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	my $jobInfo = $self->__GetJobInfo( $d{"jobGUID"} );
	$self->{"serverMngr"}->ReturnServerPort( $jobInfo->{"port"} );
	$self->__RemoveJob( $d{"jobGUID"} );

	#reise event
	my $onJobDoneEvt = $self->{'onJobDoneEvt'};

	if ( $onJobDoneEvt->Handlers() ) {
		$onJobDoneEvt->Do( $d{"jobGUID"}, $d{"exitType"} );
	}

}

sub __ThreadProgressHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };
	

	#reise event
	my $onJobProgressEvt = $self->{'onJobProgressEvt'};

	if ( $onJobProgressEvt->Handlers() ) {
		$onJobProgressEvt->Do( $d{"jobGUID"}, $d{"value"} );
	}

	#print $event->etData;
}

sub __ThreadMessageHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	my $jobGUID = $d{"jobGUID"};
	my $messType = $d{"messType"};
	my $data = $d{"data"};


	#reise event
	my $onJobMessageEvt = $self->{'onJobMessageEvt'};

	if ( $onJobMessageEvt->Handlers() ) {
		$onJobMessageEvt->Do( $jobGUID, $messType, $data);
	}
}

sub __TakeFromQueueHandler {
	my ( $self, $frame, $event ) = @_;

	my $jobsRef = $self->{"jobs"};

	#try process waiting jobs

	for ( my $i = 0 ; $i < scalar( @{$jobsRef} ) ; $i++ ) {

		if ( ${$jobsRef}[$i]{"state"} eq JOB_WAITINGQUEUE ) {

			if ( $self->{"serverMngr"}->IsPortAvailable() ) {

				my $jobGUID = ${$jobsRef}[$i]{"jobGUID"};

				$self->__SetJobState( $jobGUID, JOB_WAITINGPORT );
				$self->{"serverMngr"}->PrepareServerPort($jobGUID);

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
