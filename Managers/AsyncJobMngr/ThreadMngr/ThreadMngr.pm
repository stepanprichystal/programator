
#-------------------------------------------------------------------------------------------#
# Description: Manager for threads. Keep list of running threads
# Responsilbe for start new, force kill etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AsyncJobMngr::ThreadMngr::ThreadMngr;

use threads;
use threads::shared;
use Wx;
use Time::HiRes qw (sleep);
use Thread::Queue;

#3th party library
use strict;
use aliased 'Managers::AsyncJobMngr::Enums';
use aliased 'Managers::AsyncJobMngr::Helper';
use aliased 'Packages::Events::Event';
use aliased 'Managers::AbstractQueue::Helper' => "HelperAbstrQ";
use aliased 'Managers::AbstractQueue::AppConf';

#local library
use aliased 'Packages::InCAM::InCAM';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

my $THREAD_PROGRESS_EVT : shared;
my $THREAD_MESSAGE_EVT : shared;
my $THREAD_DONE_EVT : shared;
my $THREAD_END_EVT : shared;

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	my @threadTasks = ();

	$self->{"threadTasks"} = \@threadTasks;    # for each task is created ifno hash
	$self->{"thrTaskCnt"}  = 0;

	#raise when new thread start
	$self->{"onThreadWorker"} = Event->new();

	return $self;
}

sub DESTROY {
	my $self = shift;

	# clean up created thread pools
	foreach my $thrId ( keys %{ $self->{"work_queues"} } ) {

		my $thrObj = threads->object($thrId);
		if ( defined $thrObj ) {
			$thrObj->kill('KILL');
		}
	}
}

sub Init {
	my $self = shift;

	$self->{"abstractQueueFrm"} = shift;

	$THREAD_PROGRESS_EVT = ${ shift(@_) };
	$THREAD_MESSAGE_EVT  = ${ shift(@_) };
	$THREAD_DONE_EVT     = ${ shift(@_) };

	$THREAD_END_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"abstractQueueFrm"}, -1, $THREAD_END_EVT, sub { $self->__ThreadEndedHandler(@_) } );

}

sub InitThreadPool {
	my $self = shift;

	# Maximum working threads
	$self->{"MAX_THREADS"} = 4;
	$self->{"MIN_THREADS"} = 3;

	# Threads add their ID to this queue when they are ready for work
	$self->{"IDLE_QUEUE"} = Thread::Queue->new();

	# Thread work queues referenced by thread ID
	my %work_queues;
	$self->{"work_queues"} = \%work_queues;

	# Create the thread pool
	for ( 1 .. $self->{"MAX_THREADS"} ) {
		$self->__AddThreadPool();

	}
}

# Processrequest for starting new thread
sub RunNewtask {
	my $self           = shift;
	my $jobGUID        = shift;
	my $jobStrData     = shift;
	my $port           = shift;
	my $pcbId          = shift;
	my $pidInCAM       = shift;
	my $externalServer = shift;

	$self->{"thrTaskCnt"} += 1;

	print STDERR "\n\n\ntask utility: THERAD ORDER IS :  " . $self->{"thrTaskCnt"} . ".\n\n\n";
 	my $threadOrder = $self->{"thrTaskCnt"};
	# special shared variable, which child process periodically read and decide if stop or continue in task
	my $stoppedShare = 0;
	share($stoppedShare);

	my $pcbIdShare = $pcbId;
	share($pcbIdShare);

	my $thrId = $self->__CreateThread( $jobGUID, $jobStrData, $port, \$pcbIdShare, $pidInCAM, $externalServer, \$stoppedShare, $threadOrder );

	my %thrTaskInf = (
					   "jobGUID" => $jobGUID,
					   "thrId"   => $thrId,          # id of thread, where is task processed
					   "port"    => $port,
					   "pcbId"   => \$pcbIdShare,    # ref variable, where pcbId is stored
					   "stopped" => \$stoppedShare
	);

	push( @{ $self->{"threadTasks"} }, \%thrTaskInf );

}

# Process request for force exit of thread
# Responsible for proper aborting
sub ExitThread {
	my $self    = shift;
	my $jobGUID = shift;

	my $thr = ( grep { $_->{"jobGUID"} eq $jobGUID } @{ $self->{"threadTasks"} } )[0];

	if ( defined $thr ) {

		#print $thr->{"thrId"};

		my $thrObj = threads->object( $thr->{"thrId"} );

		if ( defined $thrObj ) {

			my $thrId = $thrObj->tid();

			if ( $thrObj->is_running() ) {

				#$thrObj->detach();

				$thrObj->kill('KILL');

				Helper->Print( "Thread:   port:" . $thr->{"port"} . "...........................try to end thread\n" );

			}
			else {

				#In case, thread already finished
				# This can happend in time, when user abort thread when was running, or thread broke down
				# But in time of this place, thread is alreadz finished
				$self->__ThreadEnded( $jobGUID, Enums->ExitType_FORCE );
			}

			return 1;
		}

		return 0;

	}
}

# Process request for stoping thread
# Set special "stop" shared variable, which child process periodically control
sub StopThread {
	my $self    = shift;
	my $jobGUID = shift;

	my $thr = ( grep { $_->{"jobGUID"} eq $jobGUID } @{ $self->{"threadTasks"} } )[0];

	if ( defined $thr ) {

		${ $thr->{"stopped"} } = 1;
	}
}

# Process request for continue thread
# Set special "stop" shared variable, which child process periodically control
sub ContinueThread {
	my $self    = shift;
	my $jobGUID = shift;

	my $thr = ( grep { $_->{"jobGUID"} eq $jobGUID } @{ $self->{"threadTasks"} } )[0];

	if ( defined $thr ) {

		${ $thr->{"stopped"} } = 0;
	}
}

# Create new thread pool and add it
sub __AddThreadPool {
	my $self = shift;

	# Create a work queue for a thread
	my $work_q = Thread::Queue->new();

	# Create the thread, and give it the work queue
	my $thr = threads->create( sub { $self->__PoolWorker($work_q) } );
	$thr->set_thread_exit_only(1);

	# Remember the thread's work queue
	$self->{"work_queues"}->{ $thr->tid() } = $work_q;
}

sub __FillThreadPool {
	my $self = shift;

	# when we exit thread, it is necessary create new thread and add to thraad pool
	# because we want keep maximum thread readz in order do more task in same time
	my $threadPoolCnt = 0;
	foreach my $thrId ( keys %{ $self->{"work_queues"} } ) {

		my $thrObj = threads->object($thrId);
		if ( defined $thrObj && $thrObj->is_running() ) {
			$threadPoolCnt++;
		}
	}

	for(my $i = 0; $i <  ($self->{"MIN_THREADS"} - $threadPoolCnt ); $i++){
 
		print STDERR "\n Add new thread pool. TOtal cnt: $threadPoolCnt. \n";
		$self->__AddThreadPool();
	}
}

sub __CreateThread {
	my $self           = shift;
	my $jobGUID        = shift;
	my $jobStrData     = shift;
	my $port           = shift;
	my $pcbIdShare     = shift;
	my $pidInCAM       = shift;
	my $externalServer = shift;
	my $stopVarShare   = shift;
	my $threadOrder = shift;
	
	# check if thread pool has minimal count of pools
	$self->__FillThreadPool();

	# Wait for an available thread
	my $tid = $self->{"IDLE_QUEUE"}->dequeue();

	# Check for termination condition
	
	print STDERR "\n Thread is about to start ".$threadOrder."\n";
	
	unless(defined $jobStrData  ){
		die "not defined";
	}

	# Pass parameters to prepared thread
	my @ary : shared = ( $jobGUID, $jobStrData, $port, $pcbIdShare, $pidInCAM, $externalServer, $stopVarShare, $threadOrder );

	# my $pom = 1;
	$self->{"work_queues"}->{$tid}->enqueue( \@ary );

	return $tid;
}

# This method is called, when new thread starts
# Raise Event, whoch handler should contain "working code"
sub __WorkerMethod {
	my $self           = shift;
	my $jobGUID        = shift;
	my $jobStrData     = shift;
	my $inCAM          = shift;
	my $pcbIdShare     = shift;
	my $pidInCAM       = shift;
	my $externalServer = shift;
	my $stopVarShare   = shift;
	my $threadOrder = shift;

	my $onThreadWorker = $self->{'onThreadWorker'};
	if ( $onThreadWorker->Handlers() ) {
		$onThreadWorker->Do( $pcbIdShare, $jobGUID, $jobStrData, $inCAM, \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT, $stopVarShare, $threadOrder );
	}

	print STDERR "\n thread task end PCBid: $$pcbIdShare \n";

	$self->__CleanUpAndExit( $inCAM, $jobGUID, $pcbIdShare, Enums->ExitType_SUCCES );

}

# Pool thread metohod, where is infinit loop and wait for work (new task)
sub __PoolWorker {
	my $self = shift;
	my ($work_q) = @_;

	# This thread's ID
	my $tid = threads->tid();
 
#	if ( AppConf->GetValue("logingType") == 2 ) {
#
#		HelperAbstrQ->Logging("TaskThreads", "LogThread_$tid" );
#	}

	# Work loop
	do {

		# Indicate that were are ready to do work
		$self->{"IDLE_QUEUE"}->enqueue($tid);

		# Wait for work from the queue
		my $work = $work_q->dequeue();

		# If no more work, exit
		#last if ($work < 0);

		# Do some work while monitoring $TERM

		#sleep(5);

		my $jobGUID        = $work->[0];
		my $jobStrData     = $work->[1];
		my $port           = $work->[2];
		my $pcbIdShare     = $work->[3];
		my $pidInCAM       = $work->[4];
		my $externalServer = $work->[5];
		my $stop           = $work->[6];
		my $threadOrder = $work->[7];

		print STDERR "\n Thread pool start PCB: $$pcbIdShare order $threadOrder \n";

		# TODO odkomentovat
		my $inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );

		#my $inCAM = InCAM->new();
		#$inCAM->StarLog( $pidInCAM, $pcbIdShare );

		#my $inCAM = undef;
		my $pidServer = $inCAM->ServerReady();
		unless($pidServer){
			die "Server on port $port is not ready. Fail when test server is ready";
		}

		$SIG{'KILL'} = sub {

			$self->__CleanUpAndExit( $inCAM, $jobGUID, $pcbIdShare, Enums->ExitType_FORCE, $externalServer );

			exit;    #exit only this child thread

		};

		$self->__WorkerMethod( $jobGUID, $jobStrData, $inCAM, $pcbIdShare, $pidInCAM, $externalServer, $stop, $threadOrder);

		# Loop back to idle state if not told to terminate
	} while (1);

}

sub __CleanUpAndExit {
	my ( $selfMain, $inCAM, $jobGUID, $pcbIdShare, $exitType, $externalServer ) = @_;

	# If user aborted job and it is "asynchronous" task (not external server prepared)
	# Close job
	if ( $exitType eq Enums->ExitType_FORCE && !$externalServer ) {

		# Reconnection is necessary because, when is child therad aborted force
		# inCam library is confused and return odd replies

		$inCAM->Reconnect();

		# Test if specific job is still open, is so, close
		$inCAM->COM( "is_job_open", "job" => $$pcbIdShare );

		if ( $inCAM->GetReply() eq "yes" ) {

			$inCAM->COM( "check_inout", "job" => $$pcbIdShare, "mode" => "in", "ent_type" => "job" );
			$inCAM->COM( "close_job", "job" => $$pcbIdShare );
			print STDERR "\n\n\nJOBCLOSED when aborting SUER\n\n\n\n";
		}
	}

	$inCAM->ClientFinish();

	my %resExit : shared = ();
	$resExit{"jobGUID"}  = $jobGUID;
	$resExit{"thrId"}    = threads->tid();
	$resExit{"exitType"} = $exitType;

	my $threvent2 = new Wx::PlThreadEvent( -1, $THREAD_END_EVT, \%resExit );
	Wx::PostEvent( $selfMain->{"abstractQueueFrm"}, $threvent2 );

}

sub __ThreadEnded {
	my ( $self, $jobGUID, $exitType ) = @_;

	for ( my $i = 0 ; $i < scalar( @{ $self->{"threadTasks"} } ) ; $i++ ) {
		if ( @{ $self->{"threadTasks"} }[$i]->{"jobGUID"} eq $jobGUID ) {

			splice @{ $self->{"threadTasks"} }, $i, 1;    #delete thread from list

			my %res : shared = ();
			$res{"jobGUID"}  = $jobGUID;
			$res{"exitType"} = $exitType;

			my $threvent = new Wx::PlThreadEvent( -1, $THREAD_DONE_EVT, \%res );
			Wx::PostEvent( $self->{"abstractQueueFrm"}, $threvent );

			last;
		}
	}
}

sub __ThreadEndedHandler {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	$self->__ThreadEnded( $d{"jobGUID"}, $d{"exitType"} );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = MyApp2->new();

	#$app->Test();

	#$app->MainLoop;

}

1;

