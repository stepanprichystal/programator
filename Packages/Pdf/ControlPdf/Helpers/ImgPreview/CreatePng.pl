
#-------------------------------------------------------------------------------------------#
# Description: Script convert pdf to png. Each conversion run in
# own thread. Conversion is done by imageMagick program launched by system()
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use threads;
use strict;
use warnings;
use Time::HiRes;
use Thread::Queue;


#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#use local library;
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

my $output = shift(@_);    # save here output message
my $cmds   = shift(@_);    # contain commands, which convert pdfs to images by imageMagick

unless ($cmds) {
	die "Parameter cmd is not defined.\n";
}
 

my $MAX_THREADS = 6; # max 3x convert.exe is running
 

# Threads add their ID to this queue when they are ready for work
# Also, when app terminates a -1 is added to this queue
my $IDLE_QUEUE = Thread::Queue->new();

# Thread work queues referenced by thread ID
my %work_queues;
my @threads = ();

# Create the thread pool
for ( 1 .. $MAX_THREADS ) {

	# Create a work queue for a thread
	my $work_q = Thread::Queue->new();

	# Create the thread, and give it the work queue
	my $thr = threads->create( sub { __Worker($work_q) } );
	#$thr->set_thread_exit_only(1);
	$thr->detach();
	push(@threads, $thr);

	# Remember the thread's work queue
	$work_queues{ $thr->tid() } = $work_q;
}

foreach my $cmd ( @{$cmds} ) {

	# Wait for an available thread
	my $tid = $IDLE_QUEUE->dequeue();

	# run thread
	
	my @ary : shared = ($cmd);
	$work_queues{$tid}->enqueue( \@ary );
}



while(1){
	
	my  $emptyQueue = 0;
	foreach my $k (keys %work_queues){
	
		unless($work_queues{$k}->pending()){
			
			$emptyQueue++;
		}
		sleep(0.5);
	}
	
	if($emptyQueue == $MAX_THREADS && $IDLE_QUEUE->pending() ==$MAX_THREADS ){
		last;
	}
}
 

sub __Worker {
	my $work_q = shift;

	# This thread's ID
	my $tid = threads->tid();

	# Work loop
	do {

		# Indicate that were are ready to do work

		$IDLE_QUEUE->enqueue($tid);

		# Wait for work from the queue
		my $work = $work_q->dequeue();

		# Do work
		 
		my $cmd = $work->[0];
		__ConvertToPng($cmd);
		# Loop back to idle state if not told to terminate
	} while (1);
}

sub __ConvertToPng {

	my $cmd = shift;
	
	print STDERR "run thread $cmd\n";

	my @args = ($cmd);

	#print 'c:\\Program Files\\ImageMagick\\convert.exe'. " ".$cmd;
	#
	#	my $systeMres = system('c:\Program Files\ImageMagick\convert.exe'. " ".$cmd);
	my $systeMres = system($cmd);

}

1;
