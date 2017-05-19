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


#use lib qw( y:\server\site_data\scripts );
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Services::LogService::MailSender::MailSender';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Other::AppConf';
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Programs::Services::Helper';
use aliased 'Packages::InCAMCall::InCAMCall';
use aliased 'Enums::EnumsPaths';

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
 

our $configPath = GeneralHelper->Root() . "\\Programs\\Services\\TpvService\\Config";

Helper->SetLogging(AppConf->GetValue("logFilePath"), 2);

# Start the service passing in a context and
# indicating to callback using the "Running" event
# every 2000 milliseconds (10 seconds).
Win32::Daemon::StartService( \%Context, 2000 );

# Now let the service manager know that we are running...
#Win32::Daemon::State( SERVICE_RUNNING );

sub WorkerMethod {
	my $Context = shift;

	my $logger = get_logger("serviceLog");
	 
	my $paskageName = "Packages::InCAMCall::Example";
	my @par1        = ( "k" => "1" );
	my %par2      = ( "par1", "par2" );
	

	$logger->debug("test 1\n");

	my $inCAMPath = GeneralHelper->GetLastInCAMVersion();
	$inCAMPath .= "bin\\InCAM.exe";

	unless ( -f $inCAMPath )    # does it exist?
	{
		die "InCAM does not exist on path: " . $inCAMPath;
	}

 	my $fIndicator = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
 
 
 	my $script = 'c:\Perl\site\lib\TpvScripts\Scripts\pom5.pl';
 
 

	 my $cmd = "InCAM.exe -x -s".$script;
 
 
	# $logger->debug("test 1 $inCAMPath $cmd \n");
	#use Config;
	#my $perl = $Config{perlpath};
 
 	#$inCAMPath = 'c:\opt\InCAM\3.01SP1\bin\InCAM.exe';
 	use Win32::Process;
	my $processObj;
	Win32::Process::Create( $processObj, $inCAMPath, $cmd, 0, THREAD_PRIORITY_NORMAL  , "." )
	  || die " run process $!\n";

	#my $pidInCAM = $processObj->GetProcessID();

	#$processObj->Wait(INFINITE);
	
	#my $cmd = "$inCAMPath -x -s" . $script;
	#system($cmd);
	
	$logger->debug("Odpoved y incam: ");
	 

}

sub Callback_Running {
	my ( $Event, $Context ) = @_;

	my $logger = get_logger("serviceLog");
	print STDERR "ddd";

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
	if ( SERVICE_RUNNING == Win32::Daemon::State() ) {

		$logger->info("Tpv service start");

		#while (1) {

		if ( Win32::Daemon::QueryLastMessage() eq SERVICE_CONTROL_STOP ) {

			# Tell the SCM to stop this service.
			Win32::Daemon::StopService();
			Win32::Daemon::State(SERVICE_STOPPED);

			last;
		}

		eval {

			WorkerMethod($Context);

		};
		if ($@) {

			$logger->error($@);
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



1;
