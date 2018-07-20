
#-------------------------------------------------------------------------------------------#
# Description: Class allow do asynchrounous operation together using WX widgets
# Class allow more asynchrounous operation in the same time
# Class solve dissconecting inCAM library in main thread, connecting in Child thread + reconnect in mian thread
# See ussage of this class e.g.: Programs::Coupon::CpnWizard::WizardCore::WizardStep3
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::WxAsyncWorker::WxAsyncWorker;

#3th party library
use threads;
use threads::shared;
use Wx;
use strict;
use warnings;
use Thread::Queue;
use Sub::Identify ':all';

#local library
use aliased "Helpers::GeneralHelper";
use aliased 'Packages::InCAM::InCAM';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
my $PROCESS_END_EVT : shared;    # evt raise when processing reorder is done

# Classs work default with two threads in queue.
# It means max 2 asynchrounos operation can run in same time
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"wxFrame"} = shift;             # Reference on top level wxFrame
	$self->{"MAX_THREADS"} = shift // 2;    # Max num of operation in same time

	$self->{"callbacks"} = {};
	$self->{"inCAMs"}    = {};

	$self->__InitThreadPool();

	$PROCESS_END_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"wxFrame"}, -1, $PROCESS_END_EVT, sub { $self->__CallBackWrapper(@_) } );

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

sub Run {
	my $self = shift;

	# function reference on worker method
	# Return variable should be shared: scalar, hash, array. This variable is passed to callbackMethod as first argument
	my $workerMethod = shift;

	# function reference on which is called after worker method is done
	my $callbackMethod = shift;

	# input parameters in array ref for worker method.
	#(parameters can be only scalar, array, hash. No other types are supported)
	my $workerParams = shift;

	# if inCAM is passed, connected inCAM will be passed as first argument in worker
	# method (inCAM need to disconect in main thread and connect in child thread)
	my $inCAM = shift;
	

	my $workerId = GeneralHelper->GetGUID();

	$self->{"callbacks"}->{$workerId} = $callbackMethod;

	if ($inCAM) {
		$self->{"inCAMs"}->{$workerId} = $inCAM;
		$inCAM->ClientFinish();

	}

	# Wait for an available thread
	my $tid = $self->{"IDLE_QUEUE"}->dequeue();

	# run thread

	my $wmFullName = sub_fullname($workerMethod);

	my @ary = ( $workerId, ( defined $inCAM ? $inCAM->GetPort() : 0 ), $wmFullName, $workerParams );

	$self->{"work_queues"}->{$tid}->enqueue( \@ary );

}

# ================================================================================
# Private methods
# ================================================================================

sub __WorkerWrapper {
	my $self       = shift;
	my $work_q     = shift;
	my $lastLaunch = shift;

	# This thread's ID
	my $tid = threads->tid();

	# Work loop
	do {

		# Indicate that were are ready to do work

		$self->{"IDLE_QUEUE"}->enqueue($tid);

		# Wait for work from the queue
		my $workParams = $work_q->dequeue();

		# Do work
		my $workerId     = $workParams->[0];
		my $inCAMPort    = $workParams->[1];
		my $workerMethod = $workParams->[2];
		my $params       = $workParams->[3];

		my @paramsWorker = @{$params};

		my $inCAM = undef;
		if ( $inCAMPort != 0 ) {
			$inCAM = InCAM->new( "remote" => 'localhost', "port" => $inCAMPort );
			$inCAM->ServerReady();

			unshift @paramsWorker, $inCAM;
		}

		my $resultData : shared;
		eval {

			my ( $package, $func ) = $workerMethod =~ /^(.*)::(.*)$/;

			$resultData = $package->$func(@paramsWorker);
		};
		if ($@) {

			print STDERR "Unexpected error: " . $@;
		}

		if ( $inCAMPort != 0 ) {
			$inCAM->ClientFinish();
		}

		my %resultDataWrapper : shared = ();
		$resultDataWrapper{"callbackKey"} = $workerId;
		$resultDataWrapper{"data"}        = $resultData;

		my $threvent = new Wx::PlThreadEvent( -1, $PROCESS_END_EVT, \%resultDataWrapper );
		Wx::PostEvent( $self->{"wxFrame"}, $threvent );

		# Loop back to idle state if not told to terminate
	} while (1);
}

sub __CallBackWrapper {
	my $self  = shift;
	my $frame = shift;
	my $event = shift;

	my $resultDataWrapper = $event->GetData();

	my $callBackMethod = $self->{"callbacks"}->{ $resultDataWrapper->{"callbackKey"} };

	if ( $self->{"inCAMs"}->{ $resultDataWrapper->{"callbackKey"} } ) {

		my $inCAM = $self->{"inCAMs"}->{ $resultDataWrapper->{"callbackKey"} };

		$inCAM->Reconnect();
	}

	delete $self->{"callbacks"}->{ $resultDataWrapper->{"callbackKey"} };
	delete $self->{"inCAMs"}->{ $resultDataWrapper->{"callbackKey"} };

	$callBackMethod->( $resultDataWrapper->{"data"} );

}

#-------------------------------------------------------------------------------------------#
#  Thread queue methods
#-------------------------------------------------------------------------------------------#

sub __InitThreadPool {
	my $self = shift;

	# Threads add their ID to this queue when they are ready for work
	# Also, when app terminates a -1 is added to this queue
	$self->{"IDLE_QUEUE"} = Thread::Queue->new();

	# Thread work queues referenced by thread ID
	my %work_queues;
	$self->{"work_queues"} = \%work_queues;

	# Create the thread pool
	for ( 1 .. $self->{"MAX_THREADS"} ) {

		$self->__AddThreadPool();

	}
}

sub __AddThreadPool {
	my $self = shift;

	# Create a work queue for a thread
	my $work_q = Thread::Queue->new();

	# Create the thread, and give it the work queue
	my $thr = threads->create( sub { $self->__WorkerWrapper( $work_q, \$self->{"lastLaunch"} ) } );
	$thr->set_thread_exit_only(1);

	# Remember the thread's work queue
	$self->{"work_queues"}->{ $thr->tid() } = $work_q;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

