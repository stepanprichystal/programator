use strict;
use warnings;
use threads;
use Thread::Queue;
my $q = Thread::Queue->new();    # A new empty queue
                                 # Worker thread
my $thr = threads->create(
	sub {
		# Thread will loop until no more work
		while (1){
		 my $item = $q->dequeue();
			                                               # Do work on $item
			 sleep(1);
			 print $item;
			 
		}
	}
);

my $item = 10;

# Send work to the thread
$q->enqueue($item, 2, 3, 4, 5);

sleep (2);

$q->enqueue(6, 7, 8, 9, 10);

sleep (10);

# Signal that there is no more work to be sent
$q->end();
