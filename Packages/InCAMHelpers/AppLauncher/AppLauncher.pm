
#-------------------------------------------------------------------------------------------#
# Description: Launch form applications in separate perl instance and conenct to InCAM editor
# This allow has interacting GUI (when we use threads) indepandatn what if InCAM editor is working or not
# Allow log process of launching (log4perl)
# Allow show waiting form during launching and processing Init() function of Application
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::AppLauncher;

#3th party library
use strict;
use warnings;
use JSON;
use Win32::Process;
use Config;
use Log::Log4perl qw(get_logger :levels);
use IO::Socket::PortState qw(check_ports);

#local library
use aliased 'Helpers::JobHelper';
use aliased "Helpers::FileHelper";
use aliased "Helpers::GeneralHelper";
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Other::AppConf';
use aliased 'Packages::InCAMHelpers::AppLauncher::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

$main::configPath = GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\AppLauncher\\Config.txt";

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# PROPERTIES

	$self->{"appPackage"} = shift;    # full name of package
	$self->{"appParams"}  = \@_;      # scalar params, which will be passed to app constructor

	$self->{"params"} = undef;        # helper array property, tmp file names, which contain papp parametr value in json
	$self->{"runScrpit"}  = GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\AppLauncher\\Run.pl";
	$self->{"serverPort"} = $self->__GetFreePort();
	$self->{"jobId"}      = $ENV{"JOB"} || 0;

	$self->{"waitFrmShow"}  = 0;
	$self->{"waitFrmTitle"} = undef;
	$self->{"waitFrmText"}  = undef;
	$self->{"waitFrmClose"} = "-";
	$self->{"waitFrmPID"}   = 0;

	$self->{"logConfig"} = 0;         # path of loging config file (log4perl)

	return $self;
}

# Start launching specific app
sub Run {
	my $self = shift;

	$self->__RunWaitFrm();

	$self->__RunApp();

	$self->__RunServer();

}

# Display wating form during launching app
sub SetWaitingFrm {
	my $self  = shift;
	my $title = shift;
	my $text  = shift;
	my $close = shift;    # close type WaitFrm_CLOSAUTO/WaitFrm_CLOSMAN

	$self->{"waitFrmShow"}  = 1;
	$self->{"waitFrmTitle"} = $title;
	$self->{"waitFrmText"}  = $text;
	$self->{"waitFrmClose"} = $close;

}

# Log config should contain
# Logger "appLauncher" for log launching process of app
sub SetLogConfig {
	my $self      = shift;
	my $logConfig = shift;

	$self->{"logConfig"} = $logConfig;

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

sub __RunApp {
	my $self = shift;
	if ( !defined $self->{"appPackage"} || $self->{"appPackage"} eq "" ) {

		die "App Package name is not defined\n";
	}

	# all parameters, which srcipt above consum
	foreach ( @{ $self->{"appParams"} } ) {
		$self->_AddParameter($_);
	}

	my $fIndicator = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

	my @cmd = ( $self->{"runScrpit"} );
	push( @cmd, $self->{"appPackage"} );      # app name
	push( @cmd, $self->{"serverPort"} );      # server port
	push( @cmd, $$ );                         # server (curr script) PID
	push( @cmd, $self->{"jobId"} );
	push( @cmd, $self->{"waitFrmPID"} );      # Pid of wait frm
	push( @cmd, $self->{"waitFrmClose"} );    # Type of wait frm closing
	push( @cmd, $self->{"logConfig"} );       # Log config path
	push( @cmd, $fIndicator );                # file, where run.pl store its PID in order kill if something go wrongs

	push( @cmd, join( " ", @{ $self->{"params"} } ) );    # app params

	my $cmdStr = join( " ", @cmd );

	my $perl = $Config{perlpath};
	my $processObj;
	Win32::Process::Create( $processObj, $perl, "perl " . $cmdStr, 1, NORMAL_PRIORITY_CLASS, "." )
	  || die "Failed to run $cmdStr.\n";

	my $pidInCAM = $processObj->GetProcessID();
}

sub __RunWaitFrm {
	my $self = shift;

	unless ( $self->{"waitFrmShow"} ) {

		return 0;
	}

	# 1) store title and text to file

	my %inf = ( "title" => $self->{"waitFrmTitle"}, "text" => $self->{"waitFrmText"} );

	my $json       = JSON->new()->allow_nonref();
	my $serialized = $json->pretty->encode( \%inf );
	my $fileName   = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

	open( my $f, '>', $fileName );
	print $f $serialized;
	close $f;

	my $perl = $Config{perlpath};
	my $processObj;
	Win32::Process::Create( $processObj, $perl, "perl " . GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\AppLauncher\\RunWaitFrm.pl " . $fileName,
							1, NORMAL_PRIORITY_CLASS, "." )
	  || die "Failed to create run wait frm.\n";

	$self->{"waitFrmPID"} = $processObj->GetProcessID();

}

sub __RunServer {
	my $self = shift;

	my $path = GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\AppLauncher\\Server\\Server.pl";

	# while script becaome to server
	{

		local @ARGV = ( $self->{"serverPort"} );

		require $path;
	};
}

# Search for free port, which begins with number in config
# Number of attempt is limited
sub __GetFreePort {
	my $self = shift;

	my $port = undef;

	my $host    = "localhost";
	my $timeout = 0.001;

	my $curPort = AppConf->GetValue("serverPort");
	for ( my $i = 0 ; $i < AppConf->GetValue("serverPortInc") ; $i++ ) {
	
		my %porthash = (
						 "tcp" => {
									2010 => {
											  name => 'export'
									}
						 }
		);

		check_ports( $host, $timeout, \%porthash );

		if ( !$porthash{"tcp"}->{$curPort}->{"open"} ) {
			$port = $curPort;
			last;
		}

		$curPort++;

	}

	die "No free port is available. Tested port: "
	  . AppConf->GetValue("serverPort") . " - "
	  . ( AppConf->GetValue("serverPort") + AppConf->GetValue("serverPortInc") )
	  unless ( defined $port );

	return $port;
}

sub _AddParameter {
	my $self = shift;
	my $ref  = shift;

	my $json = JSON->new()->allow_nonref();

	my $serialized = $json->pretty->encode($ref);

	my $paramId = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

	push( @{ $self->{"params"} }, $paramId );

	open( my $f, '>', $paramId );
	print $f $serialized;
	close $f;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::InCAMCall::InCAMCall';
	#
	#	my $paskageName = "Packages::InCAMCall::Example";
	#	my @par1        = ( "k" => "1" );
	#	my %par2        = ( "par1", "par2" );
	#
	#	my $call = InCAMCall->new( $paskageName, \@par1, \%par2 );
	#
	#	my $result = $call->Run();
	#	my %result = $call->GetOutput();
	#
	#	print "result $result";

}

1;

