#-------------------------------------------------------------------------------------------#
# Description: Simple Win service, where are running application
# Like Reorder app, etc,..
# Author:SPR
#-------------------------------------------------------------------------------------------#

use Win32::Daemon;

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);
use Try::Tiny;
use XML::Simple;

use lib qw( \\\\incam\\InCAM\\server\\site_data\\scripts);
#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Programs::Services::LogService::MailSender::MailSender';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Other::AppConf';
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsApp';
use aliased 'Helpers::FileHelper';

# applications
use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorderApp';
use aliased 'Programs::Services::TpvService::ServiceApps::ProcessReorderApp::ProcessReorderApp';
use aliased 'Programs::Services::TpvService::ServiceApps::MdiDataAppOld::MdiDataApp' => 'MdiDataAppOld' ;
use aliased 'Programs::Services::TpvService::ServiceApps::MdiDataApp::MdiDataApp';
use aliased 'Programs::Services::TpvService::ServiceApps::JetprintDataApp::JetprintDataApp';
use aliased 'Programs::Services::TpvService::ServiceApps::ArchiveJobsApp::ArchiveJobsApp';
use aliased 'Programs::Services::TpvService::ServiceApps::CleanJobDbApp::CleanJobDbApp';
use aliased 'Programs::Services::TpvService::ServiceApps::CheckElTestsApp::CheckElTestsApp';
use aliased 'Programs::Services::TpvService::ServiceApps::ETKoopApp::ETKoopApp';

use aliased 'Programs::Services::TpvService::ServiceApps::TmpApp::TmpApp';

Win32::Daemon::RegisterCallbacks(
	{
	   start => \&Callback_Start,
	   timer => \&Callback_Timer,
	   stop  => \&Callback_Stop,

	   #pause    => \&Callback_Pause,
	   #continue => \&Callback_Continue,
	}
);

my %appStarts = ();

my %Context = (
				last_state => SERVICE_STOPPED,
				start_time => time() / 1000,
				appStarts  => \%appStarts
);

# Load configration file

#Helper->SetLogging( 'c:\tmp\InCam\scripts\logs\tpvService', GeneralHelper->Root() . "\\Programs\\Services\\TpvService" );

#my $OLDOUT;
#my $OLDERR;
###
#open $OLDOUT, ">&STDOUT" || die "Can't duplicate STDOUT: $!";
#open $OLDERR, ">&STDERR" || die "Can't duplicate STDERR: $!";
#open( STDOUT, "+>", 'c:\tmp\InCam\scripts\logs\test2' );
#open( STDERR, ">&STDOUT" );

__SetLogging();

#
#print "test";

# Start the service passing in a context and
# indicating to callback using the "Running" event
# every 2000 milliseconds (10 seconds).
Win32::Daemon::StartService( \%Context, 10000 );

# Now let the service manager know that we are running...
Win32::Daemon::State(SERVICE_RUNNING);

sub WorkerMethod {
	my $Context = shift;
	
 
	my $logger = get_logger("service");
 
	# ------------------------------------------------
	# load all registered app + period of launch in minutes
	#-------------------------------------------------

	my $path      = GeneralHelper->Root() . "\\Programs\\Services\\TpvService\\ServiceList.xml";
	my $xmlString = FileHelper->ReadAsString($path);

	my $xml = XMLin(
		$xmlString,
	);

	my %regApp = %{ $xml->{"app"} };

	# ------------------------------------------------

	#$logger->debug("In working method");

	# Launch app according last launch time
	foreach my $appName ( keys %regApp ) {
		
		if ( $regApp{$appName}->{"active"} == 0){
			next;
		}

		# check if app should run over night niht is 22:00 - 6:00, when no TPV in office
		my $curHours = ( localtime() )[2];
		if ( $regApp{$appName}->{"night"} && ( $curHours >= 6 && $curHours < 22 ) ) {
			next;
		}

		if ( !defined $Context->{"appStarts"}->{$appName}
			 || ( $Context->{"appStarts"}->{$appName} + $regApp{$appName}->{"repeat"} * 60 ) < time() )
		{

			$logger->info("Launch app ====== $appName ====== ");

			eval {

				$Context->{"appStarts"}->{$appName} = time();

				$logger->info("Before launch app $appName");
				my $app = __GetApp($appName);
				$logger->info("After init app $appName");

				$app->Run();

			};
			if ($@) {

				$logger->error("Error during running app $appName. Error message: $@");

			}

			$logger->info("End app $appName");
		}
	}

	#$logger->debug("Out of working method");

}

sub __GetApp {
	my $appName = shift;

	my $app = undef;

	my $logger = get_logger("service");

	#$logger->debug("get app");

	if ( $appName eq EnumsApp->App_CHECKREORDER ) {

		$app = CheckReorderApp->new();

	}
	elsif ( $appName eq EnumsApp->App_PROCESSREORDER ) {

		$app = ProcessReorderApp->new();

	}
	elsif ( $appName eq EnumsApp->App_MDIDATA ) {

		$app = MdiDataApp->new();
	}	elsif ( $appName eq EnumsApp->App_MDIDATAOLD ) {

		$app = MdiDataAppOld->new();
	}
	elsif ( $appName eq EnumsApp->App_ARCHIVEJOBS ) {

		$app = ArchiveJobsApp->new();
	}
	elsif ( $appName eq EnumsApp->App_JETPRINTDATA ) {

		$app = JetprintDataApp->new();
	}
	elsif ( $appName eq EnumsApp->App_CLEANJOBDB ) {

		$app = CleanJobDbApp->new();
	}
	elsif ( $appName eq EnumsApp->App_CHECKELTESTS ) {

		$app = CheckElTestsApp->new();
	}
	elsif ( $appName eq EnumsApp->App_ETKOOPER ) {

		$app = ETKoopApp->new();
	}
	elsif ( $appName eq EnumsApp->App_TEST ) {

		$app = TmpApp->new();
	
	}
	else{
 
		die "App class for app name: $appName is not implemented.";
	}

	return $app;
}

sub Callback_Timer {
	my ( $ControlMessage, $Context ) = @_;

	my $logger = get_logger("service");

	#$logger->debug("Call back running");

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

		#$logger->info("Tpv service start");

		#while (1) {

		if ( Win32::Daemon::QueryLastMessage() eq SERVICE_CONTROL_STOP ) {

			$logger->debug("Tpv service stop");

			# Tell the SCM to stop this service.
			Win32::Daemon::StopService();
			Win32::Daemon::State(SERVICE_STOPPED);

			last;
		}

		eval {

			WorkerMethod($Context);

		};
		if ($@) {

			print STDERR "error tpvCustomService\n";
			$logger->error( "Service fatal error in worker method:" . $@ );
			Win32::Daemon::StopService();
			Win32::Daemon::State(SERVICE_STOPPED);

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

	my $logConfig = GeneralHelper->Root() . "\\Programs\\Services\\TpvService\\Logger.conf";

	# create log dirs for all application
	my @dirs = ();
	if ( open( my $f, "<", $logConfig ) ) {

		while (<$f>) {
			if ( my ($logFile) = $_ =~ /.filename\s*=\s*(.*)/ ) {

				my ( $dir, $f ) = $logFile =~ /^(.+)\\([^\\]+)$/;
				unless ( -e $dir ) {
					mkdir($dir) or die "Can't create dir: " . $dir . $_;
				}
			}
		}
		close($logConfig);
	}

	Log::Log4perl->init($logConfig);

}

1;
