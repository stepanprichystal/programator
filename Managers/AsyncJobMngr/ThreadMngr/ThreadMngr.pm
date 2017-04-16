
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

	my @threads = ();

	$self->{"threads"} = \@threads;
	$self->{"threadCounter"} = 0;

	#raise when new thread start
	$self->{"onThreadWorker"} = Event->new();
	
	
		### Global Variables ###

	

	return $self;
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

sub InitThreadPool{
	my $self = shift;
		
	# Maximum working threads
	$self->{"MAX_THREADS"} = 3;

	# Flag to inform all threads that application is terminating
	$self->{"TERM :shared"} = 0;

	# Threads add their ID to this queue when they are ready for work
	# Also, when app terminates a -1 is added to this queue
	$self->{"IDLE_QUEUE"} = Thread::Queue->new();
	
	
	 # Thread work queues referenced by thread ID
    my %work_queues;
    $self->{"work_queues"} = \%work_queues;

    # Create the thread pool
    for (1..$self->{"MAX_THREADS"}) {
        # Create a work queue for a thread
        my $work_q = Thread::Queue->new();

        # Create the thread, and give it the work queue
        my $thr = threads->create(sub { $self->worker( $work_q)});

        # Remember the thread's work queue
        $work_queues{$thr->tid()} = $work_q;
    }
	
	
}

# Processrequest for starting new thread
sub RunNewtask {
	my $self           = shift;
	my $jobGUID        = shift;
	my $jobStrData 	= shift;
	my $port           = shift;
	my $pcbId          = shift;
	my $pidInCAM       = shift;
	my $externalServer = shift;

	$self->{"threadCounter"} +=1;
	
	print STDERR "\n\n\ntask utility: THERAD ORDER IS :  ".$self->{"threadCounter"}.".\n\n\n";
	
	# special shared variable, which child process periodically read and decide if stop or continue in task
	my $stopped = 0;
	share($stopped);

	my $thrId = $self->__CreateThread( $jobGUID,$jobStrData, $port, $pcbId, $pidInCAM, $externalServer, \$stopped );

	

	my %thrInfo = (
					"jobGUID" => $jobGUID,
					"thrId"   => $thrId,
					"port"    => $port,
					"pcbId"   => $pcbId,
					"stopped" => \$stopped
	);

	push( @{ $self->{"threads"} }, \%thrInfo );

	if ($thrId) {
		return 1;
	}
	else {
		return 0;
	}

}

# Process request for force exit of thread
# Responsible for proper aborting
sub ExitThread {
	my $self    = shift;
	my $jobGUID = shift;

	my $thr = ( grep { $_->{"jobGUID"} eq $jobGUID } @{ $self->{"threads"} } )[0];

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

	my $thr = ( grep { $_->{"jobGUID"} eq $jobGUID } @{ $self->{"threads"} } )[0];

	if ( defined $thr ) {
		
		${$thr->{"stopped"}} = 1;  
	}
}

# Process request for continue thread
# Set special "stop" shared variable, which child process periodically control
sub ContinueThread {
	my $self    = shift;
	my $jobGUID = shift;

	my $thr = ( grep { $_->{"jobGUID"} eq $jobGUID } @{ $self->{"threads"} } )[0];

	if ( defined $thr ) {
		
		${$thr->{"stopped"}} = 0;  
	}
}


sub __CreateThread {
	my $self           = shift;
	my $jobGUID        = shift;
		my $jobStrData 	= shift;
	my $port           = shift;
	my $pcbId          = shift;
	my $pidInCAM       = shift;
	my $externalServer = shift;
	my $stopVar = shift;

	# TODO smazat

	# $self->__WorkerMethod( $jobGUID, $port, $pcbId, $pidInCAM ) ;

	# return $$;
	
	 # Wait for an available thread
     my $tid = $self->{"IDLE_QUEUE"}->dequeue();

      # Check for termination condition
      

      # Give the thread some work to do
      
     # my @ary = ($jobGUID, $port, $pcbId, $pidInCAM, $externalServer);
     my @ary :shared = ($jobGUID, $jobStrData, $port, $pcbId, $pidInCAM, $externalServer, $stopVar);
 	 
    # my $pom = 1;
 	  $self->{"work_queues"}->{$tid}->enqueue(\@ary);
 

	#my $worker = threads->create( sub { $self->__WorkerMethod( $jobGUID, $port, $pcbId, $pidInCAM, $externalServer, $stopVar ) } );
 	
	#$worker->set_thread_exit_only(1);    # tell only this child thread will be exited
	#$worker->detach();

	return $tid;
}

# This method is called, when new thread starts
# Raise Event, whoch handler should contain "working code"
sub __WorkerMethod {
	my $self = shift;

	my $jobGUID        = shift;
	my $jobStrData =  shift;
	my $port           = shift;
	my $pcbId          = shift;
	my $pidInCAM       = shift;
	my $externalServer = shift;
	my $stopVar = shift;
	 

	# TODO odkomentovat
	my $inCAM = InCAM->new( "remote" => 'localhost', "port" => $port );
	#my $inCAM = InCAM->new();
	$inCAM->StarLog( $pidInCAM, $pcbId );

	#my $inCAM = undef;
	$inCAM->ServerReady();

	$SIG{'KILL'} = sub {

		$self->__CleanUpAndExit( $inCAM, $jobGUID, $pcbId, Enums->ExitType_FORCE, $externalServer );

		exit;    #exit only this child thread

	};

	my $onThreadWorker = $self->{'onThreadWorker'};
	if ( $onThreadWorker->Handlers() ) {
		$onThreadWorker->Do( $pcbId, $jobGUID, $jobStrData,  $inCAM, \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT, $stopVar );
	}

	$self->__CleanUpAndExit( $inCAM, $jobGUID, $pcbId, Enums->ExitType_SUCCES );

}



sub worker
{
	my $self = shift;
    my ($work_q) = @_;

    # This thread's ID
    my $tid = threads->tid();

    # Work loop
    do {
        # Indicate that were are ready to do work
        printf("Idle     -> %2d\n", $tid);
        $self->{"IDLE_QUEUE"}->enqueue($tid);

        # Wait for work from the queue
        my $work = $work_q->dequeue();

        # If no more work, exit
        #last if ($work < 0);

        # Do some work while monitoring $TERM
        printf("            %2d <- Working\n", $tid);
        
        #sleep(5);
         
         my $jobGUID = $work->[0];
         my $jobStrData =  $work->[1]; 
         my $port= $work->[2]; 
         my $pcbId= $work->[3]; 
         my $pidInCAM= $work->[4]; 
         my $externalServer= $work->[5];
         my $stop= $work->[6];
      
 
        $self-> __WorkerMethod($jobGUID, $jobStrData, $port, $pcbId, $pidInCAM, $externalServer, $stop);
         

        # Loop back to idle state if not told to terminate
    } while (1);

    # All done
    printf("Finished -> %2d\n", $tid);
}





sub __CleanUpAndExit {
	my ( $selfMain, $inCAM, $jobGUID, $pcbId, $exitType, $externalServer ) = @_;

	# If user aborted job and it is "asynchronous" task (not external server prepared)
	# Close job
	if ( $exitType eq Enums->ExitType_FORCE && !$externalServer ) {
	
		# Reconnection is necessary because, when is child therad aborted force
		# inCam library is confused and return odd replies
		 
		$inCAM->Reconnect();
	 

		# Test if specific job is still open, is so, close
		$inCAM->COM( "is_job_open", "job" => $pcbId );
 
		if ( $inCAM->GetReply() eq "yes" ) {

			$inCAM->COM( "check_inout","job"  => "$pcbId", "mode"  => "in", "ent_type"  => "job");
			$inCAM->COM( "close_job", "job" => $pcbId );
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

	for ( my $i = 0 ; $i < scalar( @{ $self->{"threads"} } ) ; $i++ ) {
		if ( @{ $self->{"threads"} }[$i]->{"jobGUID"} eq $jobGUID ) {

			my $thrObj = threads->object( @{ $self->{"threads"} }[$i]->{"thrId"} );

			if ( defined $thrObj ) {
				print STDERR "\ndetach START\n";
				#$thrObj->detach(); # mozna zpusobuje free wrong pool
				 $thrObj = undef;
				print STDERR "\ndetach\n";
			}

			splice @{ $self->{"threads"} }, $i, 1;    #delete thread from list

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

