use Win32::Daemon;

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);

#use lib qw( y:\server\site_data\scripts );
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
 

use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Other::AppConf';
 

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

# Load configration file
our $configPath = GeneralHelper->Root() . "\\Programs\\LogService\\Config";
__SetLogging();


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
	my $Context = shift;

	#my $logger = get_logger();
	
	#$logger->info("worketr method");


	if ( open( my $f, ">>", "c:\\Export\\service.txt" ) ) {

		print $f "Record: " . $Context->{"start_time"} . "\n";

		close($f);
	}

}

sub Callback_Running {
	my ( $Event, $Context ) = @_;
	
	my $logger = get_logger();
	
	 


	# Note that here you want to check that the state
	# is indeed SERVICE_RUNNING. Even though the Running
	# callback is called it could have done so before
	# calling the "Start" callback.
	if ( SERVICE_RUNNING == Win32::Daemon::State() ) {
		
		$logger->info("Loging mail service start");

		eval {

			while (1) {
				
				$logger->info("Loging mail start process logs.");
 
				WorkerMethod($Context);

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

				sleep(5);

			}

		};
		if ($@) {
			
			$logger->error($@);

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

sub __SetLogging {
 
	my $path = AppConf->GetValue("logFilePath");
 
	unless ( -e $path ) {
		mkdir($path) or die "Can't create dir: " . $path . $_;
	}

	$path = $path . "\\log.txt";
	
	my $mainLogger = get_logger();
	$mainLogger->level($DEBUG);

	# Appenders
	my $appenderFile = Log::Log4perl::Appender->new(
												 'Log::Log4perl::Appender::File::FixedSize',
												 filename => $path,
												 mode     => "append",
												 size     => '10Mb');

	my $appenderScreen = Log::Log4perl::Appender->new(
													   'Log::Dispatch::Screen',
													   min_level => 'debug',
													   stderr    => 1,
													   newline   => 1
	);

	my $layout = Log::Log4perl::Layout::PatternLayout->new("%d %p> %F{1}:%L  %M \n- %m%n \n");
	$appenderFile->layout($layout);
	$appenderScreen->layout($layout);

	$mainLogger->add_appender($appenderFile);
	$mainLogger->add_appender($appenderScreen);
	
	$mainLogger->info("test");
 

}
