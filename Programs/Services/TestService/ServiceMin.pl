#-------------------------------------------------------------------------------------------#
# Description: Simple Win service, responsible for checking error log DB and processing
# new logs
# Author:SPR
#-------------------------------------------------------------------------------------------#

use Win32::Daemon;

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);
use Try::Tiny;

use lib qw( \\\\incam\\InCAM\\server\\site_data\\scripts);
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );



#use aliased 'Programs::Services::LogService::MailSender::MailSender';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
#use aliased 'Packages::Other::AppConf';
#use aliased 'Connectors::TpvConnector::TpvMethods';
#use aliased 'Programs::Services::Helper';

Win32::Daemon::RegisterCallbacks(
	{
	   start   => \&Callback_Start,
	   timer => \&Callback_Timer,
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
__SetLogging();

# Start the service passing in a context and
# indicating to callback using the "Running" event
# every 2000 milliseconds (10 seconds).
Win32::Daemon::StartService( \%Context, 2000 );

# Now let the service manager know that we are running...
#Win32::Daemon::State( SERVICE_RUNNING );

sub Callback_Timer {
	my ( $ControlMessage, $Context ) = @_;

	my $logger = get_logger("service");

	$logger->debug("Serivce start");

	# reduce log file
	#my $pathstd = AppConf->GetValue("logFilePath") . "\\LogOut.txt";

	#get file attributes
	#		my @stats = stat($pathstd);
	#
	#		print @stats;
	#		print STDERR "\nVelikost je ".$stats[7]." \n";
	#
	#		# if file is bigger than 10 mb, delete
	#		if ( $stats[7] > 1000 ) {
	#			#close($OLDOUT);
	#			#close($OLDERR);
	#			#unlink $pathstd;
	#		}

	# Note that here you want to check that the state
	# is indeed SERVICE_RUNNING. Even though the Running
	# callback is called it could have done so before
	# calling the "Start" callback.
	if ( SERVICE_CONTROL_TIMER == $ControlMessage ) {

		#while (1) {

		if ( Win32::Daemon::QueryLastMessage() eq SERVICE_CONTROL_STOP ) {

			# Tell the SCM to stop this service.
			Win32::Daemon::StopService();
			Win32::Daemon::State(SERVICE_STOPPED);
			$logger->debug("Serivce stopped");

			last;
		}

		eval {

			$logger->debug("Serivce work");
			
			 $logger->debug("Y server disc path: ".EnumsPaths->InCAM_serverDisc);

#			if ( -t STDIN && -t STDOUT ) {
#				$logger->debug("Interaktive service ");
#			}
			
			 

		};
		if ($@) {

			Win32::Daemon::State(SERVICE_RUNNING);

		}

		#sleep(5);

		#}

	}

}

sub Callback_Start {
	my ( $Event, $Context ) = @_;

	# Initialization code
	# ...do whatever you need to do to start...

	$Context->{last_state} = SERVICE_RUNNING;
	Win32::Daemon::State(SERVICE_RUNNING);
}

sub Callback_Stop {
	my ( $Event, $Context ) = @_;
	$Context->{last_state} = SERVICE_STOPPED;

	Win32::Daemon::State(SERVICE_STOPPED);

	# We need to notify the Daemon that we want to stop callbacks and the service.
	Win32::Daemon::StopService();
}

sub __SetLogging {
	my $self = shift;

	# 1) Create dir
	my $logDirService = 'c:\tmp\InCam\scripts\logs\testService';
	unless ( -e $logDirService ) {
		mkdir($logDirService) or die "Can't create dir: " . $logDirService . $_;
	}

	Log::Log4perl->init( GeneralHelper->Root() . "\\Programs\\Services\\TestService\\Logger.conf" );

}

1;
