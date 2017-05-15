use Win32::Daemon;

Win32::Daemon::RegisterCallbacks(
	{
	   start   => \&Callback_Start,
	   running => \&Callback_Running,
	   stop    => \&Callback_Stop,

	   #pause    => \&Callback_Pause,
	   #continue => \&Callback_Continue,
	}
);
my %Context = (
				last_state => SERVICE_STOPPED,
				start_time => time() / 1000,
);

# Start the service passing in a context and
# indicating to callback using the "Running" event
# every 2000 milliseconds (2 seconds).
Win32::Daemon::StartService( \%Context, 1000 );

# Wait until the service manager is ready for us to continue...
#    while( SERVICE_START_PENDING != Win32::Daemon::State() )
#    {
#        sleep( 1 );
#    }

# Wait until the service manager is ready for us to continue...
#	while ( SERVICE_START_PENDING != Win32::Daemon::State() ) {
#		sleep(1);
#	}

# Now let the service manager know that we are running...
#Win32::Daemon::State( SERVICE_RUNNING );

sub WorkerMethod {

	if ( open( my $f, ">>", "c:\\Export\\service.txt" ) ) {

		print $f "Record: " . $Context->{"start_time"} . "\n";

		close($f);
	}

}

sub Callback_Running {
	my ( $Event, $Context ) = @_;

	# Note that here you want to check that the state
	# is indeed SERVICE_RUNNING. Even though the Running
	# callback is called it could have done so before
	# calling the "Start" callback.
	if ( SERVICE_RUNNING == Win32::Daemon::State() ) {

		eval {

			while (1) {

				WorkerMethod();

				if ( Win32::Daemon::QueryLastMessage() eq SERVICE_CONTROL_STOP ) {

					if ( open( my $f, ">>", "c:\\Export\\service.txt" ) ) {

						print $f "STOP: " . $Context->{"start_time"} . "\n";

						close($f);
					}

					# Tell the SCM to stop this service.
					Win32::Daemon::StopService();
					Win32::Daemon::State(SERVICE_STOPPED);

					last;
				}

				sleep(1);

			}

		};
		if ($@) {

		}
	}

}

sub Callback_Start {
	my ( $Event, $Context ) = @_;

	if ( open( my $f, ">>", "c:\\Export\\service.txt" ) ) {

		print $f "START: " . $Context->{"start_time"} . "\n";

		close($f);
	}

	# Initialization code
	# ...do whatever you need to do to start...

	$Context->{last_state} = SERVICE_RUNNING;
	Win32::Daemon::State(SERVICE_RUNNING);
}

sub Callback_Stop {
	my ( $Event, $Context ) = @_;
	$Context->{last_state} = SERVICE_STOPPED;

	if ( open( my $f, ">>", "c:\\Export\\service.txt" ) ) {

		print $f "STOP callback : " . $Context->{"start_time"} . "\n";

		close($f);
	}

	Win32::Daemon::State(SERVICE_STOPPED);

	# We need to notify the Daemon that we want to stop callbacks and the service.
	Win32::Daemon::StopService();
}

