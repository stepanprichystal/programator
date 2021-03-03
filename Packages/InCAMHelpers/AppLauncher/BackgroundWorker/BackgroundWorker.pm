
#-------------------------------------------------------------------------------------------#
# Description: Manager for threads. Keep list of running threads
# Responsilbe for start new, force kill etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::BackgroundWorker::BackgroundWorker;

#3th party library
use threads;
use threads::shared;
use Wx;
use strict;
use warnings;
use Time::HiRes qw (sleep);
use Thread::Queue;
use Log::Log4perl qw(get_logger :easy);
use JSON::XS;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Packages::InCAM::InCAM';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
Log::Log4perl->easy_init($DEBUG);

# General events raised during thread rowkring
my $THREAD_GENERAL_EVT : shared;

# Thread event types
use constant ThrEvt_START        => "thrStartEvt";
use constant ThrEvt_FINISH       => "thrFinishEvt";
use constant ThrEvt_END          => "thrEndEvt";
use constant ThrEvt_MESSAGEINFO  => "thrMessageInfoEvtEvt";
use constant ThrEvt_PROGRESSINFO => "thrProgressInfoEvt";

# Task execution type
use constant Task_SERIAL   => "serial";
use constant Task_PARALLEL => "parallel";

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	# PROPERTIES

	$self->{"appMainFrm"}     = undef;    # reference to main app frame (need for raise events)
	$self->{"inCAM"}          = undef;    # inCAM is repeatedlz disconecting/reconnectin during child thread working
	$self->{"inCAMPort"}      = undef;
	$self->{"asyncWorkerSub"} = undef;    # worker subroutine which is called for newt  task
	$self->{"MAX_THREADS"}    = 0;        # maximal cnt of thread queue
	$self->{"MIN_THREADS"}    = 0;        # minimal cnt of thread queue

	my @threadTasks = ();
	$self->{"threadTasks"} = \@threadTasks;    # for each task is created ifno hash
	$self->{"thrTaskCnt"}  = 0;

	$self->{"InCAMAppReConnecting"} = 0;       # if 1, do not add new task, because InCAM app reconnect to server

	$self->{"loger"} = undef;

	$self->{"json"} = JSON::XS->new->ascii->pretty->allow_nonref;
	$self->{"json"}->convert_blessed( [1] );

	# EVENTS

	$self->{"thrStartEvt"}       = Event->new();    # thread start
	$self->{"thrFinishEvt"}      = Event->new();    # thread finished properly
	$self->{"thrEndEvt"}         = Event->new();    # thread finished uncomplete, before reach end
	$self->{"thrPogressInfoEvt"} = Event->new();    # percentage of thread progress
	$self->{"thrMessageInfoEvt"} = Event->new();    # general message from thread

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
	$self->{"appMainFrm"}     = shift;                                  # app main frame
	$self->{"inCAM"}          = shift;                                  # InCAM reference
	$self->{"asyncWorkerSub"} = shift;                                  # worker subroutine which is called for newt  task
	$self->{"MAX_THREADS"}    = shift // 1;
	$self->{"MIN_THREADS"}    = shift // 1;
	$self->{"loger"}          = shift // Log::Log4perl->get_logger();

	die "MAX_THREADS value must be greater than MIN_THREADS" if ( $self->{"MIN_THREADS"} > $self->{"MAX_THREADS"} );
	die "MAX_THREADS value must be greater than 0" if ( $self->{"MAX_THREADS"} < 1 );

	$self->{"inCAMPort"} = $self->{"inCAM"}->GetPort();

	$THREAD_GENERAL_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"appMainFrm"}, -1, $THREAD_GENERAL_EVT, sub { $self->__OnThreadGeneralHndl(@_) } );

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

# Add new asynchronouse task
# All tasks added by this method will be executed one by one in one child thread
sub AddTaskSerial {
	my $self       = shift;
	my $taskId     = shift;
	my $taskParams = shift // [];    # array of parameters which will be serialized to JSON

		# If app InCAM library is trying to recconect, wait to prevent inCAM connect collision
		# (only oneInCAM library can by connected to server in same time)
		print STDERR "\n---------------TEST BEFORE----------------\n";
	
		while ( $self->{"InCAMAppReConnecting"} ) {
	
			print STDERR "\n...reconnecting...\n";
			sleep(1);
		}
	
		print STDERR "\n---------------TEST AFTER----------------\n";

	my $thrId = $self->__AddNewTask( Task_SERIAL, $taskId, $taskParams );

	my %thrTaskInf = (
		"taskId" => $taskId,
		"thrId"  => $thrId,    # id of thread, where is task processed

	);

	push( @{ $self->{"threadTasks"} }, \%thrTaskInf );

}

# Add new asynchronouse task
# All tasks added by this method will be executed parallely in more than one child thread
sub AddTaskParallel {
	my $self       = shift;
	my $taskId     = shift;
	my $taskParams = shift // [];    # array of parameters which will be serialized to JSON

	# If app InCAM library is trying to recconect, wait to prevent inCAM connect collision
	# (only oneInCAM library can by connected to server in same time)
	while ( $self->{"InCAMAppReConnecting"} ) {

		sleep(1);
	}

	my $thrId = $self->__AddNewTask( Task_PARALLEL, $taskId, $taskParams );

	my %thrTaskInf = (
		"taskId" => $taskId,
		"thrId"  => $thrId,    # id of thread, where is task processed

	);

	push( @{ $self->{"threadTasks"} }, \%thrTaskInf );

}

# Process request for force exit of thread
# Responsible for proper aborting
sub EndTask {
	my $self   = shift;
	my $taskId = shift;

	my $thr = ( grep { $_->{"taskId"} eq $taskId } @{ $self->{"threadTasks"} } )[0];

	if ( defined $thr ) {

		#print $thr->{"thrId"};

		my $thrObj = threads->object( $thr->{"thrId"} );

		if ( defined $thrObj ) {

			my $thrId = $thrObj->tid();

			if ( $thrObj->is_running() ) {

				#$thrObj->detach();

				$thrObj->kill('KILL');

				$self->{"loger"}->debug( "Thread:   port:" . $thr->{"port"} . "...........................try to end thread" );

			}
			else {

				#In case, thread already finished
				# This can happend in time, when user abort thread when was running, or thread broke down
				# But in time of this place, thread is alreadz finished
				for ( my $i = 0 ; $i < scalar( @{ $self->{"threadTasks"} } ) ; $i++ ) {
					if ( @{ $self->{"threadTasks"} }[$i]->{"taskId"} eq $taskId ) {

						splice @{ $self->{"threadTasks"} }, $i, 1;    #delete thread from list
						my %evtData : shared = ();
						$evtData{"evtType"} = ThrEvt_END;
						$evtData{"taskId"}  = $taskId;
						Wx::PostEvent( $self->{"appMainFrm"}, new Wx::PlThreadEvent( -1, $THREAD_GENERAL_EVT, \%evtData ) );

						last;
					}
				}
			}

			return 1;
		}

		return 0;

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

sub __UpdateThreadPool {
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

	for ( my $i = 0 ; $i < ( $self->{"MIN_THREADS"} - $threadPoolCnt ) ; $i++ ) {

		$self->{"loger"}->debug("Add new thread pool. TOtal cnt: $threadPoolCnt.");
		$self->__AddThreadPool();
	}
}

sub __AddNewTask {
	my $self       = shift;
	my $taskType   = shift;          # serial/parallel
	my $taskId     = shift;
	my $taskParams = shift // [];    # array of parameters which will be serialized to JSON

	die "Unique task id is not defined" unless ( defined $taskId );

	# 1) heck if thread pool has minimal count of pools
	$self->__UpdateThreadPool();

	# 2) Wait for an available thread
	my $tid;

	if ( $taskType eq Task_SERIAL ) {

		# Always use first thread (queue) and execute all task in it

		$tid = ( sort { $a <=> $b } keys %{ $self->{"work_queues"} } )[0];

	}
	elsif ( $taskType eq Task_PARALLEL ) {

		# Always use first AVAILABLE thread (queue). There must be more than one thread to execute task parallel
		my @thredCnt = scalar( keys %{ $self->{"work_queues"} } );

		die "Threads number must be >= 2 if parallel task execution is requested" if ( scalar(@thredCnt) < 2 );

		# Wait for random available thread
		# No free thread? Do not block and choose random

		$tid = $self->{"IDLE_QUEUE"}->dequeue_nb();
		if ( !defined $tid ) {

			$tid = ( sort { $a <=> $b } keys %{ $self->{"work_queues"} } )[0];
		}

	}

	#	my $tid = $self->{"IDLE_QUEUE"}->dequeue_nb();
	#	$tid = 1;

	# 3) Check for termination condition
	$self->{"loger"}->debug( "Thread is about to start  taskId: " . $taskId );

	# Disconnect InCAM library from InCAM server before start working function
	$self->{"inCAM"}->ClientFinish() if ( $self->{"inCAM"}->IsConnected() );

	# Pass parameters to prepared thread (task id + serialized params)
	my $taskParamsJSON = $self->{"json"}->pretty->encode($taskParams);

	my @ary : shared = ( $taskId, $taskParamsJSON );

	print STDERR "TID:$tid,  workQueue: " . join( ";", map { $self->{"work_queues"}->{$_} } keys %{ $self->{"work_queues"} } ) . "\n";
	$self->{"work_queues"}->{$tid}->enqueue( \@ary );

	return $tid;
}

# This function is called, when new thread starts
# Raise Event, whoch handler should contain "working code"
# Note: Function is executed in child thread
sub __WorkerMethod {
	my $self           = shift;
	my $taskId         = shift;
	my $taskParamsJSON = shift;
	my $inCAMWorker    = shift;

	# Rise stardt event

	my $taskParams = $self->{"json"}->decode($taskParamsJSON);

	my $thrPogressInfoEvtEvt = Event->new();    # percentage of thread progress
	my $thrMessageInfoEvtEvt = Event->new();    # general message from thread

	$thrPogressInfoEvtEvt->Add(
		sub {

			my $taskId   = shift;
			my $progress = shift;

			my %res : shared = ();
			$res{"evtType"} = ThrEvt_PROGRESSINFO;
			$res{"taskId"}  = $taskId;
			$res{"data"}    = $progress;

			my $threvent = new Wx::PlThreadEvent( -1, $THREAD_GENERAL_EVT, \%res );
			Wx::PostEvent( $self->{"appMainFrm"}, $threvent );

		}
	);

	$thrMessageInfoEvtEvt->Add(
		sub {

			my $taskId = shift;
			my $mess   = shift;

			my %res : shared = ();
			$res{"evtType"} = ThrEvt_MESSAGEINFO;
			$res{"taskId"}  = $taskId;
			$res{"data"}    = $mess;

			my $threvent = new Wx::PlThreadEvent( -1, $THREAD_GENERAL_EVT, \%res );
			Wx::PostEvent( $self->{"appMainFrm"}, $threvent );

		}
	);

	$self->{"asyncWorkerSub"}->( $taskId, $taskParams, $inCAMWorker, $thrPogressInfoEvtEvt, $thrMessageInfoEvtEvt );

	$self->{"loger"}->debug("thread task end   taskId: $taskId");

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

		# Get parameters
		my $taskId         = $work->[0];
		my $taskParamsJSON = $work->[1];

		my $inCAMWorker = undef;

		$SIG{'KILL'} = sub {

			$inCAMWorker->ClientFinish() if ( defined $inCAMWorker );

			my %evtData : shared = ();
			$evtData{"evtType"} = ThrEvt_END;
			$evtData{"taskId"}  = $taskId;
			Wx::PostEvent( $self->{"appMainFrm"}, new Wx::PlThreadEvent( -1, $THREAD_GENERAL_EVT, \%evtData ) );

			exit;    #exit only this child thread
		};

		eval {

			$self->{"loger"}->debug("In thread, taskId: $taskId ");

			# Raise start task event
			my %evtData : shared = ();
			$evtData{"evtType"} = ThrEvt_START;
			$evtData{"taskId"}  = $taskId;
			Wx::PostEvent( $self->{"appMainFrm"}, new Wx::PlThreadEvent( -1, $THREAD_GENERAL_EVT, \%evtData ) );
			print STDERR "test 1\n";

			my $connected = 0;
			while ( !$connected ) {

				print STDERR "test 10\n";

				# Connect InCAM library from child thread to server
				$inCAMWorker = InCAM->new( "remote" => 'localhost', "port" => $self->{"inCAMPort"} );

				my $pidServer = $inCAMWorker->ServerReady();
				if ($pidServer) {

					last;
				}
				else {
					sleep(1);
				}
			}

			print STDERR "test 2\n";

			# Process working function
			$self->__WorkerMethod( $taskId, $taskParamsJSON, $inCAMWorker );

			print STDERR "test 3\n";

			# dissconect InCAM library, in order another task in row or main app can connect
			$inCAMWorker->ClientFinish();

			# Raise finish task event
			my %evtData2 : shared = ();
			$evtData2{"evtType"} = ThrEvt_FINISH;
			$evtData2{"taskId"}  = $taskId;
			Wx::PostEvent( $self->{"appMainFrm"}, new Wx::PlThreadEvent( -1, $THREAD_GENERAL_EVT, \%evtData2 ) );

		};
		if ( my $e = $@ ) {

			$inCAMWorker->ClientFinish() if ( defined $inCAMWorker );

			my %evtData : shared = ();
			$evtData{"evtType"} = ThrEvt_END;
			$evtData{"taskId"}  = $taskId;
			$evtData{"data"}    = $e;
			Wx::PostEvent( $self->{"appMainFrm"}, new Wx::PlThreadEvent( -1, $THREAD_GENERAL_EVT, \%evtData ) );

		}

		# Loop back to idle state if not told to terminate
	} while (1);

}

# Receive all events and raise more specific events, by event type
sub __OnThreadGeneralHndl {
	my ( $self, $frame, $event ) = @_;

	my %d = %{ $event->GetData };

	my $evtType = $d{"evtType"};
	my $taskId  = $d{"taskId"};

	$self->{"loger"}->debug("Receive message event task id $taskId, event type: $evtType");

	# Check if all worker queue are empty and we can reconnect app InCAM library

	if ( ( $evtType eq ThrEvt_FINISH || $evtType eq ThrEvt_END ) && !$self->{"InCAMAppReConnecting"} ) {

		$self->{"InCAMAppReConnecting"} = 1;

		my $activeTaskCnt = 0;
		foreach my $thrId ( keys %{ $self->{"work_queues"} } ) {

			my $workQueue      = $self->{"work_queues"}->{$thrId};
			my $pendingTaskCnt = $workQueue->pending();

			$activeTaskCnt += $pendingTaskCnt if ( defined $pendingTaskCnt );
		}

		print STDERR "\ntaskid: $taskId......Reconnect....Active task: $activeTaskCnt..........\n";

		if ( $activeTaskCnt == 0 ) {
 
			$self->{"inCAM"}->Reconnect();

			unless ( $self->{"inCAM"}->ServerReady() ) {
				die "InCAM all library reconnect failed";
			}else{
				
				print STDERR "Reconnect succ";
			}
		}

		$self->{"InCAMAppReConnecting"} = 0;

	}

	if ( $evtType eq ThrEvt_START ) {

		$self->{"thrStartEvt"}->Do($taskId);
	}
	elsif ( $evtType eq ThrEvt_FINISH ) {

		$self->{"thrFinishEvt"}->Do($taskId);
	}
	elsif ( $evtType eq ThrEvt_END ) {

		my $errMess = $d{"data"};

		$self->{"thrEndEvt"}->Do( $taskId, $errMess );
	}
	elsif ( $evtType eq ThrEvt_PROGRESSINFO ) {

		my $progress = $d{"data"};

		$self->{"thrPogressInfoEvt"}->Do( $taskId, $progress );
	}
	elsif ( $evtType eq ThrEvt_MESSAGEINFO ) {

		my $message = $d{"data"};

		$self->{"thrMessageInfoEvt"}->Do( $taskId, $message );
	}

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

